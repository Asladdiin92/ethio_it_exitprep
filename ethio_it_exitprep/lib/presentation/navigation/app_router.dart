// lib/presentation/navigation/app_router.dart
// GoRouter navigation configuration for EthioIT ExitPrep.
// Supports hierarchical curriculum browsing, direct graph jumps, and smart queue routes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ethio_it_exitprep/core/providers/repository_providers.dart';
import 'package:ethio_it_exitprep/presentation/exam/exam_hub_screen.dart';
import 'package:ethio_it_exitprep/presentation/exam/custom_quiz_builder_screen.dart';
import 'package:ethio_it_exitprep/presentation/exam/mock_exam_simulator_screen.dart';
import 'package:ethio_it_exitprep/presentation/exam/exam_review_screen.dart';
import 'package:ethio_it_exitprep/presentation/analytics/readiness_dashboard_screen.dart';
import 'package:ethio_it_exitprep/presentation/study/study_material_reader.dart';
import 'package:ethio_it_exitprep/presentation/study/related_concepts_sheet.dart';

final appRouter = GoRouter(
  initialLocation: '/exam',
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/exam',
    ),
    GoRoute(
      path: '/study',
      name: 'study',
      builder: (context, state) => const _AppShellPlaceholder(
        title: 'Study Modules & Reading',
      ),
    ),
    GoRoute(
      path: '/study/material/:id',
      name: 'study-material',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return Consumer(
          builder: (ctx, ref, _) {
            final repo = ref.watch(studyMaterialRepositoryProvider);
            return FutureBuilder(
              future: repo.getById(id),
              builder: (c, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }
                final material = snap.data;
                if (material == null) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Not Found')),
                    body: Center(child: Text('Study material $id not found.')),
                  );
                }
                return StudyMaterialReader(
                  material: material,
                  onRelatedTap: () {
                    RelatedConceptsSheet.show(
                      ctx,
                      entityId: material.id,
                      entityTitle: material.title,
                      relationRepo: ref.read(contentRelationRepositoryProvider),
                      onNavigate: (type, targetId) {
                        if (type == 'material') {
                          context.push('/study/material/$targetId');
                        }
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/exam',
      name: 'exam-hub',
      builder: (context, state) => const ExamHubScreen(),
    ),
    GoRoute(
      path: '/exam/builder',
      name: 'exam-builder',
      builder: (context, state) => const CustomQuizBuilderScreen(),
    ),
    GoRoute(
      path: '/exam/session',
      name: 'exam-session',
      builder: (context, state) => const MockExamSimulatorScreen(),
    ),
    GoRoute(
      path: '/exam/review',
      name: 'exam-review',
      builder: (context, state) => const ExamReviewScreen(),
    ),
    GoRoute(
      path: '/analytics',
      name: 'analytics',
      builder: (context, state) => const ReadinessDashboardScreen(),
    ),
  ],
);

class _AppShellPlaceholder extends StatelessWidget {
  final String title;
  const _AppShellPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'EthioIT ExitPrep • Haramaya University BSc IT',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
