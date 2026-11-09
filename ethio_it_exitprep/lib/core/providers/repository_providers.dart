// lib/core/providers/repository_providers.dart
// Riverpod providers for all repositories — wires AppDatabase to concrete impls.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethio_it_exitprep/data/local/database.dart';
import 'package:ethio_it_exitprep/data/repositories/local_simple_repositories.dart';
import 'package:ethio_it_exitprep/data/repositories/local_study_material_repository.dart';
import 'package:ethio_it_exitprep/data/repositories/local_question_repository.dart';
import 'package:ethio_it_exitprep/data/remote/sync_api.dart';
import 'package:ethio_it_exitprep/data/remote/sync_service.dart';
import 'package:ethio_it_exitprep/domain/repositories/curriculum_repository.dart';

// ── Database Provider ─────────────────────────────────────────────────────────
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('Initialize via ProviderScope override after AppDatabase.getInstance()');
});

// ── Entity Repositories ───────────────────────────────────────────────────────
final programThemeRepositoryProvider = Provider<ProgramThemeRepository>((ref) {
  return LocalProgramThemeRepository(ref.watch(appDatabaseProvider));
});

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return LocalCourseRepository(ref.watch(appDatabaseProvider));
});

final chapterRepositoryProvider = Provider<ChapterRepository>((ref) {
  return LocalChapterRepository(ref.watch(appDatabaseProvider));
});

final studyMaterialRepositoryProvider = Provider<StudyMaterialRepository>((ref) {
  return LocalStudyMaterialRepository(ref.watch(appDatabaseProvider));
});

final contentRelationRepositoryProvider = Provider<ContentRelationRepository>((ref) {
  return LocalContentRelationRepository(ref.watch(appDatabaseProvider));
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return LocalQuestionRepository(ref.watch(appDatabaseProvider));
});

final questionOptionRepositoryProvider = Provider<QuestionOptionRepository>((ref) {
  return LocalQuestionOptionRepository(ref.watch(appDatabaseProvider));
});

final studentProgressRepositoryProvider = Provider<StudentProgressRepository>((ref) {
  return LocalStudentProgressRepository(ref.watch(appDatabaseProvider));
});

// Override this provider from the authenticated app shell; null keeps cloud sync disabled.
final syncAuthTokenProvider = Provider<String?>((ref) => null);

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    apiClient: SyncApiClient(
      authTokenProvider: () => ref.read(syncAuthTokenProvider),
    ),
    materialRepo: ref.watch(studyMaterialRepositoryProvider),
    questionRepo: ref.watch(questionRepositoryProvider),
    progressRepo: ref.watch(studentProgressRepositoryProvider),
  );
});
