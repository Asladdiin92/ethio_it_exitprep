// lib/domain/entities/question.dart
// Entity 6 of 8: Question — assessment item linked to blueprint, chapter, and study material.

import 'learning_entity.dart';
import 'study_material.dart';

enum SourceType { nationalExitExam, universityMock, courseDrill }

enum BloomDomain { cognitive, psychomotor, affective }

extension SourceTypeExt on SourceType {
  String get value => const {
        SourceType.nationalExitExam: 'NATIONAL_EXIT_EXAM',
        SourceType.universityMock: 'UNIVERSITY_MOCK',
        SourceType.courseDrill: 'COURSE_DRILL',
      }[this]!;
  static SourceType fromString(String s) => SourceType.values.firstWhere(
        (e) => e.value == s,
        orElse: () => SourceType.nationalExitExam,
      );
}

extension BloomDomainExt on BloomDomain {
  String get value => name;
  static BloomDomain fromString(String s) =>
      BloomDomain.values.firstWhere((e) => e.name == s, orElse: () => BloomDomain.cognitive);
}

class Question extends LearningEntity {
  final String courseId;
  final String chapterId;
  final String? linkedMaterialId;
  final int examYear; // Ethiopian Calendar (2015–2018)
  final SourceType sourceType;
  final DifficultyTier difficultyTier;
  final double priorityWeight; // 0.0 – 100.0
  final BloomDomain bloomDomain;
  final String stemTitle;
  final String stemBody;
  final String generalExplanation;

  const Question({
    required super.id,
    required super.title,
    super.description,
    required super.createdAt,
    required super.updatedAt,
    super.customAttributes,
    required this.courseId,
    required this.chapterId,
    this.linkedMaterialId,
    required this.examYear,
    required this.sourceType,
    required this.difficultyTier,
    required this.priorityWeight,
    required this.bloomDomain,
    required this.stemTitle,
    required this.stemBody,
    required this.generalExplanation,
  });

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'courseId': courseId,
        'chapterId': chapterId,
        'linkedMaterialId': linkedMaterialId,
        'examYear': examYear,
        'sourceType': sourceType.value,
        'difficultyTier': difficultyTier.level,
        'priorityWeight': priorityWeight,
        'bloomDomain': bloomDomain.value,
        'stemTitle': stemTitle,
        'stemBody': stemBody,
        'generalExplanation': generalExplanation,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'customAttributes': customAttributes,
      };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        courseId: json['courseId'] as String,
        chapterId: json['chapterId'] as String,
        linkedMaterialId: json['linkedMaterialId'] as String?,
        examYear: json['examYear'] as int,
        sourceType: SourceTypeExt.fromString(json['sourceType'] as String),
        difficultyTier: DifficultyTierExt.fromInt(json['difficultyTier'] as int),
        priorityWeight: (json['priorityWeight'] as num).toDouble(),
        bloomDomain: BloomDomainExt.fromString(json['bloomDomain'] as String),
        stemTitle: json['stemTitle'] as String,
        stemBody: json['stemBody'] as String,
        generalExplanation: json['generalExplanation'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        customAttributes: (json['customAttributes'] as Map<String, dynamic>?) ?? {},
      );
}
