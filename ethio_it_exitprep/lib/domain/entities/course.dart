// lib/domain/entities/course.dart
// Entity 2 of 8: Course — 13 core BSc IT courses (45 credit hours).

import 'learning_entity.dart';

class Course extends LearningEntity {
  final String themeId;
  final String courseCode;
  final int courseYear;
  final int semester;
  final int creditHours;
  final double examWeightPct;
  final String priorityLevel; // P1 | P2 | P3

  const Course({
    required super.id,
    required super.title,
    super.description,
    required super.createdAt,
    required super.updatedAt,
    super.customAttributes,
    required this.themeId,
    required this.courseCode,
    this.courseYear = 1,
    this.semester = 1,
    required this.creditHours,
    required this.examWeightPct,
    required this.priorityLevel,
  });

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'themeId': themeId,
        'courseCode': courseCode,
        'courseYear': courseYear,
        'semester': semester,
        'creditHours': creditHours,
        'examWeightPct': examWeightPct,
        'priorityLevel': priorityLevel,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'customAttributes': customAttributes,
      };

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        themeId: json['themeId'] as String,
        courseCode: json['courseCode'] as String,
        courseYear: (json['courseYear'] ?? json['year'] ?? 1) as int,
        semester: (json['semester'] ?? 1) as int,
        creditHours: json['creditHours'] as int,
        examWeightPct: (json['examWeightPct'] as num).toDouble(),
        priorityLevel: json['priorityLevel'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        customAttributes: (json['customAttributes'] as Map<String, dynamic>?) ?? {},
      );

  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? themeId,
    String? courseCode,
    int? courseYear,
    int? semester,
    int? creditHours,
    double? examWeightPct,
    String? priorityLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? customAttributes,
  }) =>
      Course(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        themeId: themeId ?? this.themeId,
        courseCode: courseCode ?? this.courseCode,
        courseYear: courseYear ?? this.courseYear,
        semester: semester ?? this.semester,
        creditHours: creditHours ?? this.creditHours,
        examWeightPct: examWeightPct ?? this.examWeightPct,
        priorityLevel: priorityLevel ?? this.priorityLevel,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        customAttributes: customAttributes ?? this.customAttributes,
      );
}
