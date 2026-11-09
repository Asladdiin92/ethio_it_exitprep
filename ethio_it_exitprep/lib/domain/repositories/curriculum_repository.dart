// lib/domain/repositories/curriculum_repository.dart
// Abstract repository interfaces for all 8 entities. Concrete implementations are offline-first
// (Drift/SQLite) and live in lib/data/repositories/.

import '../entities/program_theme.dart';
import '../entities/course.dart';
import '../entities/chapter.dart';
import '../entities/study_material.dart';
import '../entities/content_relation.dart';
import '../entities/question.dart';
import '../entities/question_option.dart';
import '../entities/student_progress.dart';
import 'curriculum_filter.dart';

// ── ProgramTheme ──────────────────────────────────────────────────────────────
abstract class ProgramThemeRepository {
  Future<List<ProgramTheme>> getAll();
  Future<ProgramTheme?> getById(String id);
  Future<void> upsert(ProgramTheme theme);
  Future<void> upsertAll(List<ProgramTheme> themes);
}

// ── Course ────────────────────────────────────────────────────────────────────
abstract class CourseRepository {
  Future<List<Course>> getAll();
  Future<List<Course>> getByTheme(String themeId);
  Future<Course?> getById(String id);
  Future<void> upsert(Course course);
  Future<void> upsertAll(List<Course> courses);
}

// ── Chapter ───────────────────────────────────────────────────────────────────
abstract class ChapterRepository {
  Future<List<Chapter>> getByCourse(String courseId);
  Future<Chapter?> getById(String id);
  Future<void> upsert(Chapter chapter);
  Future<void> upsertAll(List<Chapter> chapters);
}

// ── StudyMaterial ─────────────────────────────────────────────────────────────
abstract class StudyMaterialRepository {
  /// Core multi-dimensional query — MUST honour all non-null fields in [filter].
  Future<List<StudyMaterial>> query(
    CurriculumFilter filter, {
    CurriculumSortOrder sort = CurriculumSortOrder.priorityDesc,
    int limit = 50,
    int offset = 0,
  });

  Future<StudyMaterial?> getById(String id);
  Future<void> upsert(StudyMaterial material);
  Future<void> upsertAll(List<StudyMaterial> materials);
  Future<void> deleteById(String id);
}

// ── ContentRelation ───────────────────────────────────────────────────────────
abstract class ContentRelationRepository {
  Future<List<ContentRelation>> getRelationsFrom(String sourceId, {RelationType? type});
  Future<List<ContentRelation>> getRelationsTo(String targetId, {RelationType? type});
  Future<void> upsert(ContentRelation relation);
  Future<void> upsertAll(List<ContentRelation> relations);
}

// ── Question ──────────────────────────────────────────────────────────────────
abstract class QuestionRepository {
  /// Core multi-dimensional query — MUST honour all non-null fields in [filter].
  Future<List<Question>> query(
    CurriculumFilter filter, {
    CurriculumSortOrder sort = CurriculumSortOrder.priorityDesc,
    int limit = 50,
    int offset = 0,
  });

  Future<Question?> getById(String id);
  Future<void> upsert(Question question);
  Future<void> upsertAll(List<Question> questions);
}

// ── QuestionOption ────────────────────────────────────────────────────────────
abstract class QuestionOptionRepository {
  Future<List<QuestionOption>> getByQuestion(String questionId);
  Future<void> upsert(QuestionOption option);
  Future<void> upsertAll(List<QuestionOption> options);
}

// ── StudentProgress ───────────────────────────────────────────────────────────
abstract class StudentProgressRepository {
  Future<StudentProgress> getOrCreate(String studentId);
  Future<void> saveProgress(StudentProgress progress);
  Future<void> recordAttempt(ExamAttempt attempt);
  Future<List<ExamAttempt>> getUnsyncedAttempts(String studentId);
  Future<void> markAttemptSynced(String attemptId);
  Future<void> updateChapterMastery(String studentId, ChapterMastery mastery);
  Future<void> toggleBookmark(String studentId, String itemId);
}
