// lib/domain/entities/study_material.dart
// Entity 4 of 8: StudyMaterial — polymorphic study content types.

import 'learning_entity.dart';

enum ContentStyle { conceptNote, quickSummary, codeWalkthrough, formulaSheet, flashcard }

enum DifficultyTier { simple, moderate, hard }

enum PriorityTier { p1Critical, p2HighYield, p3Supplementary }

extension ContentStyleExt on ContentStyle {
  String get value => name;
  static ContentStyle fromString(String s) =>
      ContentStyle.values.firstWhere((e) => e.name == s, orElse: () => ContentStyle.conceptNote);
}

extension DifficultyTierExt on DifficultyTier {
  int get level => index + 1; // 1=simple, 2=moderate, 3=hard
  static DifficultyTier fromInt(int v) =>
      DifficultyTier.values[v.clamp(1, 3) - 1];
}

extension PriorityTierExt on PriorityTier {
  String get value => ['P1_CRITICAL', 'P2_HIGH_YIELD', 'P3_SUPPLEMENTARY'][index];
  static PriorityTier fromString(String s) {
    if (s == 'P1_CRITICAL') return PriorityTier.p1Critical;
    if (s == 'P2_HIGH_YIELD') return PriorityTier.p2HighYield;
    return PriorityTier.p3Supplementary;
  }
}

class StudyMaterial extends LearningEntity {
  final String chapterId;
  final ContentStyle contentStyle;
  final DifficultyTier difficultyTier;
  final PriorityTier priorityTier;
  /// Ordered list of content blocks (Markdown, code, formula, etc.)
  final List<Map<String, dynamic>> contentBlocks;
  final List<String> tags;

  const StudyMaterial({
    required super.id,
    required super.title,
    super.description,
    required super.createdAt,
    required super.updatedAt,
    super.customAttributes,
    required this.chapterId,
    required this.contentStyle,
    required this.difficultyTier,
    required this.priorityTier,
    this.contentBlocks = const [],
    this.tags = const [],
  });

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'chapterId': chapterId,
        'contentStyle': contentStyle.name,
        'difficultyTier': difficultyTier.level,
        'priorityTier': priorityTier.value,
        'contentBlocks': contentBlocks,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'customAttributes': customAttributes,
      };

  factory StudyMaterial.fromJson(Map<String, dynamic> json) => StudyMaterial(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        chapterId: json['chapterId'] as String,
        contentStyle: ContentStyleExt.fromString(json['contentStyle'] as String),
        difficultyTier: DifficultyTierExt.fromInt(json['difficultyTier'] as int),
        priorityTier: PriorityTierExt.fromString(json['priorityTier'] as String),
        contentBlocks: List<Map<String, dynamic>>.from(json['contentBlocks'] ?? []),
        tags: List<String>.from(json['tags'] ?? []),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        customAttributes: (json['customAttributes'] as Map<String, dynamic>?) ?? {},
      );
}
