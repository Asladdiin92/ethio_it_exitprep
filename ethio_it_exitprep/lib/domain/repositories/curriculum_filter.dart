// lib/domain/repositories/curriculum_filter.dart
// CurriculumFilter & CurriculumSortOrder — multi-dimensional query models used by all repositories.

import '../entities/content_relation.dart';
import '../entities/study_material.dart';
import '../entities/question.dart';

/// Unified filter object accepted by every StudyMaterial and Question repository query.
class CurriculumFilter {
  // ── Hierarchy ──────────────────────────────────────────────────────────────
  final String? themeId;
  final String? courseId;
  final String? chapterId;
  final String? titleContains;

  // ── Material style ─────────────────────────────────────────────────────────
  final ContentStyle? contentStyle;

  // ── Semantic graph traversal ───────────────────────────────────────────────
  final RelationType? relationType;
  final String? relatedEntityId;

  // ── Exam metadata ──────────────────────────────────────────────────────────
  final int? examYear; // Ethiopian Calendar 2015–2018
  final SourceType? sourceType;

  // ── Difficulty & priority ──────────────────────────────────────────────────
  final DifficultyTier? difficultyTier;
  final PriorityTier? priorityTier;

  // ── Full-text search ───────────────────────────────────────────────────────
  /// Routed through curriculum_fts FTS5 virtual table with BM25 ranking.
  final String? searchQuery;

  const CurriculumFilter({
    this.themeId,
    this.courseId,
    this.chapterId,
    this.titleContains,
    this.contentStyle,
    this.relationType,
    this.relatedEntityId,
    this.examYear,
    this.sourceType,
    this.difficultyTier,
    this.priorityTier,
    this.searchQuery,
  });

  /// Returns true when at least one filter dimension has a value.
  bool get hasFilters =>
      themeId != null ||
      courseId != null ||
      chapterId != null ||
      titleContains != null ||
      contentStyle != null ||
      relationType != null ||
      relatedEntityId != null ||
      examYear != null ||
      sourceType != null ||
      difficultyTier != null ||
      priorityTier != null ||
      searchQuery != null;

  CurriculumFilter copyWith({
    String? themeId,
    String? courseId,
    String? chapterId,
    String? titleContains,
    ContentStyle? contentStyle,
    RelationType? relationType,
    String? relatedEntityId,
    int? examYear,
    SourceType? sourceType,
    DifficultyTier? difficultyTier,
    PriorityTier? priorityTier,
    String? searchQuery,
  }) =>
      CurriculumFilter(
        themeId: themeId ?? this.themeId,
        courseId: courseId ?? this.courseId,
        chapterId: chapterId ?? this.chapterId,
        titleContains: titleContains ?? this.titleContains,
        contentStyle: contentStyle ?? this.contentStyle,
        relationType: relationType ?? this.relationType,
        relatedEntityId: relatedEntityId ?? this.relatedEntityId,
        examYear: examYear ?? this.examYear,
        sourceType: sourceType ?? this.sourceType,
        difficultyTier: difficultyTier ?? this.difficultyTier,
        priorityTier: priorityTier ?? this.priorityTier,
        searchQuery: searchQuery ?? this.searchQuery,
      );

  /// Empty filter — retrieves all items.
  static const CurriculumFilter empty = CurriculumFilter();
}

/// Dynamic sort order applied to any StudyMaterial or Question query.
enum CurriculumSortOrder {
  /// Highest blueprint priority first, then easiest.
  priorityDesc,

  /// Easiest items first — builds confidence before advancing to hard content.
  simplicityToHardness,

  /// Hardest items first — challenges students preparing for exam day.
  hardnessToSimplicity,

  /// Most recent exam year first — focus on latest official papers.
  examYearDesc,

  /// Sequential chapter order — structured curriculum walk-through.
  chapterSequenceAsc,

  /// Items most urgently needing practice based on weakness score.
  /// ORDER BY (priority_score * (1.0 - mastery_pct)) DESC
  weaknessFirst,
}

extension CurriculumSortOrderSQL on CurriculumSortOrder {
  /// Returns the SQL ORDER BY clause for Drift raw queries.
  String toSqlOrderBy({String tableAlias = ''}) {
    final p = tableAlias.isEmpty ? '' : '$tableAlias.';
    switch (this) {
      case CurriculumSortOrder.priorityDesc:
        return '${p}priority_score DESC, ${p}difficulty_tier ASC';
      case CurriculumSortOrder.simplicityToHardness:
        return '${p}difficulty_tier ASC, ${p}priority_score DESC';
      case CurriculumSortOrder.hardnessToSimplicity:
        return '${p}difficulty_tier DESC, ${p}exam_year DESC';
      case CurriculumSortOrder.examYearDesc:
        return '${p}exam_year DESC, ${p}course_code ASC';
      case CurriculumSortOrder.chapterSequenceAsc:
        return '${p}chapter_number ASC, ${p}sequence_order ASC';
      case CurriculumSortOrder.weaknessFirst:
        return '(${p}priority_score * (1.0 - ${p}mastery_pct)) DESC';
    }
  }
}
