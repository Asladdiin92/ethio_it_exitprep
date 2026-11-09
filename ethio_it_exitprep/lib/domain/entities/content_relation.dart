// lib/domain/entities/content_relation.dart
// Entity 5 of 8: ContentRelation — semantic graph links between entities.

enum RelationType {
  prerequisiteOf,
  relatedConcept,
  testedByQuestion,
  explainsAnswerFor,
}

extension RelationTypeExt on RelationType {
  String get value => const {
        RelationType.prerequisiteOf: 'PREREQUISITE_OF',
        RelationType.relatedConcept: 'RELATED_CONCEPT',
        RelationType.testedByQuestion: 'TESTED_BY_QUESTION',
        RelationType.explainsAnswerFor: 'EXPLAINS_ANSWER_FOR',
      }[this]!;

  static RelationType fromString(String s) => RelationType.values.firstWhere(
        (e) => e.value == s,
        orElse: () => RelationType.relatedConcept,
      );
}

class ContentRelation {
  final String relationId;
  final String sourceType;
  final String sourceId;
  final String targetType;
  final String targetId;
  final RelationType relationType;
  final double relevanceWeight; // 0.0 – 1.0

  const ContentRelation({
    required this.relationId,
    required this.sourceType,
    required this.sourceId,
    required this.targetType,
    required this.targetId,
    required this.relationType,
    this.relevanceWeight = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'relationId': relationId,
        'sourceType': sourceType,
        'sourceId': sourceId,
        'targetType': targetType,
        'targetId': targetId,
        'relationType': relationType.value,
        'relevanceWeight': relevanceWeight,
      };

  factory ContentRelation.fromJson(Map<String, dynamic> json) => ContentRelation(
        relationId: json['relationId'] as String,
        sourceType: json['sourceType'] as String,
        sourceId: json['sourceId'] as String,
        targetType: json['targetType'] as String,
        targetId: json['targetId'] as String,
        relationType: RelationTypeExt.fromString(json['relationType'] as String),
        relevanceWeight: (json['relevanceWeight'] as num?)?.toDouble() ?? 1.0,
      );
}
