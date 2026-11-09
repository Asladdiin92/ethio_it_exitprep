// lib/presentation/exam/mock_exam_simulator_screen.dart
// Timed National Mock Exam Simulator mirroring official FDRE exit exam parameters.
// Includes countdown timer, question palette navigator, flagging, and instant review flow.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ethio_it_exitprep/domain/entities/study_material.dart';
import 'package:ethio_it_exitprep/presentation/exam/controllers/exam_session_controller.dart';

class MockExamSimulatorScreen extends ConsumerWidget {
  const MockExamSimulatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(examSessionControllerProvider);
    final controller = ref.read(examSessionControllerProvider.notifier);

    if (session.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam Simulator')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('No questions loaded in this session.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Return to Exam Hub'),
              ),
            ],
          ),
        ),
      );
    }

    final currentItem = session.questions[session.currentIndex];
    final currentQ = currentItem.question;
    final selectedKey = session.currentSelectedAnswer;
    final isFlagged = session.isCurrentFlagged;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _showExitConfirmDialog(context);
        if (leave == true && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            session.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          actions: [
            if (session.isTimedMock) _TimerBadge(remainingSeconds: session.remainingSeconds),
            IconButton(
              icon: Icon(
                isFlagged ? Icons.flag : Icons.flag_outlined,
                color: isFlagged ? Colors.amber.shade800 : null,
              ),
              tooltip: isFlagged ? 'Remove flag' : 'Flag for review',
              onPressed: controller.toggleFlagCurrent,
            ),
            IconButton(
              icon: const Icon(Icons.grid_view),
              tooltip: 'Question Palette',
              onPressed: () => _showPaletteSheet(context, ref),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (session.currentIndex + 1) / session.totalQuestions,
              minHeight: 5,
              color: const Color(0xFF0F7A51),
              backgroundColor: const Color(0xFFDCE8E1),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Question Meta Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${session.currentIndex + 1} of ${session.totalQuestions}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          _BadgeChip(
                            label: '${currentQ.examYear} E.C.',
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 6),
                          _BadgeChip(
                            label: 'Tier ${currentQ.difficultyTier.level}',
                            color: currentQ.difficultyTier.level == 1
                                ? Colors.green
                                : currentQ.difficultyTier.level == 2
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Question Stem Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Color(0xFFDDE7E1)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (currentQ.stemTitle.isNotEmpty)
                            Text(
                              currentQ.stemTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            currentQ.stemBody,
                            style: const TextStyle(fontSize: 15, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Options A–D
                  ...currentItem.options.map((opt) {
                    final isSelected = selectedKey == opt.optionKey;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => controller.selectAnswer(opt.optionKey),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade200,
                                child: Text(
                                  opt.optionKey,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  opt.optionText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: session.currentIndex > 0 ? controller.previousQuestion : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Prev'),
                ),
                Text(
                  '${session.answeredCount}/${session.totalQuestions} Answered',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (session.currentIndex < session.totalQuestions - 1)
                  ElevatedButton.icon(
                    onPressed: controller.nextQuestion,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _confirmSubmit(context, ref),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Finish Exam'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPaletteSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final session = ref.watch(examSessionControllerProvider);
        final controller = ref.read(examSessionControllerProvider.notifier);

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (c, scrollCtrl) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Question Palette',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmSubmit(context, ref);
                      },
                      child: const Text('Submit Now', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _PaletteLegend(color: Colors.green, label: 'Answered (${session.answeredCount})'),
                    const SizedBox(width: 12),
                    _PaletteLegend(color: Colors.grey.shade300, label: 'Unanswered (${session.unansweredCount})'),
                    const SizedBox(width: 12),
                    _PaletteLegend(color: Colors.amber.shade800, label: 'Flagged (${session.flaggedCount})'),
                  ],
                ),
                const Divider(height: 24),
                Expanded(
                  child: GridView.builder(
                    controller: scrollCtrl,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: session.totalQuestions,
                    itemBuilder: (ctx, idx) {
                      final qItem = session.questions[idx];
                      final isAnswered = session.selectedAnswers.containsKey(qItem.question.id);
                      final isFlagged = session.flaggedQuestionIds.contains(qItem.question.id);
                      final isCurrent = session.currentIndex == idx;

                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          controller.goToQuestion(idx);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isAnswered ? Colors.green.shade600 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCurrent
                                  ? Theme.of(context).colorScheme.primary
                                  : isFlagged
                                      ? Colors.amber.shade800
                                      : Colors.grey.shade300,
                              width: isCurrent || isFlagged ? 2 : 1,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                '${idx + 1}',
                                style: TextStyle(
                                  color: isAnswered ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              if (isFlagged)
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Icon(Icons.flag, size: 10, color: Colors.amber.shade800),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmSubmit(BuildContext context, WidgetRef ref) {
    final session = ref.read(examSessionControllerProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Exam?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You have answered ${session.answeredCount} of ${session.totalQuestions} questions.'),
            if (session.unansweredCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '⚠️ Warning: ${session.unansweredCount} questions are still unanswered and will be marked incorrect.',
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            if (session.flaggedCount > 0) ...[
              const SizedBox(height: 6),
              Text(
                '🚩 You have ${session.flaggedCount} flagged questions for review.',
                style: const TextStyle(color: Colors.amber, fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Working'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(examSessionControllerProvider.notifier).submitExam();
              if (context.mounted) {
                context.pushReplacement('/exam/review');
              }
            },
            child: const Text('Confirm & Submit'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showExitConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Exam Session?'),
        content: const Text('Your current progress will not be saved as completed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  final int remainingSeconds;
  const _TimerBadge({required this.remainingSeconds});

  @override
  Widget build(BuildContext context) {
    final hours = remainingSeconds ~/ 3600;
    final mins = (remainingSeconds % 3600) ~/ 60;
    final secs = remainingSeconds % 60;
    final isUrgent = remainingSeconds < 300; // < 5 mins

    final timeStr = hours > 0
        ? '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}'
        : '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUrgent ? Colors.red : Colors.green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 14, color: isUrgent ? Colors.red : Colors.green.shade800),
          const SizedBox(width: 4),
          Text(
            timeStr,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isUrgent ? Colors.red : Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;
  final Color color;
  const _BadgeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _PaletteLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _PaletteLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
