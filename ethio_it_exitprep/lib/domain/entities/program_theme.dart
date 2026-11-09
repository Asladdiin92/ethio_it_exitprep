// lib/domain/entities/program_theme.dart
// Entity 1 of 8: ProgramTheme — the 5 FDRE national exit exam thematic areas.

import 'learning_entity.dart';

class ProgramTheme extends LearningEntity {
  final String themeCode;
  final double blueprintSharePct;
  final int priorityRank;

  const ProgramTheme({
    required super.id,
    required super.title,
    super.description,
    required super.createdAt,
    required super.updatedAt,
    super.customAttributes,
    required this.themeCode,
    required this.blueprintSharePct,
    required this.priorityRank,
  });

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'themeCode': themeCode,
        'blueprintSharePct': blueprintSharePct,
        'priorityRank': priorityRank,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'customAttributes': customAttributes,
      };

  factory ProgramTheme.fromJson(Map<String, dynamic> json) => ProgramTheme(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        themeCode: json['themeCode'] as String,
        blueprintSharePct: (json['blueprintSharePct'] as num).toDouble(),
        priorityRank: json['priorityRank'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        customAttributes: (json['customAttributes'] as Map<String, dynamic>?) ?? {},
      );

  ProgramTheme copyWith({
    String? id,
    String? title,
    String? description,
    String? themeCode,
    double? blueprintSharePct,
    int? priorityRank,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? customAttributes,
  }) =>
      ProgramTheme(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        themeCode: themeCode ?? this.themeCode,
        blueprintSharePct: blueprintSharePct ?? this.blueprintSharePct,
        priorityRank: priorityRank ?? this.priorityRank,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        customAttributes: customAttributes ?? this.customAttributes,
      );
}
