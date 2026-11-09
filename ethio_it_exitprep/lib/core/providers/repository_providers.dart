// lib/core/providers/repository_providers.dart
// Riverpod providers for all repositories — wires AppDatabase to concrete impls.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:ethio_it_exitprep/data/local/database.dart';
import 'package:ethio_it_exitprep/data/repositories/local_simple_repositories.dart';
import 'package:ethio_it_exitprep/data/repositories/local_study_material_repository.dart';
import 'package:ethio_it_exitprep/data/repositories/local_question_repository.dart';
import 'package:ethio_it_exitprep/data/remote/sync_api.dart';
import 'package:ethio_it_exitprep/data/remote/sync_service.dart';
import 'package:ethio_it_exitprep/domain/repositories/curriculum_repository.dart';

// ── Database Provider ─────────────────────────────────────────────────────────
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'Initialize via ProviderScope override after AppDatabase.getInstance()',
  );
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

final studyMaterialRepositoryProvider = Provider<StudyMaterialRepository>((
  ref,
) {
  return LocalStudyMaterialRepository(ref.watch(appDatabaseProvider));
});

final contentRelationRepositoryProvider = Provider<ContentRelationRepository>((
  ref,
) {
  return LocalContentRelationRepository(ref.watch(appDatabaseProvider));
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return LocalQuestionRepository(ref.watch(appDatabaseProvider));
});

final questionOptionRepositoryProvider = Provider<QuestionOptionRepository>((
  ref,
) {
  return LocalQuestionOptionRepository(ref.watch(appDatabaseProvider));
});

final studentProgressRepositoryProvider = Provider<StudentProgressRepository>((
  ref,
) {
  return LocalStudentProgressRepository(ref.watch(appDatabaseProvider));
});

const _configuredSyncToken = String.fromEnvironment('SYNC_AUTH_TOKEN');
const _configuredSyncBaseUrl = String.fromEnvironment('SYNC_API_BASE_URL');

final syncAuthTokenProvider = Provider<String?>((ref) {
  if (_configuredSyncToken.isEmpty) return null;
  return _configuredSyncToken;
});

final syncApiBaseUrlProvider = Provider<String>((ref) {
  if (_configuredSyncBaseUrl.isNotEmpty) return _configuredSyncBaseUrl;
  if (!kDebugMode) return 'https://api.exitprep.haramaya.edu.et/api/v1';

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'http://10.0.2.2:4000/api/v1',
    TargetPlatform.iOS => 'http://127.0.0.1:4000/api/v1',
    _ => 'http://127.0.0.1:4000/api/v1',
  };
});

final syncEnabledProvider = Provider<bool>((ref) {
  return kDebugMode || (ref.watch(syncAuthTokenProvider)?.isNotEmpty ?? false);
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    apiClient: SyncApiClient(
      baseUrl: ref.watch(syncApiBaseUrlProvider),
      authTokenProvider: () => ref.read(syncAuthTokenProvider),
    ),
    themeRepo: ref.watch(programThemeRepositoryProvider),
    courseRepo: ref.watch(courseRepositoryProvider),
    chapterRepo: ref.watch(chapterRepositoryProvider),
    materialRepo: ref.watch(studyMaterialRepositoryProvider),
    questionRepo: ref.watch(questionRepositoryProvider),
    questionOptionRepo: ref.watch(questionOptionRepositoryProvider),
    progressRepo: ref.watch(studentProgressRepositoryProvider),
  );
});
