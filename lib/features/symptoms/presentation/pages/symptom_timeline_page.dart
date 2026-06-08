import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:drug/core/router/app_routes.dart';
import 'package:drug/features/profiles/presentation/cubit/active_profile_cubit.dart';
import 'package:drug/features/symptoms/domain/entities/symptom_entry.dart';
import 'package:drug/features/symptoms/presentation/cubit/symptom_cubit.dart';

class SymptomTimelinePage extends StatefulWidget {
  const SymptomTimelinePage({super.key});

  @override
  State<SymptomTimelinePage> createState() => _SymptomTimelinePageState();
}

class _SymptomTimelinePageState extends State<SymptomTimelinePage> {
  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  void _loadInitial() {
    final activeState = context.read<ActiveProfileCubit>().state;
    if (activeState is ActiveProfileSelected) {
      context.read<SymptomCubit>().startWatching(activeState.profile.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ActiveProfileCubit, ActiveProfileState>(
      listener: (context, activeState) {
        if (activeState is ActiveProfileSelected) {
          context.read<SymptomCubit>().startWatching(activeState.profile.id);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Health Diary & Symptoms'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push(AppRoutes.symptomForm),
          child: const Icon(Icons.add_moderator_outlined),
        ),
        body: BlocBuilder<SymptomCubit, SymptomState>(
          builder: (context, state) {
            return switch (state) {
              SymptomInitial() || SymptomLoading() =>
                const Center(child: CircularProgressIndicator()),
              SymptomError(:final failure) =>
                Center(child: Text('Error: ${failure.message}')),
              SymptomLoaded(:final symptoms) =>
                _buildContent(context, symptoms),
            };
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<SymptomEntry> symptoms) {
    if (symptoms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.health_and_safety_outlined,
                size: 72,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Diary is empty',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Log daily symptoms, side-effects, or wellness notes to help track progress.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.symptomForm),
                icon: const Icon(Icons.add),
                label: const Text('Add Entry'),
              ),
            ],
          ),
        ),
      );
    }

    final mildCount = symptoms.where((s) => s.severity == SymptomSeverity.mild).length;
    final modCount = symptoms.where((s) => s.severity == SymptomSeverity.moderate).length;
    final sevCount = symptoms.where((s) => s.severity == SymptomSeverity.severe).length;

    return CustomScrollView(
      slivers: [
        // ── Summary Header cards ──
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                _SeveritySummaryCard(
                  label: 'Mild',
                  count: mildCount,
                  color: Colors.teal,
                ),
                const SizedBox(width: 8),
                _SeveritySummaryCard(
                  label: 'Moderate',
                  count: modCount,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _SeveritySummaryCard(
                  label: 'Severe',
                  count: sevCount,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),

        // ── List of timeline entries ──
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 88),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = symptoms[index];
                return _SymptomCard(
                  entry: entry,
                  onDelete: () => _confirmDelete(context, entry.id),
                );
              },
              childCount: symptoms.length,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Log'),
        content: const Text('Are you sure you want to delete this symptom log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SymptomCubit>().removeEntry(id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SeveritySummaryCard extends StatelessWidget {
  const _SeveritySummaryCard({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final MaterialColor color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color.shade50,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SymptomCard extends StatelessWidget {
  const _SymptomCard({
    required this.entry,
    required this.onDelete,
  });

  final SymptomEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (entry.severity) {
      SymptomSeverity.mild => Colors.teal,
      SymptomSeverity.moderate => Colors.orange,
      SymptomSeverity.severe => Colors.red,
    };
    final severityLabel = switch (entry.severity) {
      SymptomSeverity.mild => 'Mild',
      SymptomSeverity.moderate => 'Moderate',
      SymptomSeverity.severe => 'Severe',
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.shade200),
                  ),
                  child: Text(
                    severityLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color.shade800,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(entry.occurredAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              entry.notes,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            if (entry.relatedMedicationName != null) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.medication_outlined, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Related to: ${entry.relatedMedicationName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
