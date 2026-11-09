// lib/data/local/database.dart
// Drift/SQLite offline-first persistence engine for EthioIT ExitPrep.
// Contains 8 canonical entity tables, composite indexes, and FTS5 virtual table.

import 'dart:io';
import 'dart:ffi';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/open.dart';

void _ensureSqliteLinux() {
  if (Platform.isLinux) {
    open.overrideFor(OperatingSystem.linux, () {
      final candidates = [
        'libsqlite3.so',
        'libsqlite3.so.0',
        '/lib64/libsqlite3.so.0',
        '/usr/lib/x86_64-linux-gnu/libsqlite3.so.0',
      ];
      for (final c in candidates) {
        try {
          return DynamicLibrary.open(c);
        } catch (_) {}
      }
      return DynamicLibrary.process();
    });
  }
}

class AppDatabase {
  static AppDatabase? _instance;
  final DatabaseConnection _connection;
  late final _DriftExecutor _executor;
  bool _initialized = false;

  AppDatabase._(this._connection) {
    _executor = _DriftExecutor(_connection);
  }

  /// Default file-backed singleton instance.
  static Future<AppDatabase> getInstance() async {
    _ensureSqliteLinux();
    if (_instance != null && _instance!._initialized) return _instance!;
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'ethio_it_exitprep.sqlite'));
    final connection = DatabaseConnection(NativeDatabase.createInBackground(file));
    final db = AppDatabase._(connection);
    await db.initialize();
    _instance = db;
    return db;
  }

  /// In-memory database factory for testing.
  static Future<AppDatabase> createInMemory() async {
    _ensureSqliteLinux();
    final connection = DatabaseConnection(NativeDatabase.memory());
    final db = AppDatabase._(connection);
    await db.initialize();
    return db;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    await _executor.customStatement('PRAGMA foreign_keys = ON;');
    await _executor.customStatement('PRAGMA journal_mode = WAL;');
    await _createTables();
    await _migrateCourseColumns();
    await _createIndexes();
    await _createFts5Table();
    _initialized = true;
  }

  Future<void> _createTables() async {
    await _executor.customStatement('''
      CREATE TABLE IF NOT EXISTS program_themes (
        id TEXT PRIMARY KEY,
        theme_code TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        blueprint_share_pct REAL DEFAULT 0.0,
        priority_rank INTEGER DEFAULT 1,
        custom_attributes TEXT DEFAULT '{}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    await _executor.customStatement('''
      CREATE TABLE IF NOT EXISTS courses (
        id TEXT PRIMARY KEY,
        theme_id TEXT NOT NULL REFERENCES program_themes(id),
        course_code TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        course_year INTEGER DEFAULT 1,
        semester INTEGER DEFAULT 1,
        credit_hours INTEGER DEFAULT 3,
        exam_weight_pct REAL DEFAULT 0.0,
        priority_level TEXT DEFAULT 'P2',
        custom_attributes TEXT DEFAULT '{}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    await _executor.customStatement('''
      CREATE TABLE IF NOT EXISTS chapters (
        id TEXT PRIMARY KEY,
        course_id TEXT NOT NULL REFERENCES courses(id),
        title TEXT NOT NULL,
        description TEXT,
        chapter_number INTEGER NOT NULL,
        sequence_order INTEGER NOT NULL,
        priority_score REAL DEFAULT 50.0,
        est_minutes INTEGER DEFAULT 60,
        custom_attributes TEXT DEFAULT '{}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    await _executor.customStatement('''
      CREATE TABLE IF NOT EXISTS study_materials (
        id TEXT PRIMARY KEY,
        chapter_id TEXT NOT NULL REFERENCES chapters(id),
        title TEXT NOT NULL,
        description TEXT,
        content_style TEXT NOT NULL,
        difficulty_tier INTEGER DEFAULT 1,
        priority_tier TEXT DEFAULT 'P2_HIGH_YIELD',
        content_blocks TEXT DEFAULT '[]',
        tags TEXT DEFAULT '[]',
        custom_attributes TEXT DEFAULT '{}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    await _executor.customStatement('''
      CREATE TABLE IF NOT EXISTS content_relations (
        relation_id TEXT PRIMARY KEY,
        source_type TEXT NOT NULL,
        source_id TEXT NOT NULL,
        target_type TEXT NOT NULL,
        target_id TEXT NOT NULL,
        relation_type TEXT NOT NULL,
        relevance_weight REAL DEFAULT 1.0
      );
    ''');
    await _executor.customStatement('''
      CREATE TABLE IF NOT EXISTS questions (
        id TEXT PRIMARY KEY,
        course_id TEXT NOT NULL REFERENCES courses(id),
        chapter_id TEXT NOT NULL REFERENCES chapters(id),
        linked_material_id TEXT,
        title TEXT NOT NULL,
        description TEXT,
        exam_year INTEGER NOT NULL,
        source_type TEXT NOT NULL,
        difficulty_tier INTEGER DEFAULT 1,
        priority_weight REAL DEFAULT 50.0,
        bloom_domain TEXT DEFAULT 'cognitive',
        stem_title TEXT NOT NULL,
        stem_body TEXT NOT NULL,
        general_explanation TEXT NOT NULL,
        custom_attributes TEXT DEFAULT '{}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');
    await _executor.customStatement('''
      CREATE TABLE IF NOT EXISTS question_options (
        option_id TEXT PRIMARY KEY,
        question_id TEXT NOT NULL REFERENCES questions(id),
        option_key TEXT NOT NULL,
        option_text TEXT NOT NULL,
        is_correct INTEGER DEFAULT 0,
        option_rationale TEXT NOT NULL
      );
    ''');
    await _executor.customStatement('''
      CREATE TABLE IF NOT EXISTS student_progress (
        student_id TEXT PRIMARY KEY,
        mastery_by_chapter TEXT DEFAULT '{}',
        bookmarked_ids TEXT DEFAULT '[]',
        weakness_priority_queue TEXT DEFAULT '[]',
        last_synced TEXT NOT NULL
      );
    ''');
    await _executor.customStatement('''
      CREATE TABLE IF NOT EXISTS exam_attempts (
        attempt_id TEXT PRIMARY KEY,
        student_id TEXT NOT NULL REFERENCES student_progress(student_id),
        started_at TEXT NOT NULL,
        completed_at TEXT,
        total_questions INTEGER NOT NULL,
        correct_answers INTEGER NOT NULL,
        score_percent REAL NOT NULL,
        answer_map TEXT DEFAULT '{}',
        synced_to_cloud INTEGER DEFAULT 0
      );
    ''');
    await _executor.customStatement('''
      CREATE TABLE IF NOT EXISTS sync_outbox (
        outbox_id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        queued_at TEXT NOT NULL,
        sent INTEGER DEFAULT 0
      );
    ''');
  }

  Future<void> _migrateCourseColumns() async {
    for (final statement in [
      'ALTER TABLE courses ADD COLUMN course_year INTEGER DEFAULT 1;',
      'ALTER TABLE courses ADD COLUMN semester INTEGER DEFAULT 1;',
    ]) {
      try {
        await _executor.customStatement(statement);
      } catch (_) {
        // Existing databases already have these columns.
      }
    }
  }

  Future<void> _createIndexes() async {
    await _executor.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_questions_faceted
        ON questions (course_id, chapter_id, difficulty_tier, priority_weight);
    ''');
    await _executor.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_questions_year_priority
        ON questions (exam_year DESC, priority_weight DESC);
    ''');
    await _executor.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_materials_lookup
        ON study_materials (chapter_id, content_style, difficulty_tier, priority_tier);
    ''');
    await _executor.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_relations_forward
        ON content_relations (source_id, relation_type);
    ''');
    await _executor.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_relations_reverse
        ON content_relations (target_id, relation_type);
    ''');
    await _executor.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_exam_attempts_student
        ON exam_attempts (student_id, started_at DESC);
    ''');
    await _executor.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_sync_outbox_unsent
        ON sync_outbox (sent, queued_at ASC);
    ''');
  }

  Future<void> _createFts5Table() async {
    await _executor.customStatement(
      "CREATE VIRTUAL TABLE IF NOT EXISTS curriculum_fts "
      "USING fts5("
      "entity_id UNINDEXED, entity_type UNINDEXED, "
      "course_code, chapter_title, title, body_text, tags, "
      "tokenize='unicode61', prefix='2 3 4'"
      ");",
    );
  }

  /// Run custom SELECT and return mapped rows.
  Future<List<Map<String, dynamic>>> select(
    String sql, [
    List<Variable<Object>> vars = const [],
  ]) async {
    final rows = await _executor.customSelect(sql, variables: vars).get();
    return rows.map((r) => r.data).toList();
  }

  /// Run custom INSERT / UPDATE / DELETE / DDL.
  Future<void> execute(String sql, [List<dynamic> args = const []]) async {
    await _executor.customStatement(sql, args);
  }

  /// Index any entity into curriculum_fts virtual table for BM25 full-text search.
  Future<void> indexDocument({
    required String entityId,
    required String entityType,
    required String courseCode,
    required String chapterTitle,
    required String title,
    required String bodyText,
    String tags = '',
  }) async {
    await _executor.customStatement(
      'INSERT OR REPLACE INTO curriculum_fts '
      '(entity_id, entity_type, course_code, chapter_title, title, body_text, tags) '
      'VALUES (?, ?, ?, ?, ?, ?, ?);',
      [entityId, entityType, courseCode, chapterTitle, title, bodyText, tags],
    );
  }

  /// BM25-ranked full-text search returning matching entity IDs in sub-5ms.
  Future<List<String>> ftsSearch(String query, {int limit = 50}) async {
    final rows = await _executor.customSelect(
      'SELECT entity_id FROM curriculum_fts '
      'WHERE curriculum_fts MATCH ? '
      'ORDER BY bm25(curriculum_fts) ASC LIMIT ?;',
      variables: [Variable.withString(query), Variable.withInt(limit)],
    ).get();
    return rows.map((r) => r.read<String>('entity_id')).toList();
  }

  Future<void> close() async {
    await _executor.close();
    _instance = null;
    _initialized = false;
  }
}

class _DriftExecutor extends GeneratedDatabase {
  _DriftExecutor(super.executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => 1;
}
