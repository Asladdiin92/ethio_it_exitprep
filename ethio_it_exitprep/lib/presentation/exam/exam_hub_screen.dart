// Main assessment hub with the compact study dashboard experience.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ethio_it_exitprep/core/providers/repository_providers.dart';
import 'package:ethio_it_exitprep/domain/entities/student_progress.dart';
import 'package:ethio_it_exitprep/presentation/exam/controllers/exam_session_controller.dart';

class ExamHubScreen extends ConsumerWidget {
  const ExamHubScreen({super.key});

  Future<void> _startMock(BuildContext context, WidgetRef ref) async {
    await ref.read(examSessionControllerProvider.notifier).startTimedNationalMock();
    if (context.mounted) context.push('/exam/session');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressRepo = ref.watch(studentProgressRepositoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EthioIT ExitPrep', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            SizedBox(height: 2),
            Text('Your exam, your pace', style: TextStyle(fontSize: 11, color: Color(0xFF6C7A73))),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFDDF2E9), borderRadius: BorderRadius.circular(20)),
            child: const Row(
              children: [
                Icon(Icons.cloud_done_outlined, size: 14, color: Color(0xFF0F7A51)),
                SizedBox(width: 5),
                Text('Offline ready', style: TextStyle(fontSize: 11, color: Color(0xFF0F6645), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sync curriculum and attempts',
            icon: const Icon(Icons.sync),
            onPressed: () async {
              final token = ref.read(syncAuthTokenProvider);
              if (token == null || token.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cloud sync is not configured for this account.')));
                return;
              }
              final success = await ref.read(syncServiceProvider).runSyncCycle('LOCAL_STUDENT');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Sync completed.' : 'Sync incomplete; unsent data was retained.')));
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('Good morning, learner', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text('Build confidence one focused session at a time.', style: TextStyle(color: Color(0xFF69766F))),
          const SizedBox(height: 18),
          _ReadinessHero(onStart: () => _startMock(context, ref)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Continue learning', style: theme.textTheme.titleLarge),
              TextButton(onPressed: () => context.push('/study'), child: const Text('View all')),
            ],
          ),
          const SizedBox(height: 10),
          _CourseProgressTile(courseId: 'C01', icon: Icons.code_rounded, title: 'Programming', subtitle: '12 Notes  •  60 Flashcards', progress: 0.72, color: const Color(0xFF0F7A51)),
          _CourseProgressTile(courseId: 'C04', icon: Icons.storage_rounded, title: 'Database Systems', subtitle: '10 Notes  •  45 Flashcards', progress: 0.51, color: const Color(0xFF2C8C86)),
          _CourseProgressTile(courseId: 'C10', icon: Icons.devices_rounded, title: 'Web & Mobile Development', subtitle: '10 Notes  •  50 Flashcards', progress: 0.38, color: const Color(0xFF3678A6)),
          _CourseProgressTile(courseId: 'C07', icon: Icons.account_tree_rounded, title: 'Networking & Security', subtitle: '13 Notes  •  65 Flashcards', progress: 0.64, color: const Color(0xFF9A6A20)),
          _CourseProgressTile(courseId: 'C09', icon: Icons.settings_suggest_rounded, title: 'System Administration', subtitle: '8 Notes  •  40 Flashcards', progress: 0.42, color: const Color(0xFF6D5A9B)),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const CircleAvatar(backgroundColor: Color(0xFFE4F0EC), child: Icon(Icons.tune_rounded, color: Color(0xFF0F5132))),
              title: const Text('Build a custom drill', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Choose course, year, and difficulty.', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => context.push('/exam/builder'),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent attempts', style: theme.textTheme.titleLarge),
              const Icon(Icons.offline_pin_rounded, size: 18, color: Color(0xFF0F7A51)),
            ],
          ),
          const SizedBox(height: 10),
          FutureBuilder<StudentProgress>(
            future: progressRepo.getOrCreate('LOCAL_STUDENT'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
              }
              final attempts = snapshot.data?.examAttempts ?? [];
              if (attempts.isEmpty) {
                return const Card(child: Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No attempts yet. Your first session belongs here.', textAlign: TextAlign.center))));
              }
              return Column(
                children: attempts.reversed.take(5).map((a) {
                  final isPass = a.scorePercent >= 50.0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPass ? const Color(0xFFDDF2E9) : const Color(0xFFFFE7D7),
                        child: Text('${a.scorePercent.toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isPass ? const Color(0xFF0F6645) : const Color(0xFF9B4A22))),
                      ),
                      title: Text('${a.correctAnswers}/${a.totalQuestions} correct', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text('${a.startedAt.month}/${a.startedAt.day}  •  ${a.syncedToCloud ? "Cloud synced" : "Stored offline"}', style: const TextStyle(fontSize: 12)),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) context.push('/study');
          if (index == 2) _startMock(context, ref);
          if (index == 3) context.push('/analytics');
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Modules'),
          NavigationDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer_rounded), label: 'Mock exam'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights_rounded), label: 'Analytics'),
        ],
      ),
    );
  }
}

class _ReadinessHero extends StatelessWidget {
  final VoidCallback onStart;

  const _ReadinessHero({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F5132),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x260F5132), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BSc IT Exit Exam', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('5 core themes  •  13 courses  •  45 credit hours', style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 12)),
                const SizedBox(height: 16),
                SizedBox(height: 38, child: FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF6C453), foregroundColor: const Color(0xFF24352B)), onPressed: onStart, child: const Text('Start a mock exam', style: TextStyle(fontWeight: FontWeight.w800)))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 76, height: 76, child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(value: 0.62, strokeWidth: 9, backgroundColor: Colors.white24, color: const Color(0xFFF6C453)),
            const Text('62%', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
          ])),
        ],
      ),
    );
  }
}

class _CourseProgressTile extends StatelessWidget {
  final String courseId;
  final IconData icon;
  final String title;
  final String subtitle;
  final double progress;
  final Color color;

  const _CourseProgressTile({required this.courseId, required this.icon, required this.title, required this.subtitle, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/study/course/$courseId'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, size: 20, color: color)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF718078))),
                const SizedBox(height: 8),
                ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: const Color(0xFFE6ECE8), color: color)),
              ])),
              const SizedBox(width: 12),
              Text('${(progress * 100).round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
