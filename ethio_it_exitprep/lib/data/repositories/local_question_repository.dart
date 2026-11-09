// lib/data/repositories/local_question_repository.dart
// Offline-first concrete implementation of QuestionRepository.

import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:ethio_it_exitprep/data/local/database.dart';
import 'package:ethio_it_exitprep/domain/entities/question.dart';
import 'package:ethio_it_exitprep/domain/entities/study_material.dart';
import 'package:ethio_it_exitprep/domain/repositories/curriculum_filter.dart';
import 'package:ethio_it_exitprep/domain/repositories/curriculum_repository.dart';

class LocalQuestionRepository implements QuestionRepository {
  final AppDatabase _db;
  LocalQuestionRepository(this._db);

  static Question _fromRow(Map<String, dynamic> r) {
    return Question(
      id: r['id'] as String,
      title: r['title'] as String,
      description: r['description'] as String?,
      courseId: r['course_id'] as String,
      chapterId: r['chapter_id'] as String,
      linkedMaterialId: r['linked_material_id'] as String?,
      examYear: r['exam_year'] as int,
      sourceType: SourceTypeExt.fromString(r['source_type'] as String),
      difficultyTier: DifficultyTierExt.fromInt(r['difficulty_tier'] as int),
      priorityWeight: (r['priority_weight'] as num).toDouble(),
      bloomDomain: BloomDomainExt.fromString(r['bloom_domain'] as String),
      stemTitle: r['stem_title'] as String,
      stemBody: r['stem_body'] as String,
      generalExplanation: r['general_explanation'] as String,
      createdAt: DateTime.parse(r['created_at'] as String),
      updatedAt: DateTime.parse(r['updated_at'] as String),
      customAttributes: Map<String, dynamic>.from(
          jsonDecode(r['custom_attributes'] as String? ?? '{}') as Map),
    );
  }

  @override
  Future<List<Question>> query(
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

    if (filter.courseId != null) {
      conditions.add('q.course_id = ?');
      args.add(Variable.withString(filter.courseId!));
    }
    if (filter.chapterId != null) {
      conditions.add('q.chapter_id = ?');
      args.add(Variable.withString(filter.chapterId!));
    }
    if (filter.themeId != null) {
      conditions.add('co.theme_id = ?');
      args.add(Variable.withString(filter.themeId!));
    }
    if (filter.examYear != null) {
      conditions.add('q.exam_year = ?');
      args.add(Variable.withInt(filter.examYear!));
    }
    if (filter.sourceType != null) {
      conditions.add('q.source_type = ?');
      args.add(Variable.withString(filter.sourceType!.value));
    }
    if (filter.difficultyTier != null) {
      conditions.add('q.difficulty_tier = ?');
      args.add(Variable.withInt(filter.difficultyTier!.level));
    }
    if (filter.titleContains != null) {
      conditions.add('(q.stem_title LIKE ? OR q.stem_body LIKE ?)');
      args.add(Variable.withString('%${filter.titleContains}%'));
      args.add(Variable.withString('%${filter.titleContains}%'));
    }
    if (ftsIds != null) {
      final placeholders = ftsIds.map((_) => '?').join(',');
      conditions.add('q.id IN ($placeholders)');
      args.addAll(ftsIds.map((id) => Variable.withString(id)));
    }

    final orderBy = _questionSortSql(sort);
    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    final sql = '''
      SELECT q.*
      FROM questions q
      JOIN courses co  ON co.id = q.course_id
      JOIN chapters ch ON ch.id = q.chapter_id
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
  Future<Question?> getById(String id) async {
    final rows = await _db.select(
      'SELECT * FROM questions WHERE id = ? LIMIT 1;',
      [Variable.withString(id)],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<void> upsert(Question q) async {
    await _db.execute('''
      INSERT OR REPLACE INTO questions
        (id, course_id, chapter_id, linked_material_id, title, description,
         exam_year, source_type, difficulty_tier, priority_weight, bloom_domain,
         stem_title, stem_body, general_explanation, custom_attributes,
         created_at, updated_at)
      VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);
    ''', [
      q.id, q.courseId, q.chapterId, q.linkedMaterialId,
      q.title, q.description, q.examYear, q.sourceType.value,
      q.difficultyTier.level, q.priorityWeight, q.bloomDomain.value,
      q.stemTitle, q.stemBody, q.generalExplanation,
      jsonEncode(q.customAttributes),
      q.createdAt.toIso8601String(), q.updatedAt.toIso8601String(),
    ]);
  }

  @override
  Future<void> upsertAll(List<Question> questions) async {
    for (final q in questions) {
      await upsert(q);
    }
  }

  @override
  Future<void> deleteById(String id) async {
    await _db.execute(
      'DELETE FROM questions WHERE id = ?;',
      [Variable.withString(id)],
    );
  }

  String _questionSortSql(CurriculumSortOrder sort) {
    switch (sort) {
      case CurriculumSortOrder.priorityDesc:
        return 'q.priority_weight DESC, q.difficulty_tier ASC';
      case CurriculumSortOrder.simplicityToHardness:
        return 'q.difficulty_tier ASC, q.priority_weight DESC';
      case CurriculumSortOrder.hardnessToSimplicity:
        return 'q.difficulty_tier DESC, q.exam_year DESC';
      case CurriculumSortOrder.examYearDesc:
        return 'q.exam_year DESC, co.course_code ASC';
      case CurriculumSortOrder.chapterSequenceAsc:
        return 'ch.chapter_number ASC, ch.sequence_order ASC';
      case CurriculumSortOrder.weaknessFirst:
        return 'q.priority_weight DESC, q.difficulty_tier ASC';
    }
  }
}
