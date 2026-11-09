// test/domain/analytics_and_sync_test.dart
// Phase 4 tests: validates Competency Analytics Engine, Smart Priority Queue,
// and Delta-Sync API client / offline fallback.

import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ethio_it_exitprep/data/local/database.dart';
import 'package:ethio_it_exitprep/data/local/seed_data.dart';
import 'package:ethio_it_exitprep/data/remote/sync_api.dart';
import 'package:ethio_it_exitprep/data/remote/sync_service.dart';
import 'package:ethio_it_exitprep/data/repositories/local_simple_repositories.dart';
import 'package:ethio_it_exitprep/data/repositories/local_study_material_repository.dart';
import 'package:ethio_it_exitprep/data/repositories/local_question_repository.dart';
import 'package:ethio_it_exitprep/domain/entities/chapter.dart';
import 'package:ethio_it_exitprep/domain/entities/student_progress.dart';
import 'package:ethio_it_exitprep/domain/services/readiness_analytics_service.dart';

class MockOfflineConnectivity implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return [ConnectivityResult.none];
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Stream.value([ConnectivityResult.none]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late LocalProgramThemeRepository themeRepo;
  late LocalCourseRepository courseRepo;
  late LocalChapterRepository chapterRepo;
  late LocalStudentProgressRepository progressRepo;
  late LocalStudyMaterialRepository materialRepo;
  late LocalQuestionRepository questionRepo;
  late ReadinessAnalyticsService analyticsService;

  final now = DateTime(2026, 11, 9);

  setUp(() async {
    db = await AppDatabase.createInMemory();
    themeRepo = LocalProgramThemeRepository(db);
    courseRepo = LocalCourseRepository(db);
    chapterRepo = LocalChapterRepository(db);
    progressRepo = LocalStudentProgressRepository(db);
    materialRepo = LocalStudyMaterialRepository(db);
    questionRepo = LocalQuestionRepository(db);

    // Seed baseline themes and courses
    final seeder = SeedDataLoader(themeRepo: themeRepo, courseRepo: courseRepo);
    await seeder.loadIfEmpty();

    analyticsService = ReadinessAnalyticsService(
      db: db,
      progressRepo: progressRepo,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Competency & Readiness Analytics Engine', () {
    test('Calculates weighted readiness and smart priority queue', () async {
      // Add chapters with different priority scores
      await chapterRepo.upsert(Chapter(
        id: 'CH01',
        courseId: 'C01', // OOP (Theme T1)
        title: 'OOP Fundamentals',
        chapterNumber: 1,
        sequenceOrder: 1,
        priorityScore: 90.0,
        estMinutes: 45,
        createdAt: now,
        updatedAt: now,
      ));

      await chapterRepo.upsert(Chapter(
        id: 'CH02',
        courseId: 'C01',
        title: 'Inheritance Details',
        chapterNumber: 2,
        sequenceOrder: 2,
        priorityScore: 50.0,
        estMinutes: 45,
        createdAt: now,
        updatedAt: now,
      ));

      // Record mastery: CH01 has 80% mastery, CH02 has 10% mastery
      await progressRepo.updateChapterMastery(
        'STUDENT_01',
        ChapterMastery(
          chapterId: 'CH01',
          masteryPct: 0.80,
          questionsAttempted: 10,
          questionsCorrect: 8,
          lastStudied: now,
        ),
      );

      await progressRepo.updateChapterMastery(
        'STUDENT_01',
        ChapterMastery(
          chapterId: 'CH02',
          masteryPct: 0.10,
          questionsAttempted: 10,
          questionsCorrect: 1,
          lastStudied: now,
        ),
      );

      final report = await analyticsService.generateReport('STUDENT_01');

      // 1. Verify Themes and Courses are generated
      expect(report.themeMasteries.length, 5);
      expect(report.courseMasteries.length, 13);

      // 2. Verify Smart Priority Queue ranking:
      // CH01 urgency: 90.0 * (1 - 0.80) = 18.0
      // CH02 urgency: 50.0 * (1 - 0.10) = 45.0
      // Therefore, CH02 must be ranked HIGHER urgency than CH01 in the queue!
      expect(report.priorityQueue.length, 2);
      expect(report.priorityQueue.first.chapterId, 'CH02');
      expect(report.priorityQueue.first.urgencyScore, closeTo(45.0, 0.1));
      expect(report.priorityQueue.last.chapterId, 'CH01');
      expect(report.priorityQueue.last.urgencyScore, closeTo(18.0, 0.1));

      // 3. Verify Bloom domains breakdown
      expect(report.bloomDomainMastery.containsKey('cognitive'), true);
    });
  });

  group('SyncDeltaResponse & REST client models', () {
    test('SyncDeltaResponse parses JSON successfully', () {
      final json = {
        'serverTimestamp': '2026-11-09T18:00:00.000Z',
        'updatedMaterials': [
          {
            'id': 'SM_CLOUD_01',
            'chapterId': 'CH01',
            'title': 'Cloud Note',
            'contentStyle': 'conceptNote',
            'difficultyTier': 2,
            'priorityTier': 'P1_CRITICAL',
            'contentBlocks': [],
            'tags': ['cloud'],
            'createdAt': '2026-11-09T18:00:00.000Z',
            'updatedAt': '2026-11-09T18:00:00.000Z',
          }
        ],
        'updatedQuestions': [],
        'deletedIds': ['OLD_ITEM_01'],
      };

      final response = SyncDeltaResponse.fromJson(json);
      expect(response.updatedMaterials.length, 1);
      expect(response.updatedMaterials.first['title'], 'Cloud Note');
      expect(response.deletedEntities.first.entityId, 'OLD_ITEM_01');
    });
  });

  group('SyncService offline fallback', () {
    test('Gracefully skips sync when device is offline without throwing', () async {
      final syncService = SyncService(
        apiClient: SyncApiClient(),
        connectivity: MockOfflineConnectivity(),
        materialRepo: materialRepo,
        questionRepo: questionRepo,
        progressRepo: progressRepo,
      );

      final result = await syncService.runSyncCycle('STUDENT_01');
      expect(result, false); // Returns false cleanly indicating offline, no crash
    });
  });
}
