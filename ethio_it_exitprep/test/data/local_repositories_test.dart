// test/data/local_repositories_test.dart
// Phase 2 repository tests: verifies multi-dimensional filtering, FTS5 search,
// dynamic sorting, semantic graph relations, and offline-first storage.

import 'package:flutter_test/flutter_test.dart';
import 'package:ethio_it_exitprep/data/local/database.dart';
import 'package:ethio_it_exitprep/data/local/seed_data.dart';
import 'package:ethio_it_exitprep/data/repositories/local_study_material_repository.dart';
import 'package:ethio_it_exitprep/data/repositories/local_question_repository.dart';
import 'package:ethio_it_exitprep/data/repositories/local_simple_repositories.dart';
import 'package:ethio_it_exitprep/domain/entities/chapter.dart';
import 'package:ethio_it_exitprep/domain/entities/study_material.dart';
import 'package:ethio_it_exitprep/domain/entities/content_relation.dart';
import 'package:ethio_it_exitprep/domain/entities/question.dart';
import 'package:ethio_it_exitprep/domain/entities/question_option.dart';
import 'package:ethio_it_exitprep/domain/entities/student_progress.dart';
import 'package:ethio_it_exitprep/domain/repositories/curriculum_filter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late LocalProgramThemeRepository themeRepo;
  late LocalCourseRepository courseRepo;
  late LocalChapterRepository chapterRepo;
  late LocalStudyMaterialRepository materialRepo;
  late LocalQuestionRepository questionRepo;
  late LocalQuestionOptionRepository optionRepo;
  late LocalContentRelationRepository relationRepo;
  late LocalStudentProgressRepository progressRepo;

  final now = DateTime(2026, 11, 9);

  setUp(() async {
    db = await AppDatabase.createInMemory();
    themeRepo = LocalProgramThemeRepository(db);
    courseRepo = LocalCourseRepository(db);
    chapterRepo = LocalChapterRepository(db);
    materialRepo = LocalStudyMaterialRepository(db);
    questionRepo = LocalQuestionRepository(db);
    optionRepo = LocalQuestionOptionRepository(db);
    relationRepo = LocalContentRelationRepository(db);
    progressRepo = LocalStudentProgressRepository(db);

    // Seed baseline 5 themes and 13 courses
    final seeder = SeedDataLoader(themeRepo: themeRepo, courseRepo: courseRepo);
    await seeder.loadIfEmpty();
  });

  tearDown(() async {
    await db.close();
  });

  test('SeedDataLoader populates 5 MoE themes and 13 BSc IT courses', () async {
    final themes = await themeRepo.getAll();
    expect(themes.length, 5);

    final courses = await courseRepo.getAll();
    expect(courses.length, 13);

    final progCourses = await courseRepo.getByTheme('T1');
    expect(progCourses.length, 3);
  });

  test('SeedDataLoader populates chapters, questions, and options when repos provided', () async {
    final fullSeeder = SeedDataLoader(
      themeRepo: themeRepo,
      courseRepo: courseRepo,
      chapterRepo: chapterRepo,
      questionRepo: questionRepo,
      optionRepo: optionRepo,
    );
    await fullSeeder.loadIfEmpty();

    final questions = await questionRepo.query(const CurriculumFilter());
    expect(questions.length, greaterThanOrEqualTo(2));

    final oopQuestion = await questionRepo.getById('Q_2017_OOP_01');
    expect(oopQuestion, isNotNull);
    expect(oopQuestion!.stemTitle, 'Object-Oriented Encapsulation');

    final options = await optionRepo.getByQuestion('Q_2017_OOP_01');
    expect(options.length, 4);
    final correctOpt = options.firstWhere((o) => o.isCorrect);
    expect(correctOpt.optionKey, 'B');
    expect(correctOpt.optionText, 'Encapsulation');
  });

  group('StudyMaterial multi-dimensional filtering & FTS5 search', () {
    setUp(() async {
      // Add Chapter under OOP (C01)
      await chapterRepo.upsert(Chapter(
        id: 'CH01',
        courseId: 'C01',
        title: 'Classes and Objects',
        chapterNumber: 1,
        sequenceOrder: 1,
        priorityScore: 90.0,
        estMinutes: 50,
        createdAt: now,
        updatedAt: now,
      ));

      // Add Study Materials with varied dimensions
      await materialRepo.upsert(StudyMaterial(
        id: 'SM01',
        chapterId: 'CH01',
        title: 'Polymorphism and Dynamic Binding',
        contentStyle: ContentStyle.conceptNote,
        difficultyTier: DifficultyTier.hard,
        priorityTier: PriorityTier.p1Critical,
        contentBlocks: [{'type': 'text', 'text': 'Dynamic dispatch mechanism'}],
        tags: ['oop', 'polymorphism'],
        createdAt: now,
        updatedAt: now,
      ));

      await materialRepo.upsert(StudyMaterial(
        id: 'SM02',
        chapterId: 'CH01',
        title: 'Basic Class Definition Syntax',
        contentStyle: ContentStyle.quickSummary,
        difficultyTier: DifficultyTier.simple,
        priorityTier: PriorityTier.p2HighYield,
        contentBlocks: [{'type': 'text', 'text': 'How to define classes and fields'}],
        tags: ['syntax', 'beginner'],
        createdAt: now,
        updatedAt: now,
      ));

      // Index in FTS5
      await db.indexDocument(
        entityId: 'SM01',
        entityType: 'material',
        courseCode: 'ITec2051',
        chapterTitle: 'Classes and Objects',
        title: 'Polymorphism and Dynamic Binding',
        bodyText: 'Dynamic dispatch mechanism in Java and C++',
        tags: 'oop polymorphism',
      );
    });

    test('Query by courseId and difficultyTier', () async {
      final results = await materialRepo.query(
        const CurriculumFilter(
          courseId: 'C01',
          difficultyTier: DifficultyTier.hard,
        ),
      );
      expect(results.length, 1);
      expect(results.first.id, 'SM01');
    });

    test('Query by contentStyle', () async {
      final results = await materialRepo.query(
        const CurriculumFilter(
          contentStyle: ContentStyle.quickSummary,
        ),
      );
      expect(results.length, 1);
      expect(results.first.id, 'SM02');
    });

    test('Sort by simplicityToHardness reorders correctly', () async {
      final results = await materialRepo.query(
        const CurriculumFilter(courseId: 'C01'),
        sort: CurriculumSortOrder.simplicityToHardness,
      );
      expect(results.length, 2);
      expect(results.first.difficultyTier, DifficultyTier.simple);
      expect(results.last.difficultyTier, DifficultyTier.hard);
    });

    test('Full-text search via FTS5 BM25 ranking', () async {
      final results = await materialRepo.query(
        const CurriculumFilter(searchQuery: 'dispatch'),
      );
      expect(results.length, 1);
      expect(results.first.id, 'SM01');
    });
  });

  group('Question repository multi-dimensional queries', () {
    setUp(() async {
      await chapterRepo.upsert(Chapter(
        id: 'CH01',
        courseId: 'C01',
        title: 'OOP Foundations',
        chapterNumber: 1,
        sequenceOrder: 1,
        priorityScore: 85.0,
        estMinutes: 40,
        createdAt: now,
        updatedAt: now,
      ));

      await questionRepo.upsert(Question(
        id: 'Q01',
        courseId: 'C01',
        chapterId: 'CH01',
        title: 'Inheritance vs Composition',
        examYear: 2017,
        sourceType: SourceType.nationalExitExam,
        difficultyTier: DifficultyTier.moderate,
        priorityWeight: 92.0,
        bloomDomain: BloomDomain.cognitive,
        stemTitle: 'Inheritance Design',
        stemBody: 'Which principle favours composition over inheritance?',
        generalExplanation: 'Favor object composition over class inheritance.',
        createdAt: now,
        updatedAt: now,
      ));

      await questionRepo.upsert(Question(
        id: 'Q02',
        courseId: 'C01',
        chapterId: 'CH01',
        title: 'Abstract Class Basics',
        examYear: 2015,
        sourceType: SourceType.nationalExitExam,
        difficultyTier: DifficultyTier.simple,
        priorityWeight: 60.0,
        bloomDomain: BloomDomain.cognitive,
        stemTitle: 'Abstract Classes',
        stemBody: 'Can an abstract class be directly instantiated?',
        generalExplanation: 'No, abstract classes cannot be instantiated directly.',
        createdAt: now,
        updatedAt: now,
      ));

      await optionRepo.upsertAll([
        const QuestionOption(
          optionId: 'OPT1',
          questionId: 'Q01',
          optionKey: 'A',
          optionText: 'Liskov Substitution',
          isCorrect: false,
          optionRationale: 'LSP focuses on subtype substitutability.',
        ),
        const QuestionOption(
          optionId: 'OPT2',
          questionId: 'Q01',
          optionKey: 'B',
          optionText: 'Favor composition over inheritance',
          isCorrect: true,
          optionRationale: 'Directly stated in Gang of Four design patterns.',
        ),
      ]);
    });

    test('Query questions by examYear', () async {
      final results = await questionRepo.query(
        const CurriculumFilter(examYear: 2017),
      );
      expect(results.length, 1);
      expect(results.first.id, 'Q01');
    });

    test('Sort by priorityDesc orders highest priority first', () async {
      final results = await questionRepo.query(
        const CurriculumFilter(courseId: 'C01'),
        sort: CurriculumSortOrder.priorityDesc,
      );
      expect(results.length, 2);
      expect(results.first.priorityWeight, 92.0);
      expect(results.last.priorityWeight, 60.0);
    });

    test('Fetch question options with per-option rationales', () async {
      final options = await optionRepo.getByQuestion('Q01');
      expect(options.length, 2);
      expect(options.firstWhere((o) => o.isCorrect).optionKey, 'B');
    });
  });

  group('Semantic ContentRelation graph navigation', () {
    test('Stores and traverses bidirectional relations', () async {
      await relationRepo.upsert(const ContentRelation(
        relationId: 'REL01',
        sourceType: 'question',
        sourceId: 'Q01',
        targetType: 'material',
        targetId: 'SM01',
        relationType: RelationType.explainsAnswerFor,
        relevanceWeight: 0.95,
      ));

      await relationRepo.upsert(const ContentRelation(
        relationId: 'REL02',
        sourceType: 'material',
        sourceId: 'SM02',
        targetType: 'material',
        targetId: 'SM01',
        relationType: RelationType.prerequisiteOf,
        relevanceWeight: 0.85,
      ));

      final forwardFromQ = await relationRepo.getRelationsFrom('Q01');
      expect(forwardFromQ.length, 1);
      expect(forwardFromQ.first.targetId, 'SM01');

      final reverseToSM01 = await relationRepo.getRelationsTo('SM01');
      expect(reverseToSM01.length, 2);
    });
  });

  group('StudentProgress & offline exam queue', () {
    test('Tracks mastery and queues exam attempts for offline-first sync', () async {
      final initial = await progressRepo.getOrCreate('STUDENT_0172');
      expect(initial.studentId, 'STUDENT_0172');
      expect(initial.bookmarkedIds, isEmpty);

      // Bookmark an item
      await progressRepo.toggleBookmark('STUDENT_0172', 'SM01');
      final updated = await progressRepo.getOrCreate('STUDENT_0172');
      expect(updated.bookmarkedIds, contains('SM01'));

      // Record offline exam attempt
      final attempt = ExamAttempt(
        attemptId: 'ATT_UUID_01',
        studentId: 'STUDENT_0172',
        startedAt: now,
        completedAt: now.add(const Duration(hours: 1)),
        totalQuestions: 100,
        correctAnswers: 78,
        scorePercent: 78.0,
        answerMap: {'Q01': 'B'},
        syncedToCloud: false,
      );
      await progressRepo.recordAttempt(attempt);

      final unsynced = await progressRepo.getUnsyncedAttempts('STUDENT_0172');
      expect(unsynced.length, 1);
      expect(unsynced.first.scorePercent, 78.0);

      // Simulate cloud sync completion
      await progressRepo.markAttemptSynced('ATT_UUID_01');
      final unsyncedAfter = await progressRepo.getUnsyncedAttempts('STUDENT_0172');
      expect(unsyncedAfter, isEmpty);
    });
  });
}
