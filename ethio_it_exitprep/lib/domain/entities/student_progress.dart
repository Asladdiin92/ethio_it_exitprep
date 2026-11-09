// lib/domain/entities/student_progress.dart
// Entity 8 of 8: StudentProgress & ExamAttempt — local mastery, bookmarks, and exam logs.

class ChapterMastery {
  final String chapterId;
  final double masteryPct; // 0.0 – 1.0
  final int questionsAttempted;
  final int questionsCorrect;
  final DateTime lastStudied;

  const ChapterMastery({
    required this.chapterId,
    required this.masteryPct,
    required this.questionsAttempted,
    required this.questionsCorrect,
    required this.lastStudied,
  });

  Map<String, dynamic> toJson() => {
        'chapterId': chapterId,
        'masteryPct': masteryPct,
        'questionsAttempted': questionsAttempted,
        'questionsCorrect': questionsCorrect,
        'lastStudied': lastStudied.toIso8601String(),
      };

  factory ChapterMastery.fromJson(Map<String, dynamic> json) => ChapterMastery(
        chapterId: json['chapterId'] as String,
        masteryPct: (json['masteryPct'] as num).toDouble(),
        questionsAttempted: json['questionsAttempted'] as int,
        questionsCorrect: json['questionsCorrect'] as int,
        lastStudied: DateTime.parse(json['lastStudied'] as String),
      );
}

class ExamAttempt {
  final String attemptId; // UUID
  final String studentId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int totalQuestions;
  final int correctAnswers;
  final double scorePercent;
  final Map<String, String> answerMap; // questionId → selectedOptionKey
  final bool syncedToCloud;

  const ExamAttempt({
    required this.attemptId,
    required this.studentId,
    required this.startedAt,
    this.completedAt,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.scorePercent,
    required this.answerMap,
    this.syncedToCloud = false,
  });

  Map<String, dynamic> toJson() => {
        'attemptId': attemptId,
        'studentId': studentId,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'scorePercent': scorePercent,
        'answerMap': answerMap,
        'syncedToCloud': syncedToCloud,
      };

  factory ExamAttempt.fromJson(Map<String, dynamic> json) => ExamAttempt(
        attemptId: json['attemptId'] as String,
        studentId: json['studentId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
        totalQuestions: json['totalQuestions'] as int,
        correctAnswers: json['correctAnswers'] as int,
        scorePercent: (json['scorePercent'] as num).toDouble(),
        answerMap: Map<String, String>.from(json['answerMap'] as Map),
        syncedToCloud: json['syncedToCloud'] as bool? ?? false,
      );
}

class StudentProgress {
  final String studentId;
  final Map<String, ChapterMastery> masteryByChapter;
  final List<String> bookmarkedIds;
  final List<String> weaknessPriorityQueue; // chapterIds ordered weakest-first
  final List<ExamAttempt> examAttempts;
  final DateTime lastSynced;

  const StudentProgress({
    required this.studentId,
    this.masteryByChapter = const {},
    this.bookmarkedIds = const [],
    this.weaknessPriorityQueue = const [],
    this.examAttempts = const [],
    required this.lastSynced,
  });

  /// Compute overall readiness score (0–100) as weighted avg of chapter masteries.
  double get overallReadiness {
    if (masteryByChapter.isEmpty) return 0.0;
    final sum = masteryByChapter.values.fold<double>(0, (prev, m) => prev + m.masteryPct);
    return (sum / masteryByChapter.length) * 100;
  }

  StudentProgress copyWith({
    String? studentId,
    Map<String, ChapterMastery>? masteryByChapter,
    List<String>? bookmarkedIds,
    List<String>? weaknessPriorityQueue,
    List<ExamAttempt>? examAttempts,
    DateTime? lastSynced,
  }) =>
      StudentProgress(
        studentId: studentId ?? this.studentId,
        masteryByChapter: masteryByChapter ?? this.masteryByChapter,
        bookmarkedIds: bookmarkedIds ?? this.bookmarkedIds,
        weaknessPriorityQueue: weaknessPriorityQueue ?? this.weaknessPriorityQueue,
        examAttempts: examAttempts ?? this.examAttempts,
        lastSynced: lastSynced ?? this.lastSynced,
      );

  Map<String, dynamic> toJson() => {
        'studentId': studentId,
        'masteryByChapter': masteryByChapter.map((k, v) => MapEntry(k, v.toJson())),
        'bookmarkedIds': bookmarkedIds,
        'weaknessPriorityQueue': weaknessPriorityQueue,
        'examAttempts': examAttempts.map((e) => e.toJson()).toList(),
        'lastSynced': lastSynced.toIso8601String(),
      };

  factory StudentProgress.fromJson(Map<String, dynamic> json) => StudentProgress(
        studentId: json['studentId'] as String,
        masteryByChapter: (json['masteryByChapter'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, ChapterMastery.fromJson(v as Map<String, dynamic>))),
        bookmarkedIds: List<String>.from(json['bookmarkedIds'] ?? []),
        weaknessPriorityQueue: List<String>.from(json['weaknessPriorityQueue'] ?? []),
        examAttempts: (json['examAttempts'] as List<dynamic>?)
                ?.map((e) => ExamAttempt.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        lastSynced: DateTime.parse(json['lastSynced'] as String),
      );
}
