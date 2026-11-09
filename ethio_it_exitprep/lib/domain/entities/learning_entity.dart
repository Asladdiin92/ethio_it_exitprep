// lib/domain/entities/learning_entity.dart
// Abstract base class for all 8 canonical EthioIT ExitPrep domain entities.

abstract class LearningEntity {
  final String id;
  final String title;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Optional extensible JSON map for forward‑compatible blueprint fields.
  final Map<String, dynamic> customAttributes;

  const LearningEntity({
    required this.id,
    required this.title,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.customAttributes = const {},
  });

  Map<String, dynamic> toJson();
}
