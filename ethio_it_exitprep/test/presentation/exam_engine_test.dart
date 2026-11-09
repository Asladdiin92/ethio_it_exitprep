// test/presentation/exam_engine_test.dart
// Phase 3 tests: validates Mock Exam simulator, Custom Drill builder,
// state transitions, answer selection, score calculation, and local submission.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethio_it_exitprep/core/providers/repository_providers.dart';
import 'package:ethio_it_exitprep/data/local/database.dart';
import 'package:ethio_it_exitprep/domain/entities/chapter.dart';
import 'package:ethio_it_exitprep/domain/entities/question.dart';
import 'package:ethio_it_exitprep/domain/entities/question_option.dart';
import 'package:ethio_it_exitprep/domain/entities/study_material.dart';
import 'package:ethio_it_exitprep/domain/repositories/curriculum_filter.dart';
import 'package:ethio_it_exitprep/presentation/exam/controllers/exam_session_controller.dart';
import 'package:ethio_it_exitprep/presentation/exam/models/exam_session_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late ProviderContainer container;

  final now = DateTime(2026, 11, 9);

  setUp(() async {
    db = await AppDatabase.createInMemory();

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
    );

    // Setup sample Course and Chapter
    await db.execute('''
      INSERT INTO program_themes (id, theme_code, title, created_at, updated_at)
      VALUES ('T1', 'PROG', 'Programming', '$now', '$now');
    ''');
    await db.execute('''
      INSERT INTO courses (id, theme_id, course_code, title, created_at, updated_at)
      VALUES ('C01', 'T1', 'ITec2051', 'OOP', '$now', '$now');
    ''');
    await container.read(chapterRepositoryProvider).upsert(Chapter(
      id: 'CH01',
      courseId: 'C01',
      title: 'Polymorphism',
      chapterNumber: 1,
      sequenceOrder: 1,
      priorityScore: 90.0,
      estMinutes: 60,
      createdAt: now,
      updatedAt: now,
    ));

    // Insert 3 questions with options
    final qRepo = container.read(questionRepositoryProvider);
    final optRepo = container.read(questionOptionRepositoryProvider);

    for (int i = 1; i <= 3; i++) {
      await qRepo.upsert(Question(
        id: 'Q0$i',
        courseId: 'C01',
        chapterId: 'CH01',
        title: 'Question $i Title',
        examYear: 2017,
        sourceType: SourceType.nationalExitExam,
        difficultyTier: DifficultyTier.moderate,
        priorityWeight: 80.0,
        bloomDomain: BloomDomain.cognitive,
        stemTitle: 'Stem Title $i',
        stemBody: 'Which option is correct for question $i?',
        generalExplanation: 'Explanation for question $i.',
        createdAt: now,
        updatedAt: now,
      ));

      await optRepo.upsertAll([
        QuestionOption(
          optionId: 'OPT_${i}_A',
          questionId: 'Q0$i',
          optionKey: 'A',
          optionText: 'Option A for $i',
          isCorrect: i == 1, // Correct only for Q1
          optionRationale: 'Rationale A for $i',
        ),
        QuestionOption(
          optionId: 'OPT_${i}_B',
          questionId: 'Q0$i',
          optionKey: 'B',
          optionText: 'Option B for $i',
          isCorrect: i == 2, // Correct only for Q2
          optionRationale: 'Rationale B for $i',
        ),
        QuestionOption(
          optionId: 'OPT_${i}_C',
          questionId: 'Q0$i',
          optionKey: 'C',
          optionText: 'Option C for $i',
          isCorrect: i == 3, // Correct only for Q3
          optionRationale: 'Rationale C for $i',
        ),
      ]);
    }
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('startCustomDrill loads matching questions into session state', () async {
    final controller = container.read(examSessionControllerProvider.notifier);

    await controller.startCustomDrill(
      title: 'OOP Practice Drill',
      filter: const CurriculumFilter(courseId: 'C01'),
      durationMinutes: 30,
    );

    final state = container.read(examSessionControllerProvider);
    expect(state.title, 'OOP Practice Drill');
    expect(state.totalQuestions, 3);
    expect(state.isTimedMock, true);
    expect(state.totalSeconds, 1800);
    expect(state.remainingSeconds, 1800);
    expect(state.status, ExamStatus.inProgress);
    expect(state.currentIndex, 0);
  });

  test('Answer selection, flagging, and navigation flow', () async {
    final controller = container.read(examSessionControllerProvider.notifier);

    await controller.startCustomDrill(
      title: 'Drill',
      filter: const CurriculumFilter(courseId: 'C01'),
    );

    // Q1: select A (correct)
    controller.selectAnswer('A');
    expect(container.read(examSessionControllerProvider).selectedAnswers['Q01'], 'A');
    expect(container.read(examSessionControllerProvider).answeredCount, 1);

    // Flag Q1
    controller.toggleFlagCurrent();
    expect(container.read(examSessionControllerProvider).isCurrentFlagged, true);
    expect(container.read(examSessionControllerProvider).flaggedCount, 1);

    // Navigate next to Q2
    controller.nextQuestion();
    expect(container.read(examSessionControllerProvider).currentIndex, 1);
    expect(container.read(examSessionControllerProvider).isCurrentFlagged, false);

    // Q2: select B (correct)
    controller.selectAnswer('B');

    // Navigate to Q3
    controller.nextQuestion();
    expect(container.read(examSessionControllerProvider).currentIndex, 2);

    // Q3: select A (wrong, correct is C)
    controller.selectAnswer('A');

    // Navigate back to Q1
    controller.previousQuestion();
    controller.previousQuestion();
    expect(container.read(examSessionControllerProvider).currentIndex, 0);

    // Unflag Q1
    controller.toggleFlagCurrent();
    expect(container.read(examSessionControllerProvider).isCurrentFlagged, false);
  });

  test('Exam submission records attempt and computes score accurately', () async {
    final controller = container.read(examSessionControllerProvider.notifier);

    await controller.startCustomDrill(
      title: 'Scoring Test',
      filter: const CurriculumFilter(courseId: 'C01'),
    );

    // Q1 -> A (correct)
    controller.goToQuestion(0);
    controller.selectAnswer('A');

    // Q2 -> B (correct)
    controller.goToQuestion(1);
    controller.selectAnswer('B');

    // Q3 -> leave unanswered

    final stateBeforeSubmit = container.read(examSessionControllerProvider);
    expect(stateBeforeSubmit.correctCount, 2);
    expect(stateBeforeSubmit.totalQuestions, 3);
    expect(stateBeforeSubmit.scorePercent, closeTo(66.67, 0.1));

    // Submit exam
    final attempt = await controller.submitExam(studentId: 'TEST_STUDENT_01');

    expect(attempt.totalQuestions, 3);
    expect(attempt.correctAnswers, 2);
    expect(attempt.scorePercent, closeTo(66.67, 0.1));

    // Verify persisted in offline database
    final progressRepo = container.read(studentProgressRepositoryProvider);
    final unsynced = await progressRepo.getUnsyncedAttempts('TEST_STUDENT_01');
    expect(unsynced.length, 1);
    expect(unsynced.first.attemptId, attempt.attemptId);
  });

  test('startTimedNationalMock initializes 150-minute exam session', () async {
    final controller = container.read(examSessionControllerProvider.notifier);

    await controller.startTimedNationalMock();

    final state = container.read(examSessionControllerProvider);
    expect(state.isTimedMock, true);
    expect(state.totalSeconds, 150 * 60);
    expect(state.status, ExamStatus.inProgress);
    expect(state.questions.isNotEmpty, true);
  });
}
