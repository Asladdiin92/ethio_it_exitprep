// lib/presentation/exam/controllers/exam_session_controller.dart
// Riverpod state notifier managing mock exam timers, palette, answer state, and submission.

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethio_it_exitprep/core/providers/repository_providers.dart';
import 'package:ethio_it_exitprep/domain/entities/student_progress.dart';
import 'package:ethio_it_exitprep/domain/repositories/curriculum_filter.dart';
import 'package:ethio_it_exitprep/presentation/exam/models/exam_session_state.dart';

final examSessionControllerProvider =
    StateNotifierProvider<ExamSessionController, ExamSessionState>((ref) {
  return ExamSessionController(ref);
});

class ExamSessionController extends StateNotifier<ExamSessionState> {
  final Ref _ref;
  Timer? _timer;

  ExamSessionController(this._ref)
      : super(const ExamSessionState(
          attemptId: '',
          title: '',
          questions: [],
        ));

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Initialize and start a 100-Question Timed National Mock Exam.
  /// Stratified according to FDRE MoE Blueprint weights:
  /// T1 (Prog): 23, T2 (Data): 22, T3 (Net): 20, T4 (Web): 18, T5 (Sys): 17
  Future<void> startTimedNationalMock({
    int durationMinutes = 150, // 2.5 hours national standard
    String studentId = 'LOCAL_STUDENT',
  }) async {
    _timer?.cancel();

    final questionRepo = _ref.read(questionRepositoryProvider);
    final optionRepo = _ref.read(questionOptionRepositoryProvider);

    final questions = <ExamQuestionItem>[];

    // Blueprint allocation per theme
    final themeTargets = {
      'T1': 23,
      'T2': 22,
      'T3': 20,
      'T4': 18,
      'T5': 17,
    };

    for (final entry in themeTargets.entries) {
      final themeQuestions = await questionRepo.query(
        CurriculumFilter(themeId: entry.key),
        sort: CurriculumSortOrder.priorityDesc,
        limit: entry.value,
      );

      for (final q in themeQuestions) {
        final options = await optionRepo.getByQuestion(q.id);
        questions.add(ExamQuestionItem(question: q, options: options));
      }
    }

    // Fallback if specific theme count is lower during testing: fetch any available
    if (questions.isEmpty) {
      final allQuestions = await questionRepo.query(
        const CurriculumFilter(),
        limit: 100,
      );
      for (final q in allQuestions) {
        final options = await optionRepo.getByQuestion(q.id);
        questions.add(ExamQuestionItem(question: q, options: options));
      }
    }

    final attemptId = 'MOCK_${DateTime.now().millisecondsSinceEpoch}';
    final totalSecs = durationMinutes * 60;

    state = ExamSessionState(
      attemptId: attemptId,
      title: 'FDRE MoE National Exit Exam Simulation',
      isTimedMock: true,
      questions: questions,
      currentIndex: 0,
      selectedAnswers: {},
      flaggedQuestionIds: {},
      totalSeconds: totalSecs,
      remainingSeconds: totalSecs,
      status: ExamStatus.inProgress,
      startedAt: DateTime.now(),
    );

    _startTimer();
  }

  /// Start a Custom Practice Quiz based on user-selected curriculum dimensions.
  Future<void> startCustomDrill({
    required String title,
    required CurriculumFilter filter,
    CurriculumSortOrder sort = CurriculumSortOrder.priorityDesc,
    int questionLimit = 25,
    int? durationMinutes,
  }) async {
    _timer?.cancel();

    final questionRepo = _ref.read(questionRepositoryProvider);
    final optionRepo = _ref.read(questionOptionRepositoryProvider);

    final questionsList = await questionRepo.query(
      filter,
      sort: sort,
      limit: questionLimit,
    );

    final questionItems = <ExamQuestionItem>[];
    for (final q in questionsList) {
      final options = await optionRepo.getByQuestion(q.id);
      questionItems.add(ExamQuestionItem(question: q, options: options));
    }

    final attemptId = 'DRILL_${DateTime.now().millisecondsSinceEpoch}';
    final totalSecs = durationMinutes != null ? durationMinutes * 60 : 0;

    state = ExamSessionState(
      attemptId: attemptId,
      title: title,
      isTimedMock: durationMinutes != null,
      questions: questionItems,
      currentIndex: 0,
      selectedAnswers: {},
      flaggedQuestionIds: {},
      totalSeconds: totalSecs,
      remainingSeconds: totalSecs,
      status: ExamStatus.inProgress,
      startedAt: DateTime.now(),
    );

    if (durationMinutes != null && durationMinutes > 0) {
      _startTimer();
    }
  }

  void selectAnswer(String optionKey) {
    if (state.questions.isEmpty || state.status != ExamStatus.inProgress) return;
    final currentQ = state.questions[state.currentIndex].question;
    final updated = Map<String, String>.from(state.selectedAnswers);
    updated[currentQ.id] = optionKey;
    state = state.copyWith(selectedAnswers: updated);
  }

  void toggleFlagCurrent() {
    if (state.questions.isEmpty) return;
    final currentQId = state.questions[state.currentIndex].question.id;
    final updated = Set<String>.from(state.flaggedQuestionIds);
    if (updated.contains(currentQId)) {
      updated.remove(currentQId);
    } else {
      updated.add(currentQId);
    }
    state = state.copyWith(flaggedQuestionIds: updated);
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < state.questions.length) {
      state = state.copyWith(currentIndex: index);
    }
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previousQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        timer.cancel();
        submitExam();
      }
    });
  }

  /// Submit the exam, record attempt in SQLite, and transition status to completed.
  Future<ExamAttempt> submitExam({String studentId = 'LOCAL_STUDENT'}) async {
    _timer?.cancel();
    final completedAt = DateTime.now();

    final attempt = ExamAttempt(
      attemptId: state.attemptId,
      studentId: studentId,
      startedAt: state.startedAt ?? completedAt,
      completedAt: completedAt,
      totalQuestions: state.totalQuestions,
      correctAnswers: state.correctCount,
      scorePercent: state.scorePercent,
      answerMap: state.selectedAnswers,
      syncedToCloud: false,
    );

    // Persist attempt locally to SQLite
    final progressRepo = _ref.read(studentProgressRepositoryProvider);
    await progressRepo.recordAttempt(attempt);

    state = state.copyWith(
      status: ExamStatus.completed,
      completedAt: completedAt,
    );

    return attempt;
  }
}
