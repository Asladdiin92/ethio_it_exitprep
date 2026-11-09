// lib/data/repositories/local_simple_repositories.dart
// Offline-first implementations for ProgramTheme, Course, Chapter,
// ContentRelation, QuestionOption, and StudentProgress repositories.

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:ethio_it_exitprep/data/local/database.dart';
import 'package:ethio_it_exitprep/domain/entities/program_theme.dart';
import 'package:ethio_it_exitprep/domain/entities/course.dart';
import 'package:ethio_it_exitprep/domain/entities/chapter.dart';
import 'package:ethio_it_exitprep/domain/entities/content_relation.dart';
import 'package:ethio_it_exitprep/domain/entities/question_option.dart';
import 'package:ethio_it_exitprep/domain/entities/student_progress.dart';
import 'package:ethio_it_exitprep/domain/repositories/curriculum_repository.dart';

DateTime _dt(Map<String, dynamic> r, String key) =>
    DateTime.parse(r[key] as String);

// ── ProgramTheme ──────────────────────────────────────────────────────────────
class LocalProgramThemeRepository implements ProgramThemeRepository {
  final AppDatabase _db;
  LocalProgramThemeRepository(this._db);

  static ProgramTheme _fromRow(Map<String, dynamic> r) => ProgramTheme(
    id: r['id'] as String,
    title: r['title'] as String,
    description: r['description'] as String?,
    themeCode: r['theme_code'] as String,
    blueprintSharePct: (r['blueprint_share_pct'] as num).toDouble(),
    priorityRank: r['priority_rank'] as int,
    createdAt: _dt(r, 'created_at'),
    updatedAt: _dt(r, 'updated_at'),
    customAttributes: Map<String, dynamic>.from(
      jsonDecode(r['custom_attributes'] as String? ?? '{}') as Map,
    ),
  );

  @override
  Future<List<ProgramTheme>> getAll() async {
    final rows = await _db.select(
      'SELECT * FROM program_themes ORDER BY priority_rank ASC;',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<ProgramTheme?> getById(String id) async {
    final rows = await _db.select(
      'SELECT * FROM program_themes WHERE id = ? LIMIT 1;',
      [Variable.withString(id)],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<void> upsert(ProgramTheme t) async {
    await _db.execute(
      '''
      INSERT OR REPLACE INTO program_themes
        (id, theme_code, title, description, blueprint_share_pct,
         priority_rank, custom_attributes, created_at, updated_at)
      VALUES (?,?,?,?,?,?,?,?,?);
    ''',
      [
        t.id,
        t.themeCode,
        t.title,
        t.description,
        t.blueprintSharePct,
        t.priorityRank,
        jsonEncode(t.customAttributes),
        t.createdAt.toIso8601String(),
        t.updatedAt.toIso8601String(),
      ],
    );
  }

  @override
  Future<void> upsertAll(List<ProgramTheme> themes) async {
    for (final t in themes) {
      await upsert(t);
    }
  }
}

// ── Course ─────────────────────────────────────────────────────────────────────
class LocalCourseRepository implements CourseRepository {
  final AppDatabase _db;
  LocalCourseRepository(this._db);

  static Course _fromRow(Map<String, dynamic> r) => Course(
    id: r['id'] as String,
    title: r['title'] as String,
    description: r['description'] as String?,
    themeId: r['theme_id'] as String,
    courseCode: r['course_code'] as String,
    courseYear: (r['course_year'] as int?) ?? 1,
    semester: (r['semester'] as int?) ?? 1,
    creditHours: r['credit_hours'] as int,
    examWeightPct: (r['exam_weight_pct'] as num).toDouble(),
    priorityLevel: r['priority_level'] as String,
    createdAt: _dt(r, 'created_at'),
    updatedAt: _dt(r, 'updated_at'),
    customAttributes: Map<String, dynamic>.from(
      jsonDecode(r['custom_attributes'] as String? ?? '{}') as Map,
    ),
  );

  @override
  Future<List<Course>> getAll() async {
    final rows = await _db.select(
      'SELECT * FROM courses ORDER BY exam_weight_pct DESC;',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<Course>> getByTheme(String themeId) async {
    final rows = await _db.select(
      'SELECT * FROM courses WHERE theme_id = ? ORDER BY exam_weight_pct DESC;',
      [Variable.withString(themeId)],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Course?> getById(String id) async {
    final rows = await _db.select(
      'SELECT * FROM courses WHERE id = ? LIMIT 1;',
      [Variable.withString(id)],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<void> upsert(Course c) async {
    await _db.execute(
      '''
      INSERT OR REPLACE INTO courses
        (id, theme_id, course_code, title, description, course_year, semester, credit_hours,
         exam_weight_pct, priority_level, custom_attributes,
         created_at, updated_at)
      VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?);
    ''',
      [
        c.id,
        c.themeId,
        c.courseCode,
        c.title,
        c.description,
        c.courseYear,
        c.semester,
        c.creditHours,
        c.examWeightPct,
        c.priorityLevel,
        jsonEncode(c.customAttributes),
        c.createdAt.toIso8601String(),
        c.updatedAt.toIso8601String(),
      ],
    );
  }

  @override
  Future<void> upsertAll(List<Course> courses) async {
    for (final c in courses) {
      await upsert(c);
    }
  }
}

// ── Chapter ───────────────────────────────────────────────────────────────────
class LocalChapterRepository implements ChapterRepository {
  final AppDatabase _db;
  LocalChapterRepository(this._db);

  static Chapter _fromRow(Map<String, dynamic> r) => Chapter(
    id: r['id'] as String,
    title: r['title'] as String,
    description: r['description'] as String?,
    courseId: r['course_id'] as String,
    chapterNumber: r['chapter_number'] as int,
    sequenceOrder: r['sequence_order'] as int,
    priorityScore: (r['priority_score'] as num).toDouble(),
    estMinutes: r['est_minutes'] as int,
    createdAt: _dt(r, 'created_at'),
    updatedAt: _dt(r, 'updated_at'),
    customAttributes: Map<String, dynamic>.from(
      jsonDecode(r['custom_attributes'] as String? ?? '{}') as Map,
    ),
  );

  @override
  Future<List<Chapter>> getByCourse(String courseId) async {
    final rows = await _db.select(
      'SELECT * FROM chapters WHERE course_id = ? ORDER BY sequence_order ASC;',
      [Variable.withString(courseId)],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Chapter?> getById(String id) async {
    final rows = await _db.select(
      'SELECT * FROM chapters WHERE id = ? LIMIT 1;',
      [Variable.withString(id)],
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  @override
  Future<void> upsert(Chapter ch) async {
    await _db.execute(
      '''
      INSERT OR REPLACE INTO chapters
        (id, course_id, title, description, chapter_number, sequence_order,
         priority_score, est_minutes, custom_attributes, created_at, updated_at)
      VALUES (?,?,?,?,?,?,?,?,?,?,?);
    ''',
      [
        ch.id,
        ch.courseId,
        ch.title,
        ch.description,
        ch.chapterNumber,
        ch.sequenceOrder,
        ch.priorityScore,
        ch.estMinutes,
        jsonEncode(ch.customAttributes),
        ch.createdAt.toIso8601String(),
        ch.updatedAt.toIso8601String(),
      ],
    );
  }

  @override
  Future<void> upsertAll(List<Chapter> chapters) async {
    for (final ch in chapters) {
      await upsert(ch);
    }
  }
}

// ── ContentRelation ───────────────────────────────────────────────────────────
class LocalContentRelationRepository implements ContentRelationRepository {
  final AppDatabase _db;
  LocalContentRelationRepository(this._db);

  static ContentRelation _fromRow(Map<String, dynamic> r) => ContentRelation(
    relationId: r['relation_id'] as String,
    sourceType: r['source_type'] as String,
    sourceId: r['source_id'] as String,
    targetType: r['target_type'] as String,
    targetId: r['target_id'] as String,
    relationType: RelationTypeExt.fromString(r['relation_type'] as String),
    relevanceWeight: (r['relevance_weight'] as num).toDouble(),
  );

  @override
  Future<List<ContentRelation>> getRelationsFrom(
    String sourceId, {
    RelationType? type,
  }) async {
    final sql = type == null
        ? 'SELECT * FROM content_relations WHERE source_id = ? ORDER BY relevance_weight DESC;'
        : 'SELECT * FROM content_relations WHERE source_id = ? AND relation_type = ? ORDER BY relevance_weight DESC;';
    final vars = type == null
        ? [Variable.withString(sourceId)]
        : [Variable.withString(sourceId), Variable.withString(type.value)];
    final rows = await _db.select(sql, vars);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<ContentRelation>> getRelationsTo(
    String targetId, {
    RelationType? type,
  }) async {
    final sql = type == null
        ? 'SELECT * FROM content_relations WHERE target_id = ? ORDER BY relevance_weight DESC;'
        : 'SELECT * FROM content_relations WHERE target_id = ? AND relation_type = ? ORDER BY relevance_weight DESC;';
    final vars = type == null
        ? [Variable.withString(targetId)]
        : [Variable.withString(targetId), Variable.withString(type.value)];
    final rows = await _db.select(sql, vars);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> upsert(ContentRelation r) async {
    await _db.execute(
      '''
      INSERT OR REPLACE INTO content_relations
        (relation_id, source_type, source_id, target_type, target_id,
         relation_type, relevance_weight)
      VALUES (?,?,?,?,?,?,?);
    ''',
      [
        r.relationId,
        r.sourceType,
        r.sourceId,
        r.targetType,
        r.targetId,
        r.relationType.value,
        r.relevanceWeight,
      ],
    );
  }

  @override
  Future<void> upsertAll(List<ContentRelation> relations) async {
    for (final r in relations) {
      await upsert(r);
    }
  }
}

// ── QuestionOption ────────────────────────────────────────────────────────────
class LocalQuestionOptionRepository implements QuestionOptionRepository {
  final AppDatabase _db;
  LocalQuestionOptionRepository(this._db);

  static QuestionOption _fromRow(Map<String, dynamic> r) => QuestionOption(
    optionId: r['option_id'] as String,
    questionId: r['question_id'] as String,
    optionKey: r['option_key'] as String,
    optionText: r['option_text'] as String,
    isCorrect: (r['is_correct'] as int) == 1,
    optionRationale: r['option_rationale'] as String,
  );

  @override
  Future<List<QuestionOption>> getByQuestion(String questionId) async {
    final rows = await _db.select(
      'SELECT * FROM question_options WHERE question_id = ? ORDER BY option_key ASC;',
      [Variable.withString(questionId)],
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> upsert(QuestionOption o) async {
    await _db.execute(
      '''
      INSERT OR REPLACE INTO question_options
        (option_id, question_id, option_key, option_text, is_correct, option_rationale)
      VALUES (?,?,?,?,?,?);
    ''',
      [
        o.optionId,
        o.questionId,
        o.optionKey,
        o.optionText,
        o.isCorrect ? 1 : 0,
        o.optionRationale,
      ],
    );
  }

  @override
  Future<void> upsertAll(List<QuestionOption> options) async {
    for (final o in options) {
      await upsert(o);
    }
  }

  @override
  Future<void> deleteByQuestionId(String questionId) async {
    await _db.execute('DELETE FROM question_options WHERE question_id = ?;', [
      Variable.withString(questionId),
    ]);
  }
}

// ── StudentProgress ───────────────────────────────────────────────────────────
class LocalStudentProgressRepository implements StudentProgressRepository {
  final AppDatabase _db;
  LocalStudentProgressRepository(this._db);

  @override
  Future<StudentProgress> getOrCreate(String studentId) async {
    final rows = await _db.select(
      'SELECT * FROM student_progress WHERE student_id = ? LIMIT 1;',
      [Variable.withString(studentId)],
    );
    if (rows.isEmpty) {
      final p = StudentProgress(
        studentId: studentId,
        lastSynced: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
      await saveProgress(p);
      return p;
    }
    final r = rows.first;
    final masteryJson = jsonDecode(
      r['mastery_by_chapter'] as String? ?? '{}',
    ) as Map<String, dynamic>;
    return StudentProgress(
      studentId: studentId,
      masteryByChapter: masteryJson.map(
        (k, v) =>
            MapEntry(k, ChapterMastery.fromJson(v as Map<String, dynamic>)),
      ),
      bookmarkedIds: List<String>.from(
        jsonDecode(r['bookmarked_ids'] as String? ?? '[]') as List,
      ),
      weaknessPriorityQueue: List<String>.from(
        jsonDecode(r['weakness_priority_queue'] as String? ?? '[]') as List,
      ),
      lastSynced: DateTime.parse(r['last_synced'] as String),
    );
  }

  @override
  Future<void> saveProgress(StudentProgress p) async {
    await _db.execute(
      '''
      INSERT OR REPLACE INTO student_progress
        (student_id, mastery_by_chapter, bookmarked_ids,
         weakness_priority_queue, last_synced)
      VALUES (?,?,?,?,?);
    ''',
      [
        p.studentId,
        jsonEncode(p.masteryByChapter.map((k, v) => MapEntry(k, v.toJson()))),
        jsonEncode(p.bookmarkedIds),
        jsonEncode(p.weaknessPriorityQueue),
        p.lastSynced.toIso8601String(),
      ],
    );
  }

  @override
  Future<void> recordAttempt(ExamAttempt a) async {
    await getOrCreate(a.studentId);
    await _db.execute(
      '''
      INSERT OR REPLACE INTO exam_attempts
        (attempt_id, student_id, started_at, completed_at,
         total_questions, correct_answers, score_percent, answer_map,
         synced_to_cloud)
      VALUES (?,?,?,?,?,?,?,?,?);
    ''',
      [
        a.attemptId,
        a.studentId,
        a.startedAt.toIso8601String(),
        a.completedAt?.toIso8601String(),
        a.totalQuestions,
        a.correctAnswers,
        a.scorePercent,
        jsonEncode(a.answerMap),
        a.syncedToCloud ? 1 : 0,
      ],
    );
  }

  @override
  Future<List<ExamAttempt>> getUnsyncedAttempts(String studentId) async {
    final rows = await _db.select(
      '''
      SELECT * FROM exam_attempts
      WHERE student_id = ? AND synced_to_cloud = 0
      ORDER BY started_at DESC;
    ''',
      [Variable.withString(studentId)],
    );
    return rows
        .map(
          (r) => ExamAttempt(
            attemptId: r['attempt_id'] as String,
            studentId: r['student_id'] as String,
            startedAt: DateTime.parse(r['started_at'] as String),
            completedAt: r['completed_at'] != null
                ? DateTime.parse(r['completed_at'] as String)
                : null,
            totalQuestions: r['total_questions'] as int,
            correctAnswers: r['correct_answers'] as int,
            scorePercent: (r['score_percent'] as num).toDouble(),
            answerMap: Map<String, String>.from(
              jsonDecode(r['answer_map'] as String? ?? '{}') as Map,
            ),
            syncedToCloud: (r['synced_to_cloud'] as int) == 1,
          ),
        )
        .toList();
  }

  @override
  Future<void> markAttemptSynced(String attemptId) async {
    await _db.execute(
      'UPDATE exam_attempts SET synced_to_cloud = 1 WHERE attempt_id = ?;',
      [attemptId],
    );
  }

  @override
  Future<void> updateChapterMastery(
    String studentId,
    ChapterMastery mastery,
  ) async {
    final progress = await getOrCreate(studentId);
    final updated = Map<String, ChapterMastery>.from(progress.masteryByChapter)
      ..[mastery.chapterId] = mastery;
    final queue = updated.entries.toList()
      ..sort((a, b) => (b.value.masteryPct - a.value.masteryPct).sign.toInt());
    await saveProgress(
      StudentProgress(
        studentId: studentId,
        masteryByChapter: updated,
        bookmarkedIds: progress.bookmarkedIds,
        weaknessPriorityQueue: queue.map((e) => e.key).toList(),
        examAttempts: progress.examAttempts,
        lastSynced: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> toggleBookmark(String studentId, String itemId) async {
    final progress = await getOrCreate(studentId);
    final bookmarks = List<String>.from(progress.bookmarkedIds);
    if (bookmarks.contains(itemId)) {
      bookmarks.remove(itemId);
    } else {
      bookmarks.add(itemId);
    }
    await saveProgress(
      StudentProgress(
        studentId: studentId,
        masteryByChapter: progress.masteryByChapter,
        bookmarkedIds: bookmarks,
        weaknessPriorityQueue: progress.weaknessPriorityQueue,
        examAttempts: progress.examAttempts,
        lastSynced: progress.lastSynced,
      ),
    );
  }
}
