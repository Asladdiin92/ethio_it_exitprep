import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethio_it_exitprep/core/providers/repository_providers.dart';
import 'package:ethio_it_exitprep/domain/entities/study_material.dart';
import 'package:ethio_it_exitprep/domain/repositories/curriculum_filter.dart';

class CourseReadingMaterialScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseReadingMaterialScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseReadingMaterialScreen> createState() => _CourseReadingMaterialScreenState();
}

class _CourseReadingMaterialScreenState extends ConsumerState<CourseReadingMaterialScreen> {
  bool _showFlashcards = false;
  bool _bookmarked = false;
  int _flashcardIndex = 0;
  bool _flashcardRevealed = false;

  String get _courseTitle => {
        'C01': 'Programming',
        'C04': 'Database Systems',
        'C07': 'Networking & Security',
        'C09': 'System Administration',
        'C10': 'Web & Mobile Development',
      }[widget.courseId] ?? 'Course reading material';

  (int, int) get _courseSchedule => {
        'C01': (2, 1),
        'C04': (2, 2),
        'C07': (3, 1),
        'C09': (3, 1),
        'C10': (3, 2),
      }[widget.courseId] ?? (1, 1);

  @override
  Widget build(BuildContext context) {
    final materialRepo = ref.watch(studyMaterialRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Course Reading Material', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            Text('Year ${_courseSchedule.$1}  •  Semester ${_courseSchedule.$2}  •  3 Credit Hrs', style: const TextStyle(fontSize: 11, color: Color(0xFF6C7A73))),
          ],
        ),
        actions: [
          const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.offline_bolt_rounded, size: 17, color: Color(0xFF0F7A51))),
          IconButton(
            tooltip: _bookmarked ? 'Remove bookmark' : 'Save bookmark',
            icon: Icon(_bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
            onPressed: () => setState(() => _bookmarked = !_bookmarked),
          ),
        ],
      ),
      body: FutureBuilder<List<StudyMaterial>>(
        future: materialRepo.query(CurriculumFilter(courseId: widget.courseId)),
        builder: (context, snapshot) {
          final materials = snapshot.data ?? const <StudyMaterial>[];
          final material = materials.isEmpty ? null : materials.first;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Row(
                children: [
                  const Icon(Icons.cloud_done_outlined, size: 15, color: Color(0xFF0F7A51)),
                  const SizedBox(width: 5),
                  Text('Offline Saved', style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(_showFlashcards ? 'Flashcard ${_flashcardIndex + 1} of 6' : 'Page 4 of 12', style: const TextStyle(fontSize: 11, color: Color(0xFF6C7A73))),
                ],
              ),
              const SizedBox(height: 10),
              _ModeToggle(showFlashcards: _showFlashcards, onChanged: (value) => setState(() => _showFlashcards = value)),
              const SizedBox(height: 18),
              if (_showFlashcards) _FlashcardPanel(index: _flashcardIndex, revealed: _flashcardRevealed, courseTitle: _courseTitle, onReveal: () => setState(() => _flashcardRevealed = !_flashcardRevealed), onNext: _nextFlashcard)
              else _NotesPanel(material: material, courseTitle: _courseTitle),
              const SizedBox(height: 18),
              ClipRRect(borderRadius: BorderRadius.circular(8), child: const LinearProgressIndicator(value: 0.34, minHeight: 6, color: Color(0xFF2C8C86), backgroundColor: Color(0xFFDCE8E1))),
              const SizedBox(height: 7),
              Row(children: [
                const Text('Keep going, you are building momentum.', style: TextStyle(fontSize: 11, color: Color(0xFF6C7A73))),
                const Spacer(),
                Text(_showFlashcards ? '6 cards' : 'Page 4 of 12', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2C8C86))),
              ]),
              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => context.push('/exam/builder'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Topic Quiz', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F6B58), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) context.go('/exam');
          if (index == 2) context.go('/exam/session');
          if (index == 3) context.go('/analytics');
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

  void _nextFlashcard() {
    setState(() {
      _flashcardIndex = (_flashcardIndex + 1) % 6;
      _flashcardRevealed = false;
    });
  }
}

class _ModeToggle extends StatelessWidget {
  final bool showFlashcards;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({required this.showFlashcards, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 43,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFE4ECE8), borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        Expanded(child: _ModeButton(label: 'Reading Notes', selected: !showFlashcards, onTap: () => onChanged(false))),
        Expanded(child: _ModeButton(label: 'Flashcards', selected: showFlashcards, onTap: () => onChanged(true))),
      ]),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: selected ? const Color(0xFF2C8C86) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: selected ? Colors.white : const Color(0xFF52625A))),
      ),
    );
  }
}

class _NotesPanel extends StatelessWidget {
  final StudyMaterial? material;
  final String courseTitle;

  const _NotesPanel({required this.material, required this.courseTitle});

  @override
  Widget build(BuildContext context) {
    final blocks = material?.contentBlocks ?? const <Map<String, dynamic>>[];
    final content = blocks.isEmpty ? _fallbackBlocks(courseTitle) : blocks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('1. ER Modeling & Normalization (1NF–3NF)', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        const Text('Database Systems', style: TextStyle(fontSize: 12, color: Color(0xFF6C7A73), fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        ...content.map((block) {
          final type = block['type'] as String? ?? 'text';
          final text = block['text'] as String? ?? '';
          if (type == 'heading') return Padding(padding: const EdgeInsets.only(top: 5, bottom: 8), child: Text(text, style: Theme.of(context).textTheme.titleMedium));
          if (type == 'bullet') {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(color: Color(0xFF2C8C86), fontWeight: FontWeight.w800)),
                  Expanded(child: _LeadInText(text: text, leadIn: block['leadIn'] as String?)),
                ],
              ),
            );
          }
          if (type == 'code') return _CodeBlock(text: text);
          if (type == 'callout') return _Takeaway(text: text);
          return Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(text, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF35443C))));
        }),
      ],
    );
  }

  static List<Map<String, dynamic>> _fallbackBlocks(String courseTitle) {
    if (courseTitle == 'Database Systems') {
      return const [
        {'type': 'bullet', 'text': '**Primary Keys** uniquely identify a record and protect Entity Integrity.'},
        {'type': 'bullet', 'text': '**Third Normal Form (3NF)** requires a relation to be in 2NF and have no transitive functional dependencies.'},
        {'type': 'callout', 'text': 'Exit Exam Key Takeaway: Ensure transitive dependencies are removed when normalization progresses to 3NF.'},
        {'type': 'code', 'text': 'CREATE TABLE Students (\n  id INT PRIMARY KEY,\n  full_name VARCHAR(120) NOT NULL\n);'},
      ];
    }
    return const [
      {'type': 'bullet', 'text': 'Review the core definitions and vocabulary for this course.'},
      {'type': 'bullet', 'text': 'Connect each concept to a worked example before attempting questions.'},
      {'type': 'callout', 'text': 'Exit Exam Key Takeaway: Focus on high-yield definitions, diagrams, and applied reasoning.'},
    ];
  }
}

class _Takeaway extends StatelessWidget {
  final String text;
  const _Takeaway({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(14)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.lightbulb_outline_rounded, size: 18, color: Color(0xFF167267)), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF174E47), fontWeight: FontWeight.w700)))]),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String text;
  const _CodeBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.5, color: Color(0xFFD4F7E5))),
    );
  }
}

class _LeadInText extends StatelessWidget {
  final String text;
  final String? leadIn;

  const _LeadInText({required this.text, this.leadIn});

  @override
  Widget build(BuildContext context) {
    final match = RegExp(r'^\*\*(.+?)\*\*(.*)$').firstMatch(text);
    if (leadIn != null && leadIn!.isNotEmpty && text.startsWith(leadIn!)) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: leadIn, style: const TextStyle(fontWeight: FontWeight.w800)),
            TextSpan(text: text.substring(leadIn!.length)),
          ],
          style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF35443C)),
        ),
      );
    }
    if (match == null) {
      return Text(text, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF35443C)));
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: match.group(1), style: const TextStyle(fontWeight: FontWeight.w800)),
          TextSpan(text: match.group(2)),
        ],
        style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF35443C)),
      ),
    );
  }
}

class _FlashcardPanel extends StatelessWidget {
  final int index;
  final bool revealed;
  final String courseTitle;
  final VoidCallback onReveal;
  final VoidCallback onNext;

  const _FlashcardPanel({required this.index, required this.revealed, required this.courseTitle, required this.onReveal, required this.onNext});

  @override
  Widget build(BuildContext context) {
    const prompts = ['What is the highest-yield concept in this chapter?', 'Which rule should you check before submitting an answer?', 'What is the practical example to remember?', 'Which term is most likely to appear in an exam stem?', 'What mistake should you avoid?', 'How would you explain this concept in one sentence?'];
    return Column(children: [
      Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 265),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFF0F5132), borderRadius: BorderRadius.circular(22)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('CARD ${index + 1}', style: const TextStyle(color: Color(0xFFF6C453), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 22),
          Text(revealed ? 'Review the worked example and explain why it is correct.' : prompts[index], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 21, height: 1.25, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          Text(revealed ? '$courseTitle  •  Answer revealed' : 'Tap to reveal answer', style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 12)),
        ]),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: onReveal, child: Text(revealed ? 'Hide answer' : 'Reveal answer'))),
        const SizedBox(width: 10),
        Expanded(child: FilledButton(onPressed: onNext, child: const Text('Next card'))),
      ]),
    ]);
  }
}
