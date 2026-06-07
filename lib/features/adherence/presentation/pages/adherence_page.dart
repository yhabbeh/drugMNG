import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:drug/features/adherence/domain/entities/adherence_range.dart';
import 'package:drug/features/adherence/domain/entities/adherence_summary.dart';
import 'package:drug/features/adherence/presentation/bloc/adherence_bloc.dart';
import 'package:drug/features/adherence/presentation/bloc/adherence_event.dart';
import 'package:drug/features/adherence/presentation/bloc/adherence_state.dart';
import 'package:drug/features/adherence/presentation/pages/widgets/adherence_bar_chart.dart';
import 'package:drug/features/adherence/presentation/pages/widgets/adherence_summary_card.dart';
import 'package:drug/features/adherence/presentation/pages/widgets/missed_dose_tile.dart';
import 'package:drug/features/adherence/presentation/pages/widgets/range_selector.dart';
import 'package:drug/features/profiles/presentation/cubit/active_profile_cubit.dart';

class AdherencePage extends StatefulWidget {
  const AdherencePage({super.key});

  @override
  State<AdherencePage> createState() => _AdherencePageState();
}

class _AdherencePageState extends State<AdherencePage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  void _bootstrap() {
    final state = context.read<ActiveProfileCubit>().state;
    if (state is ActiveProfileSelected) {
      context.read<AdherenceBloc>().add(AdherenceStarted(profileId: state.profile.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adherence'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                context.read<AdherenceBloc>().add(const AdherenceRefreshed()),
          ),
        ],
      ),
      body: BlocListener<ActiveProfileCubit, ActiveProfileState>(
        listener: (context, state) {
          if (state is ActiveProfileSelected) {
            context
                .read<AdherenceBloc>()
                .add(AdherenceStarted(profileId: state.profile.id));
          }
        },
        child: BlocBuilder<AdherenceBloc, AdherenceState>(
          builder: (context, state) {
            if (state is AdherenceInitial || state is AdherenceLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AdherenceError) {
              return _ErrorView(message: state.message, range: state.range);
            }
            if (state is AdherenceLoaded) {
              return _LoadedView(
                range: state.range,
                summary: state.summary,
                missed: state.missedDoses,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.range,
    required this.summary,
    required this.missed,
  });

  final AdherenceRange range;
  final AdherenceSummary summary;
  final List missed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final end = DateTime.now();
    final start = end.subtract(Duration(days: range.days - 1));
    final dateRangeStr =
        '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d').format(end)}';

    final recentMissed = missed.take(10).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AdherenceRangeSelector(current: range),
        const SizedBox(height: 12),
        Center(
          child: Text(
            dateRangeStr,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AdherenceSummaryCard(
                icon: Icons.check_circle_outline,
                label: 'Adherence',
                value: '${summary.adherencePercent.toStringAsFixed(0)}%',
                color: summary.adherencePercent >= 80
                    ? Colors.green.shade600
                    : summary.adherencePercent >= 50
                        ? Colors.orange.shade600
                        : Colors.red.shade600,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AdherenceSummaryCard(
                icon: Icons.local_fire_department_outlined,
                label: 'Day Streak',
                value: '${summary.streakDays}',
                color: summary.streakDays > 0
                    ? Colors.deepOrange.shade600
                    : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AdherenceSummaryCard(
                icon: Icons.event_busy_outlined,
                label: 'Missed\nDoses',
                value: '${summary.missed}',
                color: summary.missed > 0
                    ? Colors.red.shade600
                    : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Doses Taken',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                AdherenceBarChart(points: summary.dailyPoints),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendDot(color: cs.primary, label: 'Taken'),
                    const SizedBox(width: 12),
                    _LegendDot(color: cs.error, label: 'Has Missed'),
                    const SizedBox(width: 12),
                    _LegendDot(
                        color: cs.surfaceContainerHighest, label: 'No Doses'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              'Missed Doses',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${missed.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (missed.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: cs.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'No missed doses in this period',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          )
        else ...[
          ...recentMissed.map((d) => MissedDoseTile(dose: d)),
          if (missed.length > 10)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  '+ ${missed.length - 10} more',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ),
            ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.range});

  final String message;
  final AdherenceRange range;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context
                  .read<AdherenceBloc>()
                  .add(const AdherenceRefreshed()),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
