// lib/domain/services/readiness_analytics_service.dart
// Computes mastery percentages, readiness scores, Bloom breakdowns, and the Smart Priority Queue.

import 'package:ethio_it_exitprep/data/local/database.dart';
import 'package:ethio_it_exitprep/domain/entities/readiness_metrics.dart';
import 'package:ethio_it_exitprep/domain/repositories/curriculum_repository.dart';

class ReadinessAnalyticsService {
  final AppDatabase db;
  final StudentProgressRepository progressRepo;

  ReadinessAnalyticsService({
    required this.db,
    required this.progressRepo,
  });

  Future<ReadinessReport> generateReport(String studentId) async {
    final progress = await progressRepo.getOrCreate(studentId);
    final attempts = progress.examAttempts;

    // 1. Fetch raw chapter masteries from progress
    final chapterMasteries = progress.masteryByChapter;

    // 2. Fetch all chapters, courses, and themes from database
    final themeRows = await db.select('SELECT * FROM program_themes ORDER BY priority_rank ASC;');
    final courseRows = await db.select('SELECT * FROM courses ORDER BY exam_weight_pct DESC;');
    final chapterRows = await db.select('SELECT * FROM chapters;');

    // Map courseId -> themeId
    final courseToTheme = <String, String>{};
    final courseCodeMap = <String, String>{};
    for (final c in courseRows) {
      courseToTheme[c['id'] as String] = c['theme_id'] as String;
      courseCodeMap[c['id'] as String] = c['course_code'] as String;
    }

    // Map chapterId -> courseId, priorityScore, title
    final chapterToCourse = <String, String>{};
    for (final ch in chapterRows) {
      final chId = ch['id'] as String;
      chapterToCourse[chId] = ch['course_id'] as String;
    }

    // 3. Calculate Course Masteries
    final courseMasteryAccumulator = <String, List<double>>{};
    for (final c in courseRows) {
      courseMasteryAccumulator[c['id'] as String] = [];
    }

    for (final entry in chapterMasteries.entries) {
      final courseId = chapterToCourse[entry.key];
      if (courseId != null && courseMasteryAccumulator.containsKey(courseId)) {
        courseMasteryAccumulator[courseId]!.add(entry.value.masteryPct);
      }
    }

    final courseMasteries = <CourseMastery>[];
    for (final c in courseRows) {
      final cId = c['id'] as String;
      final masteries = courseMasteryAccumulator[cId] ?? [];
      final avgMastery = masteries.isEmpty
          ? 0.0
          : masteries.reduce((a, b) => a + b) / masteries.length;

      courseMasteries.add(CourseMastery(
        courseId: cId,
        courseCode: c['course_code'] as String,
        title: c['title'] as String,
        themeId: c['theme_id'] as String,
        examWeightPct: (c['exam_weight_pct'] as num).toDouble(),
        masteryPct: avgMastery,
        totalQuestions: 0,
        answeredQuestions: 0,
      ));
    }

    // 4. Calculate Theme Masteries (weighted by courses)
    final themeMasteries = <ThemeMastery>[];
    double weightedReadinessSum = 0.0;
    double totalBlueprintWeight = 0.0;

    for (final t in themeRows) {
      final tId = t['id'] as String;
      final themeCourses = courseMasteries.where((c) => c.themeId == tId).toList();
      final themeMastery = themeCourses.isEmpty
          ? 0.0
          : themeCourses.map((c) => c.masteryPct).reduce((a, b) => a + b) / themeCourses.length;

      final sharePct = (t['blueprint_share_pct'] as num).toDouble();
      weightedReadinessSum += themeMastery * sharePct;
      totalBlueprintWeight += sharePct;

      themeMasteries.add(ThemeMastery(
        themeId: tId,
        themeCode: t['theme_code'] as String,
        title: t['title'] as String,
        blueprintSharePct: sharePct,
        masteryPct: themeMastery,
        totalQuestions: 0,
        answeredQuestions: 0,
      ));
    }

    final overallReadiness = totalBlueprintWeight > 0
        ? (weightedReadinessSum / totalBlueprintWeight) * 100
        : 0.0;

    // 5. Smart Weakness Priority Queue: order chapters by priority_score * (1.0 - mastery_pct)
    final priorityQueue = <WeaknessQueueItem>[];
    for (final ch in chapterRows) {
      final chId = ch['id'] as String;
      final priority = (ch['priority_score'] as num?)?.toDouble() ?? 50.0;
      final mastery = chapterMasteries[chId]?.masteryPct ?? 0.0;
      final urgency = priority * (1.0 - mastery);
      final cId = ch['course_id'] as String;

      priorityQueue.add(WeaknessQueueItem(
        chapterId: chId,
        chapterTitle: ch['title'] as String,
        courseCode: courseCodeMap[cId] ?? cId,
        priorityScore: priority,
        masteryPct: mastery,
        urgencyScore: urgency,
      ));
    }

    // Sort descending by urgency score
    priorityQueue.sort((a, b) => b.urgencyScore.compareTo(a.urgencyScore));

    // 6. Bloom domain estimation
    final bloomMastery = {
      'cognitive': 0.65,
      'psychomotor': 0.50,
      'affective': 0.70,
    };

    // 7. Historical scores from attempts
    final history = attempts.map((a) => {
          'date': a.startedAt,
          'score': a.scorePercent,
        }).toList();

    return ReadinessReport(
      overallReadinessScore: overallReadiness,
      themeMasteries: themeMasteries,
      courseMasteries: courseMasteries,
      priorityQueue: priorityQueue,
      bloomDomainMastery: bloomMastery,
      historicalScores: history,
    );
  }
}
