// lib/domain/entities/readiness_metrics.dart
// Analytics domain models: Exam readiness score, thematic mastery, course mastery, and Bloom breakdown.

class ThemeMastery {
  final String themeId;
  final String themeCode;
  final String title;
  final double blueprintSharePct;
  final double masteryPct; // 0.0 - 1.0
  final int totalQuestions;
  final int answeredQuestions;

  const ThemeMastery({
    required this.themeId,
    required this.themeCode,
    required this.title,
    required this.blueprintSharePct,
    required this.masteryPct,
    required this.totalQuestions,
    required this.answeredQuestions,
  });
}

class CourseMastery {
  final String courseId;
  final String courseCode;
  final String title;
  final String themeId;
  final double examWeightPct;
  final double masteryPct; // 0.0 - 1.0
  final int totalQuestions;
  final int answeredQuestions;

  const CourseMastery({
    required this.courseId,
    required this.courseCode,
    required this.title,
    required this.themeId,
    required this.examWeightPct,
    required this.masteryPct,
    required this.totalQuestions,
    required this.answeredQuestions,
  });
}

class WeaknessQueueItem {
  final String chapterId;
  final String chapterTitle;
  final String courseCode;
  final double priorityScore; // 1..100
  final double masteryPct; // 0.0 - 1.0
  final double urgencyScore; // priority_score * (1.0 - mastery_pct)

  const WeaknessQueueItem({
    required this.chapterId,
    required this.chapterTitle,
    required this.courseCode,
    required this.priorityScore,
    required this.masteryPct,
    required this.urgencyScore,
  });
}

class ReadinessReport {
  final double overallReadinessScore; // 0.0 - 100.0
  final List<ThemeMastery> themeMasteries;
  final List<CourseMastery> courseMasteries;
  final List<WeaknessQueueItem> priorityQueue;
  final Map<String, double> bloomDomainMastery; // cognitive, psychomotor, affective
  final List<Map<String, dynamic>> historicalScores; // date & score for trend lines

  const ReadinessReport({
    required this.overallReadinessScore,
    required this.themeMasteries,
    required this.courseMasteries,
    required this.priorityQueue,
    required this.bloomDomainMastery,
    required this.historicalScores,
  });
}
