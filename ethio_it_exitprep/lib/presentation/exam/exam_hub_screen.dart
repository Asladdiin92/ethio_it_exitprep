// lib/presentation/exam/exam_hub_screen.dart
// Main assessment hub: Timed National Mock Exam, Custom Practice Builder, and Past Attempts.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ethio_it_exitprep/core/providers/repository_providers.dart';
import 'package:ethio_it_exitprep/domain/entities/student_progress.dart';
import 'package:ethio_it_exitprep/presentation/exam/controllers/exam_session_controller.dart';

class ExamHubScreen extends ConsumerWidget {
  const ExamHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressRepo = ref.watch(studentProgressRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Simulator & Quizzes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. National Mock Simulator Hero Card
          Card(
            elevation: 3,
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.timer, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'National Mock Exam',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              'MoE Blueprint 100 Questions • 150 Mins',
                              style: TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Full timed simulation stratified across all 5 themes and 13 core IT courses. '
                    'Mirrors the official FDRE exit exam structure with countdown timer and instant scoring.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      await ref
                          .read(examSessionControllerProvider.notifier)
                          .startTimedNationalMock();
                      if (context.mounted) {
                        context.push('/exam/session');
                      }
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Launch Timed Simulation', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // 2. Custom Practice Builder Tile
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.tune, color: Colors.blue.shade700, size: 26),
              ),
              title: const Text('Custom Practice Drill', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Target specific courses, exam years (2015–2018 E.C.), and difficulty tiers.'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/exam/builder'),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Past Offline Exam Attempts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Attempts (Offline Store)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.offline_pin, size: 16, color: Colors.green),
            ],
          ),
          const SizedBox(height: 8),

          FutureBuilder<StudentProgress>(
            future: progressRepo.getOrCreate('LOCAL_STUDENT'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
              }
              final attempts = snapshot.data?.examAttempts ?? [];
              if (attempts.isEmpty) {
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('No exam attempts recorded yet. Launch your first mock drill above!'),
                    ),
                  ),
                );
              }

              return Column(
                children: attempts.reversed.take(5).map((a) {
                  final isPass = a.scorePercent >= 50.0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPass ? Colors.green.shade100 : Colors.red.shade100,
                        child: Text(
                          '${a.scorePercent.toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPass ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                      ),
                      title: Text(
                        '${a.correctAnswers}/${a.totalQuestions} Correct',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Completed: ${a.startedAt.month}/${a.startedAt.day} • ${a.syncedToCloud ? "Cloud Synced" : "Stored Offline"}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
