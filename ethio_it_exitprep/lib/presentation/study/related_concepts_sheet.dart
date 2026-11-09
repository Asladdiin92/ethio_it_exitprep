// lib/presentation/study/related_concepts_sheet.dart
// Bidirectional ContentRelation graph navigation widget.
// Renders prerequisites, related concepts, and linked exam questions.

import 'package:flutter/material.dart';
import 'package:ethio_it_exitprep/domain/entities/content_relation.dart';
import 'package:ethio_it_exitprep/domain/repositories/curriculum_repository.dart';

class RelatedConceptsSheet extends StatelessWidget {
  final String entityId;
  final String entityTitle;
  final ContentRelationRepository relationRepo;
  final void Function(String targetType, String targetId)? onNavigate;

  const RelatedConceptsSheet({
    super.key,
    required this.entityId,
    required this.entityTitle,
    required this.relationRepo,
    this.onNavigate,
  });

  static Future<void> show(
    BuildContext context, {
    required String entityId,
    required String entityTitle,
    required ContentRelationRepository relationRepo,
    void Function(String targetType, String targetId)? onNavigate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        expand: false,
        builder: (c, scrollCtrl) => RelatedConceptsSheet(
          entityId: entityId,
          entityTitle: entityTitle,
          relationRepo: relationRepo,
          onNavigate: onNavigate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ContentRelation>>(
      future: relationRepo.getRelationsFrom(entityId),
      builder: (context, snapshot) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.hub_outlined, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Concept Graph: $entityTitle',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshot.hasError)
              Expanded(
                child: Center(child: Text('Error loading relations: ${snapshot.error}')),
              )
            else if (!snapshot.hasData || snapshot.data!.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No connected prerequisites or related concepts found.'),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final rel = snapshot.data![i];
                    final (icon, label, color) = _relationMetadata(rel.relationType);
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: color.withValues(alpha: 0.4)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(
                          '${rel.targetType.toUpperCase()} ID: ${rel.targetId} (weight: ${(rel.relevanceWeight * 100).toInt()}%)',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate?.call(rel.targetType, rel.targetId);
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  (IconData, String, Color) _relationMetadata(RelationType type) {
    switch (type) {
      case RelationType.prerequisiteOf:
        return (Icons.school_outlined, 'Prerequisite Topic', Colors.deepOrange);
      case RelationType.relatedConcept:
        return (Icons.compare_arrows, 'Related Concept', Colors.blue);
      case RelationType.testedByQuestion:
        return (Icons.quiz_outlined, 'Tested By Question', Colors.teal);
      case RelationType.explainsAnswerFor:
        return (Icons.lightbulb_outline, 'Explains Answer For', Colors.amber.shade800);
    }
  }
}
