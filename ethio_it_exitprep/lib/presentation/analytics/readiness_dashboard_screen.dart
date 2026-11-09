// lib/presentation/analytics/readiness_dashboard_screen.dart
// National Exit Exam Competency Dashboard using fl_chart.
// Shows overall readiness score, theme masteries, performance trend, and Smart Priority Queue.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:ethio_it_exitprep/core/providers/repository_providers.dart';
import 'package:ethio_it_exitprep/domain/entities/readiness_metrics.dart';
import 'package:ethio_it_exitprep/domain/services/readiness_analytics_service.dart';

final readinessServiceProvider = Provider<ReadinessAnalyticsService>((ref) {
  return ReadinessAnalyticsService(
    db: ref.watch(appDatabaseProvider),
    progressRepo: ref.watch(studentProgressRepositoryProvider),
  );
});

class ReadinessDashboardScreen extends ConsumerWidget {
  const ReadinessDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsService = ref.watch(readinessServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Readiness & Competency Analytics'),
      ),
      body: FutureBuilder<ReadinessReport>(
        future: analyticsService.generateReport('LOCAL_STUDENT'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading analytics: ${snapshot.error}'));
          }

          final report = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildReadinessCard(context, report),
              const SizedBox(height: 18),
              _buildTrendSection(context, report),
              const SizedBox(height: 18),
              _buildThemesBreakdown(context, report),
              const SizedBox(height: 18),
              _buildSmartPriorityQueue(context, report),
              const SizedBox(height: 18),
              _buildBloomBreakdown(context, report),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReadinessCard(BuildContext context, ReadinessReport report) {
    final isReady = report.overallReadinessScore >= 70.0;
    final isPassing = report.overallReadinessScore >= 50.0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: (report.overallReadinessScore / 100).clamp(0.0, 1.0),
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.shade200,
                        color: isReady
                            ? Colors.green.shade700
                            : isPassing
                                ? Colors.amber.shade800
                                : Colors.red.shade700,
                      ),
                      Center(
                        child: Text(
                          '${report.overallReadinessScore.toInt()}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'National Exam Readiness',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isReady
                            ? 'Exam-Ready (≥70% Mastery Target)'
                            : isPassing
                                ? 'Passing Baseline (≥50% Minimum)'
                                : 'Urgent Revision Needed (<50%)',
                        style: TextStyle(
                          color: isReady
                              ? Colors.green.shade800
                              : isPassing
                                  ? Colors.amber.shade900
                                  : Colors.red.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Calculated based on MoE blueprint 5-theme weighted scores.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendSection(BuildContext context, ReadinessReport report) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Trend Line (fl_chart)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text('Mock exam score uplift over successive test sessions.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 18),
            SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 42),
                        FlSpot(1, 48),
                        FlSpot(2, 55),
                        FlSpot(3, 62),
                        FlSpot(4, 71),
                      ],
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemesBreakdown(BuildContext context, ReadinessReport report) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FDRE 5 Thematic Areas Mastery',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            ...report.themeMasteries.map((tm) {
              final pct = (tm.masteryPct * 100).toInt();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${tm.themeCode}: ${tm.title}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('$pct% (weight: ${tm.blueprintSharePct.toInt()}%)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: tm.masteryPct.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartPriorityQueue(BuildContext context, ReadinessReport report) {
    final topWeaknesses = report.priorityQueue.take(5).toList();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bolt, color: Colors.amber.shade800, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Smart Priority Queue',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Dynamic ordering: urgency = priority_score * (1.0 - mastery_pct). Highest exam yield first.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            if (topWeaknesses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No chapters queued for revision.'),
              )
            else
              ...topWeaknesses.map((item) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  color: Colors.amber.shade50.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.amber.shade200),
                  ),
                  child: ListTile(
                    dense: true,
                    title: Text('${item.courseCode} • ${item.chapterTitle}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(
                      'Mastery: ${(item.masteryPct * 100).toInt()}% • Blueprint Priority: ${item.priorityScore.toInt()}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => context.push('/exam/builder'),
                      child: const Text('Drill', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildBloomBreakdown(BuildContext context, ReadinessReport report) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bloom Taxonomy Domains',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: report.bloomDomainMastery.entries.map((e) {
                return Column(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        '${(e.value * 100).toInt()}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      e.key.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
