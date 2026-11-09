// lib/domain/entities/chapter.dart
// Entity 3 of 8: Chapter — sequential course modules with priority scoring.

import 'learning_entity.dart';

class Chapter extends LearningEntity {
  final String courseId;
  final int chapterNumber;
  final int sequenceOrder;
  final double priorityScore; // 1..100
  final int estMinutes;

  const Chapter({
    required super.id,
    required super.title,
    super.description,
    required super.createdAt,
    required super.updatedAt,
    super.customAttributes,
    required this.courseId,
    required this.chapterNumber,
    required this.sequenceOrder,
    required this.priorityScore,
    required this.estMinutes,
  });

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'courseId': courseId,
        'chapterNumber': chapterNumber,
        'sequenceOrder': sequenceOrder,
        'priorityScore': priorityScore,
        'estMinutes': estMinutes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'customAttributes': customAttributes,
      };

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        courseId: json['courseId'] as String,
        chapterNumber: json['chapterNumber'] as int,
        sequenceOrder: json['sequenceOrder'] as int,
        priorityScore: (json['priorityScore'] as num).toDouble(),
        estMinutes: json['estMinutes'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        customAttributes: (json['customAttributes'] as Map<String, dynamic>?) ?? {},
      );

  Chapter copyWith({
    String? id,
    String? title,
    String? description,
    String? courseId,
    int? chapterNumber,
    int? sequenceOrder,
    double? priorityScore,
    int? estMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? customAttributes,
  }) =>
      Chapter(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        courseId: courseId ?? this.courseId,
        chapterNumber: chapterNumber ?? this.chapterNumber,
        sequenceOrder: sequenceOrder ?? this.sequenceOrder,
        priorityScore: priorityScore ?? this.priorityScore,
        estMinutes: estMinutes ?? this.estMinutes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        customAttributes: customAttributes ?? this.customAttributes,
      );
}
