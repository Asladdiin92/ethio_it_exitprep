// lib/presentation/exam/exam_review_screen.dart
// Post-Exam Review Screen displaying per-option rationales, overall score breakdown,
// and one-tap "Jump to Source Concept Note" bidirectional navigation.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ethio_it_exitprep/core/providers/repository_providers.dart';
import 'package:ethio_it_exitprep/domain/entities/question_option.dart';
import 'package:ethio_it_exitprep/presentation/exam/controllers/exam_session_controller.dart';
import 'package:ethio_it_exitprep/presentation/study/related_concepts_sheet.dart';

class ExamReviewScreen extends ConsumerWidget {
  const ExamReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(examSessionControllerProvider);
    final isPass = session.scorePercent >= 50.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Results & Review'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/exam'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Score Summary Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    isPass ? Icons.stars : Icons.info_outline,
                    size: 48,
                    color: isPass ? Colors.green.shade600 : Colors.orange.shade700,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${session.scorePercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: isPass ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  Text(
                    isPass ? 'PASSED (National Benchmark ≥ 50%)' : 'NEEDS REVISION',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: isPass ? Colors.green.shade800 : Colors.red.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        label: 'Correct',
                        value: '${session.correctCount}',
                        color: Colors.green.shade700,
                      ),
                      _StatColumn(
                        label: 'Incorrect',
                        value: '${session.answeredCount - session.correctCount}',
                        color: Colors.red.shade700,
                      ),
                      _StatColumn(
                        label: 'Unanswered',
                        value: '${session.unansweredCount}',
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Detailed Question Analysis & Rationales',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 12),

          // Question by Question Review List
          ...List.generate(session.questions.length, (idx) {
            final item = session.questions[idx];
            final q = item.question;
            final userAns = session.selectedAnswers[q.id];
            final correctOpt = item.options.cast<QuestionOption?>().firstWhere(
                  (o) => o?.isCorrect == true,
                  orElse: () => null,
                );
            final isUserCorrect = userAns != null && correctOpt?.optionKey == userAns;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isUserCorrect ? Colors.green.shade200 : Colors.red.shade200,
                  width: 1.2,
                ),
              ),
              child: ExpansionTile(
                initiallyExpanded: !isUserCorrect, // Expand incorrect items by default
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: isUserCorrect ? Colors.green.shade100 : Colors.red.shade100,
                  child: Icon(
                    isUserCorrect ? Icons.check : Icons.close,
                    size: 16,
                    color: isUserCorrect ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
                title: Text(
                  'Q${idx + 1}: ${q.stemTitle.isNotEmpty ? q.stemTitle : q.title}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  userAns == null
                      ? 'Unanswered • Correct: ${correctOpt?.optionKey ?? "-"}'
                      : 'Your Answer: $userAns • Correct: ${correctOpt?.optionKey ?? "-"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isUserCorrect ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q.stemBody,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Option Rationales:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),

                        // Render options with per-option rationales
                        ...item.options.map((opt) {
                          final isThisCorrect = opt.isCorrect;
                          final isThisUserSelected = userAns == opt.optionKey;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isThisCorrect
                                  ? Colors.green.shade50
                                  : isThisUserSelected
                                      ? Colors.red.shade50
                                      : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isThisCorrect
                                    ? Colors.green.shade400
                                    : isThisUserSelected
                                        ? Colors.red.shade400
                                        : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${opt.optionKey}. ',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Expanded(child: Text(opt.optionText)),
                                    if (isThisCorrect)
                                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                    if (isThisUserSelected && !isThisCorrect)
                                      const Icon(Icons.cancel, size: 16, color: Colors.red),
                                  ],
                                ),
                                if (opt.optionRationale.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Rationale: ${opt.optionRationale}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isThisCorrect ? Colors.green.shade900 : Colors.black87,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),

                        if (q.generalExplanation.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.lightbulb_outline, size: 18, color: Colors.blue.shade800),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Concept Explanation: ${q.generalExplanation}',
                                    style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Bidirectional Navigation Action Buttons
                        Row(
                          children: [
                            if (q.linkedMaterialId != null && q.linkedMaterialId!.isNotEmpty)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    context.push('/study/material/${q.linkedMaterialId}');
                                  },
                                  icon: const Icon(Icons.menu_book, size: 16),
                                  label: const Text('Source Study Note', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  RelatedConceptsSheet.show(
                                    context,
                                    entityId: q.id,
                                    entityTitle: q.stemTitle,
                                    relationRepo: ref.read(contentRelationRepositoryProvider),
                                    onNavigate: (type, targetId) {
                                      if (type == 'material') {
                                        context.push('/study/material/$targetId');
                                      }
                                    },
                                  );
                                },
                                icon: const Icon(Icons.hub_outlined, size: 16),
                                label: const Text('Related Concepts', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
