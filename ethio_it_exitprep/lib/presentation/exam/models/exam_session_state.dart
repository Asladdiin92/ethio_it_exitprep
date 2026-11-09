// lib/presentation/exam/models/exam_session_state.dart
// Immutable state representing an active or completed quiz / mock exam session.

import 'package:ethio_it_exitprep/domain/entities/question.dart';
import 'package:ethio_it_exitprep/domain/entities/question_option.dart';

enum ExamStatus { notStarted, inProgress, paused, completed }

class ExamQuestionItem {
  final Question question;
  final List<QuestionOption> options;

  const ExamQuestionItem({
    required this.question,
    required this.options,
  });
}

class ExamSessionState {
  final String attemptId;
  final String title;
  final bool isTimedMock;
  final List<ExamQuestionItem> questions;
  final int currentIndex;
  final Map<String, String> selectedAnswers; // questionId -> optionKey
  final Set<String> flaggedQuestionIds;
  final int totalSeconds;
  final int remainingSeconds;
  final ExamStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const ExamSessionState({
    required this.attemptId,
    required this.title,
    this.isTimedMock = false,
    required this.questions,
    this.currentIndex = 0,
    this.selectedAnswers = const {},
    this.flaggedQuestionIds = const {},
    this.totalSeconds = 0,
    this.remainingSeconds = 0,
    this.status = ExamStatus.notStarted,
    this.startedAt,
    this.completedAt,
  });

  int get totalQuestions => questions.length;
  int get answeredCount => selectedAnswers.length;
  int get unansweredCount => totalQuestions - answeredCount;
  int get flaggedCount => flaggedQuestionIds.length;

  bool get isCurrentFlagged =>
      questions.isNotEmpty && flaggedQuestionIds.contains(questions[currentIndex].question.id);

  String? get currentSelectedAnswer =>
      questions.isNotEmpty ? selectedAnswers[questions[currentIndex].question.id] : null;

  double get progressPercent =>
      totalQuestions == 0 ? 0.0 : answeredCount / totalQuestions;

  /// Calculate total score based on correct options
  int get correctCount {
    int count = 0;
    for (final item in questions) {
      final selectedKey = selectedAnswers[item.question.id];
      if (selectedKey != null) {
        final correctOption = item.options.cast<QuestionOption?>().firstWhere(
              (o) => o?.isCorrect == true,
              orElse: () => null,
            );
        if (correctOption != null && correctOption.optionKey == selectedKey) {
          count++;
        }
      }
    }
    return count;
  }

  double get scorePercent =>
      totalQuestions == 0 ? 0.0 : (correctCount / totalQuestions) * 100;

  ExamSessionState copyWith({
    String? attemptId,
    String? title,
    bool? isTimedMock,
    List<ExamQuestionItem>? questions,
    int? currentIndex,
    Map<String, String>? selectedAnswers,
    Set<String>? flaggedQuestionIds,
    int? totalSeconds,
    int? remainingSeconds,
    ExamStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return ExamSessionState(
      attemptId: attemptId ?? this.attemptId,
      title: title ?? this.title,
      isTimedMock: isTimedMock ?? this.isTimedMock,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      flaggedQuestionIds: flaggedQuestionIds ?? this.flaggedQuestionIds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
