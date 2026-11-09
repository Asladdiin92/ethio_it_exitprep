// lib/presentation/exam/custom_quiz_builder_screen.dart
// Interactive Custom Practice Builder allowing students to filter questions
// by Course, Chapter, Exam Year (2015–2018 E.C.), Simplicity/Hardness, and Priority.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ethio_it_exitprep/core/constants/curriculum_constants.dart';
import 'package:ethio_it_exitprep/domain/entities/study_material.dart';
import 'package:ethio_it_exitprep/domain/repositories/curriculum_filter.dart';
import 'package:ethio_it_exitprep/presentation/exam/controllers/exam_session_controller.dart';

class CustomQuizBuilderScreen extends ConsumerStatefulWidget {
  const CustomQuizBuilderScreen({super.key});

  @override
  ConsumerState<CustomQuizBuilderScreen> createState() => _CustomQuizBuilderScreenState();
}

class _CustomQuizBuilderScreenState extends ConsumerState<CustomQuizBuilderScreen> {
  String? _selectedCourseId;
  int? _selectedYear;
  DifficultyTier? _selectedDifficulty;
  PriorityTier? _selectedPriority;
  int _questionCount = 15;
  bool _isTimed = true;
  int _durationMinutes = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Practice Drill'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildCourseSelector(),
          const SizedBox(height: 16),
          _buildYearSelector(),
          const SizedBox(height: 16),
          _buildDifficultySelector(),
          const SizedBox(height: 16),
          _buildPrioritySelector(),
          const SizedBox(height: 16),
          _buildQuestionCountSlider(),
          const SizedBox(height: 16),
          _buildTimerConfig(),
          const SizedBox(height: 28),
          _buildStartButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.tune, color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Multi-Dimensional Drill Builder',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Combine course, past national exam years, and difficulty tiers for focused revision.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Target Course', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          initialValue: _selectedCourseId,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('All 13 BSc IT Courses')),
            ...CurriculumConstants.courses.map((c) => DropdownMenuItem(
                  value: c['id'] as String,
                  child: Text('${c['code']} - ${c['title']}'),
                )),
          ],
          onChanged: (val) => setState(() => _selectedCourseId = val),
        ),
      ],
    );
  }

  Widget _buildYearSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('National Exam Year (E.C.)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Any Year'),
              selected: _selectedYear == null,
              onSelected: (_) => setState(() => _selectedYear = null),
            ),
            ...CurriculumConstants.examYears.map((yr) => FilterChip(
                  label: Text('$yr E.C.'),
                  selected: _selectedYear == yr,
                  onSelected: (sel) => setState(() => _selectedYear = sel ? yr : null),
                )),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Difficulty Tier', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SegmentedButton<DifficultyTier?>(
          segments: const [
            ButtonSegment(value: null, label: Text('All')),
            ButtonSegment(value: DifficultyTier.simple, label: Text('Simple (Tier 1)')),
            ButtonSegment(value: DifficultyTier.moderate, label: Text('Moderate (Tier 2)')),
            ButtonSegment(value: DifficultyTier.hard, label: Text('Hard (Tier 3)')),
          ],
          selected: {_selectedDifficulty},
          onSelectionChanged: (set) => setState(() => _selectedDifficulty = set.first),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Blueprint Priority', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('All Tiers'),
              selected: _selectedPriority == null,
              onSelected: (_) => setState(() => _selectedPriority = null),
            ),
            FilterChip(
              label: const Text('⚡ P1 Critical'),
              selected: _selectedPriority == PriorityTier.p1Critical,
              onSelected: (sel) => setState(() => _selectedPriority = sel ? PriorityTier.p1Critical : null),
            ),
            FilterChip(
              label: const Text('🔥 P2 High Yield'),
              selected: _selectedPriority == PriorityTier.p2HighYield,
              onSelected: (sel) => setState(() => _selectedPriority = sel ? PriorityTier.p2HighYield : null),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionCountSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Question Count', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('$_questionCount questions', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: _questionCount.toDouble(),
          min: 5,
          max: 50,
          divisions: 9,
          onChanged: (val) => setState(() => _questionCount = val.toInt()),
        ),
      ],
    );
  }

  Widget _buildTimerConfig() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Timed Practice Drill', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(_isTimed ? '$_durationMinutes minutes countdown' : 'Untimed self-paced practice'),
              value: _isTimed,
              onChanged: (val) => setState(() => _isTimed = val),
            ),
            if (_isTimed)
              Slider(
                value: _durationMinutes.toDouble(),
                min: 5,
                max: 60,
                divisions: 11,
                label: '$_durationMinutes min',
                onChanged: (val) => setState(() => _durationMinutes = val.toInt()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _startDrill,
      icon: const Icon(Icons.play_arrow),
      label: const Text('Start Practice Drill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  void _startDrill() async {
    final filter = CurriculumFilter(
      courseId: _selectedCourseId,
      examYear: _selectedYear,
      difficultyTier: _selectedDifficulty,
      priorityTier: _selectedPriority,
    );

    final title = _selectedCourseId != null
        ? 'Drill: $_selectedCourseId'
        : 'Curriculum Drill (${_selectedYear ?? "All Years"})';

    await ref.read(examSessionControllerProvider.notifier).startCustomDrill(
          title: title,
          filter: filter,
          questionLimit: _questionCount,
          durationMinutes: _isTimed ? _durationMinutes : null,
        );

    if (mounted) {
      context.push('/exam/session');
    }
  }
}
