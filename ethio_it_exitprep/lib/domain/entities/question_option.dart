// lib/domain/entities/question_option.dart
// Entity 7 of 8: QuestionOption — choices A–D with correctness and per-option rationale.

class QuestionOption {
  final String optionId;
  final String questionId;
  final String optionKey; // 'A' | 'B' | 'C' | 'D'
  final String optionText;
  final bool isCorrect;
  final String optionRationale;

  const QuestionOption({
    required this.optionId,
    required this.questionId,
    required this.optionKey,
    required this.optionText,
    required this.isCorrect,
    required this.optionRationale,
  });

  Map<String, dynamic> toJson() => {
        'optionId': optionId,
        'questionId': questionId,
        'optionKey': optionKey,
        'optionText': optionText,
        'isCorrect': isCorrect,
        'optionRationale': optionRationale,
      };

  factory QuestionOption.fromJson(Map<String, dynamic> json) => QuestionOption(
        optionId: json['optionId'] as String,
        questionId: json['questionId'] as String,
        optionKey: json['optionKey'] as String,
        optionText: json['optionText'] as String,
        isCorrect: json['isCorrect'] as bool,
        optionRationale: json['optionRationale'] as String,
      );

  QuestionOption copyWith({
    String? optionId,
    String? questionId,
    String? optionKey,
    String? optionText,
    bool? isCorrect,
    String? optionRationale,
  }) =>
      QuestionOption(
        optionId: optionId ?? this.optionId,
        questionId: questionId ?? this.questionId,
        optionKey: optionKey ?? this.optionKey,
        optionText: optionText ?? this.optionText,
        isCorrect: isCorrect ?? this.isCorrect,
        optionRationale: optionRationale ?? this.optionRationale,
      );
}
