// lib/data/repositories/local_study_material_repository.dart
// Offline-first concrete implementation of StudyMaterialRepository.
// All queries go through the local SQLite database; FTS5 is used for searchQuery.

import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:ethio_it_exitprep/data/local/database.dart';
import 'package:ethio_it_exitprep/domain/entities/study_material.dart';
import 'package:ethio_it_exitprep/domain/repositories/curriculum_filter.dart';
import 'package:ethio_it_exitprep/domain/repositories/curriculum_repository.dart';

class LocalStudyMaterialRepository implements StudyMaterialRepository {
  final AppDatabase _db;
  LocalStudyMaterialRepository(this._db);

  // ── Mapping ───────────────────────────────────────────────────────────────
  static StudyMaterial _fromRow(Map<String, dynamic> r) {
    return StudyMaterial(
      id: r['id'] as String,
      title: r['title'] as String,
      description: r['description'] as String?,
      chapterId: r['chapter_id'] as String,
      contentStyle: ContentStyleExt.fromString(r['content_style'] as String),
      difficultyTier: DifficultyTierExt.fromInt(r['difficulty_tier'] as int),
      priorityTier: PriorityTierExt.fromString(r['priority_tier'] as String),
      contentBlocks: List<Map<String, dynamic>>.from(
          jsonDecode(r['content_blocks'] as String? ?? '[]') as List),
      tags: List<String>.from(jsonDecode(r['tags'] as String? ?? '[]') as List),
      createdAt: DateTime.parse(r['created_at'] as String),
      updatedAt: DateTime.parse(r['updated_at'] as String),
      customAttributes: Map<String, dynamic>.from(
          jsonDecode(r['custom_attributes'] as String? ?? '{}') as Map),
    );
  }

  // ── Core multi-dimensional query ──────────────────────────────────────────
  @override
  Future<List<StudyMaterial>> query(
    CurriculumFilter filter, {
    CurriculumSortOrder sort = CurriculumSortOrder.priorityDesc,
    int limit = 50,
    int offset = 0,
  }) async {
    List<String>? ftsIds;
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      ftsIds = await _db.ftsSearch(filter.searchQuery!.trim(), limit: 500);
      if (ftsIds.isEmpty) return [];
    }

    final conditions = <String>[];
    final args = <Variable<Object>>[];

    if (filter.chapterId != null) {
      conditions.add('sm.chapter_id = ?');
      args.add(Variable.withString(filter.chapterId!));
    }
    if (filter.courseId != null) {
      conditions.add('ch.course_id = ?');
      args.add(Variable.withString(filter.courseId!));
    }
    if (filter.themeId != null) {
      conditions.add('co.theme_id = ?');
      args.add(Variable.withString(filter.themeId!));
    }
    if (filter.contentStyle != null) {
      conditions.add('sm.content_style = ?');
      args.add(Variable.withString(filter.contentStyle!.name));
    }
    if (filter.difficultyTier != null) {
      conditions.add('sm.difficulty_tier = ?');
      args.add(Variable.withInt(filter.difficultyTier!.level));
    }
    if (filter.priorityTier != null) {
      conditions.add('sm.priority_tier = ?');
      args.add(Variable.withString(filter.priorityTier!.value));
    }
    if (filter.titleContains != null) {
      conditions.add('sm.title LIKE ?');
      args.add(Variable.withString('%${filter.titleContains}%'));
    }
    if (ftsIds != null) {
      final placeholders = ftsIds.map((_) => '?').join(',');
      conditions.add('sm.id IN ($placeholders)');
      args.addAll(ftsIds.map((id) => Variable.withString(id)));
    }

    final orderBy = _materialSortSql(sort);
    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final sql = '''
      SELECT sm.*
      FROM study_materials sm
      JOIN chapters ch ON ch.id = sm.chapter_id
      JOIN courses co  ON co.id = ch.course_id
      $where
      ORDER BY $orderBy
      LIMIT ? OFFSET ?;
    ''';
    args.add(Variable.withInt(limit));
    args.add(Variable.withInt(offset));

    final rows = await _db.select(sql, args);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<StudyMaterial?> getById(String id) async {
    final rows = await _db.select(
      'SELECT * FROM study_materials WHERE id = ? LIMIT 1;',
      [Variable.withString(id)],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<void> upsert(StudyMaterial m) async {
    await _db.execute('''
      INSERT OR REPLACE INTO study_materials
        (id, chapter_id, title, description, content_style, difficulty_tier,
         priority_tier, content_blocks, tags, custom_attributes,
         created_at, updated_at)
      VALUES (?,?,?,?,?,?,?,?,?,?,?,?);
    ''', [
      m.id, m.chapterId, m.title, m.description,
      m.contentStyle.name, m.difficultyTier.level, m.priorityTier.value,
      jsonEncode(m.contentBlocks), jsonEncode(m.tags),
      jsonEncode(m.customAttributes),
      m.createdAt.toIso8601String(), m.updatedAt.toIso8601String(),
    ]);
  }

  @override
  Future<void> upsertAll(List<StudyMaterial> materials) async {
    for (final m in materials) {
      await upsert(m);
    }
  }

  @override
  Future<void> deleteById(String id) async {
    await _db.execute('DELETE FROM study_materials WHERE id = ?;', [id]);
  }

  String _materialSortSql(CurriculumSortOrder sort) {
    switch (sort) {
      case CurriculumSortOrder.priorityDesc:
        return 'ch.priority_score DESC, sm.difficulty_tier ASC';
      case CurriculumSortOrder.simplicityToHardness:
        return 'sm.difficulty_tier ASC, ch.priority_score DESC';
      case CurriculumSortOrder.hardnessToSimplicity:
        return 'sm.difficulty_tier DESC, sm.updated_at DESC';
      case CurriculumSortOrder.examYearDesc:
        return 'co.course_code ASC, sm.title ASC';
      case CurriculumSortOrder.chapterSequenceAsc:
        return 'ch.chapter_number ASC, ch.sequence_order ASC';
      case CurriculumSortOrder.weaknessFirst:
        return 'ch.priority_score DESC, sm.difficulty_tier ASC';
    }
  }
}
