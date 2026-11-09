// lib/data/remote/sync_service.dart
// Background synchronization orchestrator.
// Synchronizes local SQLite outbox with MongoDB Atlas REST API when online.

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ethio_it_exitprep/data/remote/sync_api.dart';
import 'package:ethio_it_exitprep/domain/entities/study_material.dart';
import 'package:ethio_it_exitprep/domain/entities/question.dart';
import 'package:ethio_it_exitprep/domain/repositories/curriculum_repository.dart';

class SyncService {
  final SyncApiClient apiClient;
  final Connectivity connectivity;
  final StudyMaterialRepository materialRepo;
  final QuestionRepository questionRepo;
  final StudentProgressRepository progressRepo;

  SyncService({
    required this.apiClient,
    Connectivity? connectivity,
    required this.materialRepo,
    required this.questionRepo,
    required this.progressRepo,
  }) : connectivity = connectivity ?? Connectivity();

  /// Execute an offline-first sync cycle:
  /// 1. Push local outbox mutations (exam attempts) to cloud.
  /// 2. Pull incremental curriculum updates and merge into local SQLite.
  Future<bool> runSyncCycle(String studentId, {DateTime? lastSyncTime}) async {
    // Check network connectivity first
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      // Offline: exit gracefully without throwing
      return false;
    }

    try {
      // 1. Upstream: Push unsynced exam attempts
      final unsyncedAttempts = await progressRepo.getUnsyncedAttempts(studentId);
      if (unsyncedAttempts.isNotEmpty) {
        final mutations = unsyncedAttempts.map((a) => {
              'entityType': 'exam_attempt',
              'attemptId': a.attemptId,
              'studentId': a.studentId,
              'scorePercent': a.scorePercent,
              'totalQuestions': a.totalQuestions,
              'correctAnswers': a.correctAnswers,
              'completedAt': a.completedAt?.toIso8601String(),
              'answerMap': a.answerMap,
            }).toList();

        final pushSuccess = await apiClient.pushOutbox(mutations);
        if (pushSuccess) {
          for (final a in unsyncedAttempts) {
            await progressRepo.markAttemptSynced(a.attemptId);
          }
        }
      }

      // 2. Downstream: Pull curriculum delta
      final watermark = lastSyncTime ?? DateTime(2025, 1, 1);
      final delta = await apiClient.pullDelta(watermark);

      // Merge updated study materials
      for (final mJson in delta.updatedMaterials) {
        final material = StudyMaterial.fromJson(mJson);
        await materialRepo.upsert(material);
      }

      // Merge updated questions
      for (final qJson in delta.updatedQuestions) {
        final question = Question.fromJson(qJson);
        await questionRepo.upsert(question);
      }

      // Remove deleted entities if any
      for (final id in delta.deletedIds) {
        await materialRepo.deleteById(id);
      }

      // Update student last_synced timestamp
      final currentProgress = await progressRepo.getOrCreate(studentId);
      await progressRepo.saveProgress(currentProgress.copyWith(
        lastSynced: delta.serverTimestamp,
      ));

      return true;
    } catch (_) {
      // Graceful error handling in case of connection drop
      return false;
    }
  }
}
