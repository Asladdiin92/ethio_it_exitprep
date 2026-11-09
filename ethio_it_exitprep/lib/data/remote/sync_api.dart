// lib/data/remote/sync_api.dart
// Delta-Sync REST client for MongoDB Atlas API.
// Never exposes raw DB credentials; communicates solely via authenticated REST endpoints.

import 'dart:convert';
import 'package:http/http.dart' as http;

class SyncDeltaResponse {
  final DateTime serverTimestamp;
  final List<Map<String, dynamic>> updatedMaterials;
  final List<Map<String, dynamic>> updatedQuestions;
  final List<DeletedEntity> deletedEntities;

  const SyncDeltaResponse({
    required this.serverTimestamp,
    required this.updatedMaterials,
    required this.updatedQuestions,
    required this.deletedEntities,
  });

  factory SyncDeltaResponse.fromJson(Map<String, dynamic> json) => SyncDeltaResponse(
        serverTimestamp: DateTime.parse(json['serverTimestamp'] as String),
        updatedMaterials: List<Map<String, dynamic>>.from(json['updatedMaterials'] ?? []),
        updatedQuestions: List<Map<String, dynamic>>.from(json['updatedQuestions'] ?? []),
        deletedEntities: (json['deletedEntities'] ?? json['deletedIds'] ?? [])
            .map<DeletedEntity>((entry) => entry is String
                ? DeletedEntity(entityType: 'material', entityId: entry)
                : DeletedEntity.fromJson(Map<String, dynamic>.from(entry as Map)))
            .toList(),
      );
}

class DeletedEntity {
  final String entityType;
  final String entityId;

  const DeletedEntity({required this.entityType, required this.entityId});

  factory DeletedEntity.fromJson(Map<String, dynamic> json) => DeletedEntity(
        entityType: json['entityType'] as String,
        entityId: (json['entityId'] ?? json['id']) as String,
      );
}

class SyncPushResponse {
  final List<String> syncedAttemptIds;
  final List<Map<String, dynamic>> rejected;

  const SyncPushResponse({required this.syncedAttemptIds, required this.rejected});

  factory SyncPushResponse.fromJson(Map<String, dynamic> json) => SyncPushResponse(
        syncedAttemptIds: (json['results'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((result) => result['attemptId'] as String)
            .toList(),
        rejected: (json['rejected'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList(),
      );
}

class SyncApiClient {
  final String baseUrl;
  final http.Client _client;
  final String? Function()? authTokenProvider;

  SyncApiClient({
    this.baseUrl = 'https://api.exitprep.haramaya.edu.et/api/v1',
    http.Client? client,
    this.authTokenProvider,
  }) : _client = client ?? http.Client();

  Map<String, String> _headers() {
    final headers = {'Content-Type': 'application/json'};
    final token = authTokenProvider?.call();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Pull incremental changes since the watermark timestamp.
  Future<SyncDeltaResponse> pullDelta(DateTime since) async {
    final uri = Uri.parse('$baseUrl/sync/pull?since=${since.toIso8601String()}');
    final response = await _client.get(uri, headers: _headers());

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return SyncDeltaResponse.fromJson(json);
    } else {
      throw Exception('Delta pull failed: ${response.statusCode} - ${response.body}');
    }
  }

  /// Push local outbox mutations (exam attempts, progress logs) to MongoDB Atlas API.
  Future<SyncPushResponse> pushOutbox(List<Map<String, dynamic>> mutations) async {
    final uri = Uri.parse('$baseUrl/sync/push');
    final response = await _client.post(
      uri,
      headers: _headers(),
      body: jsonEncode({'mutations': mutations}),
    );

    if (response.statusCode != 200 && response.statusCode != 207) {
      throw Exception('Outbox push failed: ${response.statusCode} - ${response.body}');
    }
    return SyncPushResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
