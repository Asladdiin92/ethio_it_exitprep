// lib/presentation/study/study_material_reader.dart
// Multi-style study material reader widget.
// Supports: ConceptNote (Markdown), QuickSummary, CodeWalkthrough,
//           FormulaSheet, and Flashcard modes.

import 'package:flutter/material.dart';
import 'package:ethio_it_exitprep/domain/entities/study_material.dart';

/// Top-level reader that dispatches to the correct sub-widget based on contentStyle.
class StudyMaterialReader extends StatelessWidget {
  final StudyMaterial material;
  final VoidCallback? onRelatedTap;
  final VoidCallback? onBookmarkTap;
  final bool isBookmarked;

  const StudyMaterialReader({
    super.key,
    required this.material,
    this.onRelatedTap,
    this.onBookmarkTap,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          material.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          _DifficultyChip(tier: material.difficultyTier),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark',
            onPressed: onBookmarkTap,
          ),
        ],
      ),
      body: Column(
        children: [
          _PriorityBanner(tier: material.priorityTier),
          Expanded(child: _buildContent(context)),
          if (onRelatedTap != null) _RelatedConceptsButton(onTap: onRelatedTap!),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (material.contentStyle) {
      case ContentStyle.flashcard:
        return FlashcardWidget(material: material);
      case ContentStyle.codeWalkthrough:
        return _CodeWalkthroughReader(material: material);
      case ContentStyle.formulaSheet:
        return _FormulaSheetReader(material: material);
      case ContentStyle.quickSummary:
        return _QuickSummaryReader(material: material);
      case ContentStyle.conceptNote:
        return _ConceptNoteReader(material: material);
    }
  }
}

// ── Priority Banner ───────────────────────────────────────────────────────────
class _PriorityBanner extends StatelessWidget {
  final PriorityTier tier;
  const _PriorityBanner({required this.tier});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (tier) {
      PriorityTier.p1Critical      => (Colors.red.shade700, '⚡ P1 CRITICAL — High exam weight'),
      PriorityTier.p2HighYield     => (Colors.orange.shade700, '🔥 P2 HIGH YIELD'),
      PriorityTier.p3Supplementary => (Colors.grey.shade600, 'P3 Supplementary'),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: color.withValues(alpha: 0.12),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

// ── Difficulty Chip ───────────────────────────────────────────────────────────
class _DifficultyChip extends StatelessWidget {
  final DifficultyTier tier;
  const _DifficultyChip({required this.tier});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (tier) {
      DifficultyTier.simple   => ('Simple', Colors.green),
      DifficultyTier.moderate => ('Moderate', Colors.orange),
      DifficultyTier.hard     => ('Hard', Colors.red),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color, width: 1),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

// ── Related Concepts Button ───────────────────────────────────────────────────
class _RelatedConceptsButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RelatedConceptsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.account_tree_outlined, size: 18),
          label: const Text('Related Concepts & Questions'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
          ),
        ),
      ),
    );
  }
}

// ── ConceptNote Reader ────────────────────────────────────────────────────────
class _ConceptNoteReader extends StatelessWidget {
  final StudyMaterial material;
  const _ConceptNoteReader({required this.material});

  @override
  Widget build(BuildContext context) {
    final blocks = material.contentBlocks;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: blocks.isEmpty ? 1 : blocks.length,
      itemBuilder: (context, i) {
        if (blocks.isEmpty) {
          return Text(material.description ?? 'No content available.',
              style: Theme.of(context).textTheme.bodyMedium);
        }
        final block = blocks[i];
        final type = block['type'] as String? ?? 'text';
        final text = block['text'] as String? ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: type == 'heading'
              ? Text(text,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary))
              : Text(text, style: Theme.of(context).textTheme.bodyMedium),
        );
      },
    );
  }
}

// ── QuickSummary Reader ───────────────────────────────────────────────────────
class _QuickSummaryReader extends StatelessWidget {
  final StudyMaterial material;
  const _QuickSummaryReader({required this.material});

  @override
  Widget build(BuildContext context) {
    final points = material.contentBlocks
        .where((b) => b['type'] == 'bullet' || b['type'] == 'text')
        .map((b) => b['text'] as String? ?? '')
        .where((t) => t.isNotEmpty)
        .toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: points.length,
      itemBuilder: (ctx, i) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle_outline,
                size: 18, color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(points[i],
                style: Theme.of(ctx).textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

// ── CodeWalkthrough Reader ────────────────────────────────────────────────────
class _CodeWalkthroughReader extends StatelessWidget {
  final StudyMaterial material;
  const _CodeWalkthroughReader({required this.material});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: material.contentBlocks.length,
      itemBuilder: (ctx, i) {
        final block = material.contentBlocks[i];
        final type = block['type'] as String? ?? 'text';
        final text = block['text'] as String? ?? '';
        if (type == 'code') {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(text,
                style: const TextStyle(
                    fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 13)),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(text, style: Theme.of(ctx).textTheme.bodyMedium),
        );
      },
    );
  }
}

// ── FormulaSheet Reader ───────────────────────────────────────────────────────
class _FormulaSheetReader extends StatelessWidget {
  final StudyMaterial material;
  const _FormulaSheetReader({required this.material});

  @override
  Widget build(BuildContext context) {
    final formulas = material.contentBlocks
        .where((b) => (b['type'] as String?) == 'formula')
        .toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: formulas.length,
      itemBuilder: (ctx, i) {
        final f = formulas[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f['label'] as String? ?? '',
                    style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                        color: Theme.of(ctx).colorScheme.primary)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(f['text'] as String? ?? '',
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Flashcard Widget (interactive flip) ──────────────────────────────────────
class FlashcardWidget extends StatefulWidget {
  final StudyMaterial material;
  const FlashcardWidget({super.key, required this.material});

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget>
    with SingleTickerProviderStateMixin {
  bool _showFront = true;
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _anim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_showFront) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
    setState(() => _showFront = !_showFront);
  }

  @override
  Widget build(BuildContext context) {
    final blocks = widget.material.contentBlocks;
    final front = blocks.firstWhere(
        (b) => b['side'] == 'front',
        orElse: () => {'text': widget.material.title});
    final back = blocks.firstWhere(
        (b) => b['side'] == 'back',
        orElse: () => {'text': widget.material.description ?? 'No answer.'});

    return Center(
      child: GestureDetector(
        onTap: _flip,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (ctx, _) {
            final angle = _anim.value * 3.141592653589793;
            final showFrontSide = _anim.value < 0.5;
            return Transform(
              transform: Matrix4.rotationY(angle),
              alignment: Alignment.center,
              child: showFrontSide
                  ? _CardFace(
                      label: 'TERM',
                      text: front['text'] as String? ?? '',
                      color: Theme.of(ctx).colorScheme.primaryContainer,
                    )
                  : Transform(
                      transform: Matrix4.rotationY(3.141592653589793),
                      alignment: Alignment.center,
                      child: _CardFace(
                        label: 'DEFINITION',
                        text: back['text'] as String? ?? '',
                        color: Theme.of(ctx).colorScheme.secondaryContainer,
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  const _CardFace({required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 220,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: Colors.black.withValues(alpha: 0.12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(letterSpacing: 1.5, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          Text(text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          Text('Tap to flip', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
