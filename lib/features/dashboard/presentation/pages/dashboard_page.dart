import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:drug/core/router/app_routes.dart';
import 'package:drug/features/adherence/presentation/bloc/adherence_bloc.dart';
import 'package:drug/features/adherence/presentation/bloc/adherence_event.dart';
import 'package:drug/features/adherence/presentation/bloc/adherence_state.dart';
import 'package:drug/features/inventory/domain/entities/expiration_warning.dart';
import 'package:drug/features/inventory/presentation/cubit/expiration_warning_cubit.dart';
import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';
import 'package:drug/features/profiles/presentation/cubit/active_profile_cubit.dart';
import 'package:drug/features/schedule/domain/entities/dose_log.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/entities/recurrence_rule.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';
import 'package:drug/features/schedule/presentation/bloc/schedule_bloc.dart';
import 'package:drug/features/schedule/presentation/cubit/dose_log_cubit.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  void _loadInitial() {
    final activeState = context.read<ActiveProfileCubit>().state;
    if (activeState is ActiveProfileSelected) {
      _load(activeState.profile.id);
    }
  }

  void _load(String profileId) {
    context.read<ScheduleBloc>().add(SchedulesStarted(profileId));
    context.read<ExpirationWarningCubit>().refresh();
    context.read<AdherenceBloc>().add(AdherenceStarted(profileId: profileId));
    context.read<DoseLogCubit>().loadForDate(profileId, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ActiveProfileCubit, ActiveProfileState>(
          listener: (context, activeState) {
            if (activeState is ActiveProfileSelected) {
              _load(activeState.profile.id);
            }
          },
        ),
        BlocListener<ScheduleBloc, ScheduleState>(
          listener: (context, scheduleState) {
            if (scheduleState is ScheduleDoseActionSuccess) {
              final activeState = context.read<ActiveProfileCubit>().state;
              if (activeState is ActiveProfileSelected) {
                final profileId = activeState.profile.id;
                context.read<DoseLogCubit>().loadForDate(profileId, DateTime.now());
                context.read<AdherenceBloc>().add(AdherenceStarted(profileId: profileId));
                context.read<ExpirationWarningCubit>().refresh();
              }
            }
          },
        ),
      ],
      child: BlocBuilder<ActiveProfileCubit, ActiveProfileState>(
        builder: (context, activeState) {
          if (activeState is ActiveProfileEmpty) {
            return _NoProfileView();
          }
          final profile = (activeState as ActiveProfileSelected).profile;
          return _DashboardContent(profile: profile);
        },
      ),
    );
  }
}

// ── No-profile empty state ───────────────────────────────────────────────────

class _NoProfileView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add_outlined,
                    size: 56,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to MedManager',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Create a profile to start managing\nmedications and schedules.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.profileForm),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Profile'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go(AppRoutes.profiles),
                  child: const Text('Select Existing Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Main dashboard content ───────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.profile});

  final CaregiverProfile profile;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greeting(now.hour);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 16, bottom: 14, right: 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Text(
                    profile.displayName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.tertiary,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const CircleAvatar(
                  radius: 16,
                  child: Icon(Icons.person, size: 18),
                ),
                tooltip: 'Switch profile',
                onPressed: () => context.push(AppRoutes.profiles),
              ),
              const SizedBox(width: 4),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 16),

                // ── Expiry alert banner ─────────────────────────────────
                BlocBuilder<ExpirationWarningCubit, ExpirationWarningState>(
                  builder: (context, state) {
                    if (state is! ExpirationWarningLoaded) {
                      return const SizedBox.shrink();
                    }
                    if (state.criticalCount == 0 && state.warningCount == 0) {
                      return const SizedBox.shrink();
                    }
                    return _ExpiryAlertCard(state: state);
                  },
                ),

                // ── Quick stats ─────────────────────────────────────────
                const SizedBox(height: 16),
                _SectionTitle(title: 'Overview'),
                const SizedBox(height: 10),
                BlocBuilder<ScheduleBloc, ScheduleState>(
                  builder: (context, state) {
                    final schedules = state is ScheduleLoaded
                        ? state.schedules
                        : <DoseSchedule>[];
                    final active =
                        schedules.where((s) => s.isActive).length;
                    return BlocBuilder<ExpirationWarningCubit,
                        ExpirationWarningState>(
                      builder: (context, expState) {
                        final expCount = expState is ExpirationWarningLoaded
                            ? expState.criticalCount + expState.warningCount
                            : 0;
                        return BlocBuilder<AdherenceBloc, AdherenceState>(
                          builder: (context, adhState) {
                            final adhPct = adhState is AdherenceLoaded
                                ? adhState.summary.adherencePercent
                                : 0.0;
                            return _QuickStatsRow(
                              activeSchedules: active,
                              totalSchedules: schedules.length,
                              expiringCount: expCount,
                              adherencePercent: adhPct,
                            );
                          },
                        );
                      },
                    );
                  },
                ),

                // ── Today's doses ───────────────────────────────────────
                const SizedBox(height: 24),
                _SectionTitle(title: "Today's Doses"),
                const SizedBox(height: 10),
                BlocBuilder<DoseLogCubit, DoseLogState>(
                  builder: (context, state) {
                    if (state is DoseLogInitial || state is DoseLogLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is DoseLogError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Error loading doses: ${state.failure.message}',
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      );
                    }
                    if (state is DoseLogLoaded) {
                      final logs = state.logs;
                      if (logs.isEmpty) {
                        return _EmptyCard(
                          icon: Icons.check_circle_outline,
                          message: 'No doses scheduled for today',
                        );
                      }

                      final sortedLogs = [...logs]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

                      return Column(
                        children: sortedLogs
                            .map((log) => _TodayDoseOccurrenceCard(log: log))
                            .toList(),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // ── Quick actions ───────────────────────────────────────
                const SizedBox(height: 24),
                _SectionTitle(title: 'Quick Actions'),
                const SizedBox(height: 10),
                _QuickActionsGrid(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 12) return 'Good morning 🌅';
    if (hour < 17) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }

  List<DoseSchedule> _todaysDoses(List<DoseSchedule> schedules) {
    final now = DateTime.now();
    final weekday = now.weekday; // 1=Mon … 7=Sun

    return schedules.where((s) {
      if (!s.isActive) return false;
      return switch (s.recurrenceRule.type) {
        ScheduleType.daily => true,
        ScheduleType.prn => false,
        ScheduleType.weekly =>
          s.recurrenceRule.daysOfWeek?.contains(weekday) ?? false,
        ScheduleType.customInterval => true,
      };
    }).toList();
  }
}

// ── Expiry alert card ────────────────────────────────────────────────────────

class _ExpiryAlertCard extends StatelessWidget {
  const _ExpiryAlertCard({required this.state});

  final ExpirationWarningLoaded state;

  @override
  Widget build(BuildContext context) {
    final isCritical = state.criticalCount > 0;
    final color = isCritical ? Colors.red : Colors.orange;
    final text = isCritical
        ? '${state.criticalCount} medication(s) expiring within 7 days!'
        : '${state.warningCount} medication(s) expiring this month';

    return Card(
      color: color.shade50,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: color.shade700, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: color.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _showExpirySheet(context, state.warnings),
              child: Text(
                'View All',
                style: TextStyle(color: color.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpirySheet(
    BuildContext context,
    List<ExpirationWarning> warnings,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ExpiryBottomSheet(warnings: warnings),
    );
  }
}

// ── Expiry bottom sheet (public — also used from inventory_list_page) ────────

class ExpiryBottomSheet extends StatelessWidget {
  const ExpiryBottomSheet({super.key, required this.warnings});

  final List<ExpirationWarning> warnings;

  @override
  Widget build(BuildContext context) {
    final sorted = [...warnings]
      ..sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Expiring Medications',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${warnings.length} items',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: sorted.length,
                itemBuilder: (_, i) {
                  final w = sorted[i];
                  final isExpired = w.daysUntilExpiry < 0;
                  final isCritical =
                      w.severity == ExpirationSeverity.critical;
                  final color = isExpired
                      ? Colors.red
                      : isCritical
                          ? Colors.deepOrange
                          : Colors.orange;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.shade100,
                      child: Icon(
                        Icons.medication,
                        color: color.shade700,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      w.medication.name,
                      style:
                          const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(w.medication.drugForm.name),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.shade200),
                      ),
                      child: Text(
                        isExpired
                            ? 'Expired'
                            : w.daysUntilExpiry == 0
                                ? 'Today!'
                                : '${w.daysUntilExpiry}d left',
                        style: TextStyle(
                          color: color.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(AppRoutes.inventory);
                  },
                  icon: const Icon(Icons.medication_outlined),
                  label: const Text('Go to Inventory'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Quick stats row ──────────────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({
    required this.activeSchedules,
    required this.totalSchedules,
    required this.expiringCount,
    required this.adherencePercent,
  });

  final int activeSchedules;
  final int totalSchedules;
  final int expiringCount;
  final double adherencePercent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.schedule_outlined,
            label: 'Active\nSchedules',
            value: '$activeSchedules',
            color: Theme.of(context).colorScheme.primary,
            onTap: () => context.go(AppRoutes.schedule),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.medication_outlined,
            label: 'Total\nSchedules',
            value: '$totalSchedules',
            color: Theme.of(context).colorScheme.secondary,
            onTap: () => context.go(AppRoutes.schedule),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.warning_amber_outlined,
            label: 'Expiring\nSoon',
            value: '$expiringCount',
            color: expiringCount > 0
                ? Colors.orange.shade600
                : Colors.green.shade600,
            onTap: () => context.go(AppRoutes.inventory),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            icon: Icons.insights_outlined,
            label: 'Adherence',
            value: '${adherencePercent.toStringAsFixed(0)}%',
            color: adherencePercent >= 80
                ? Colors.green.shade600
                : adherencePercent >= 50
                    ? Colors.orange.shade600
                    : Colors.red.shade600,
            onTap: () => context.push(AppRoutes.adherence),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Today's dose card ────────────────────────────────────────────────────────

class _TodayDoseOccurrenceCard extends StatelessWidget {
  const _TodayDoseOccurrenceCard({required this.log});

  final DoseLog log;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeStr = DateFormat('h:mm a').format(log.scheduledAt);
    
    String subtitleText = timeStr;
    if (log.status == DoseStatus.taken && log.takenAt != null) {
      subtitleText += ' • Taken at ${DateFormat('h:mm a').format(log.takenAt!)}';
    } else if (log.status == DoseStatus.skipped) {
      subtitleText += ' • Skipped';
    } else if (log.status == DoseStatus.missed) {
      subtitleText += ' • Missed';
    }

    Color iconBgColor;
    Color iconColor;
    IconData iconData;

    switch (log.status) {
      case DoseStatus.taken:
        iconBgColor = Colors.green.shade50;
        iconColor = Colors.green.shade700;
        iconData = Icons.check_circle;
      case DoseStatus.skipped:
        iconBgColor = Colors.grey.shade100;
        iconColor = Colors.grey.shade600;
        iconData = Icons.next_plan_outlined;
      case DoseStatus.missed:
        iconBgColor = Colors.red.shade50;
        iconColor = Colors.red.shade700;
        iconData = Icons.error_outline;
      case DoseStatus.pending:
        iconBgColor = cs.primaryContainer;
        iconColor = cs.onPrimaryContainer;
        iconData = Icons.medication_outlined;
    }

    final isActionable = log.status == DoseStatus.pending || log.status == DoseStatus.missed;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconBgColor,
          child: Icon(
            iconData,
            color: iconColor,
            size: 20,
          ),
        ),
        title: Text(
          log.medicationName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: !isActionable ? TextDecoration.lineThrough : null,
            color: !isActionable ? cs.onSurfaceVariant.withOpacity(0.6) : null,
          ),
        ),
        subtitle: Text(
          subtitleText,
          style: TextStyle(
            color: log.status == DoseStatus.missed ? cs.error : cs.onSurfaceVariant,
          ),
        ),
        trailing: isActionable
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check_circle_outline, color: cs.primary),
                    tooltip: 'Mark as Taken',
                    onPressed: () {
                      context.read<ScheduleBloc>().add(
                            ScheduleDoseTaken(
                              LogDoseParams(
                                scheduleId: log.scheduleId,
                                profileId: log.profileId,
                                medicationId: log.medicationId,
                                scheduledAt: log.scheduledAt,
                              ),
                            ),
                          );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: cs.error),
                    tooltip: 'Skip',
                    onPressed: () {
                      context.read<ScheduleBloc>().add(
                            ScheduleDoseSkipped(
                              LogDoseParams(
                                scheduleId: log.scheduleId,
                                profileId: log.profileId,
                                medicationId: log.medicationId,
                                scheduledAt: log.scheduledAt,
                              ),
                            ),
                          );
                    },
                  ),
                ],
              )
            : null,
        onTap: () {
          _showActionBottomSheet(context, log);
        },
      ),
    );
  }

  void _showActionBottomSheet(BuildContext context, DoseLog log) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DoseActionBottomSheet(log: log),
    );
  }
}

class _DoseActionBottomSheet extends StatefulWidget {
  const _DoseActionBottomSheet({required this.log});

  final DoseLog log;

  @override
  State<_DoseActionBottomSheet> createState() => _DoseActionBottomSheetState();
}

class _DoseActionBottomSheetState extends State<_DoseActionBottomSheet> {
  late final TextEditingController _notesController;
  bool _notesChanged = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.log.notes ?? '');
    _notesController.addListener(_onNotesChanged);
  }

  @override
  void dispose() {
    _notesController.removeListener(_onNotesChanged);
    _notesController.dispose();
    super.dispose();
  }

  void _onNotesChanged() {
    final changed = _notesController.text.trim() != (widget.log.notes ?? '');
    if (changed != _notesChanged) {
      setState(() {
        _notesChanged = changed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeStr = DateFormat('EEEE, MMMM d • h:mm a').format(widget.log.scheduledAt);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.medication, color: cs.primary, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.log.medicationName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      timeStr,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (widget.log.status == DoseStatus.taken) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.log.takenAt != null
                          ? 'This dose was taken at ${DateFormat('h:mm a').format(widget.log.takenAt!)}'
                          : 'This dose was marked as taken.',
                      style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Notes (Optional)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'e.g., Taken with food, felt slightly dizzy',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            if (_notesChanged) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    context.read<ScheduleBloc>().add(
                          ScheduleDoseTaken(
                            LogDoseParams(
                              scheduleId: widget.log.scheduleId,
                              profileId: widget.log.profileId,
                              medicationId: widget.log.medicationId,
                              scheduledAt: widget.log.scheduledAt,
                              notes: _notesController.text.trim().isNotEmpty
                                  ? _notesController.text.trim()
                                  : null,
                            ),
                          ),
                        );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Notes'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      context.read<ScheduleBloc>().add(
                            ScheduleDoseReverted(
                              LogDoseParams(
                                scheduleId: widget.log.scheduleId,
                                profileId: widget.log.profileId,
                                medicationId: widget.log.medicationId,
                                scheduledAt: widget.log.scheduledAt,
                              ),
                            ),
                          );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.undo),
                    label: const Text('Revert Dose'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      context.read<ScheduleBloc>().add(
                            ScheduleDoseSkipped(
                              LogDoseParams(
                                scheduleId: widget.log.scheduleId,
                                profileId: widget.log.profileId,
                                medicationId: widget.log.medicationId,
                                scheduledAt: widget.log.scheduledAt,
                                notes: _notesController.text.trim().isNotEmpty
                                    ? _notesController.text.trim()
                                    : null,
                              ),
                            ),
                          );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Skip Dose'),
                  ),
                ),
              ],
            ),
          ] else if (widget.log.status == DoseStatus.skipped) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.next_plan_outlined, color: Colors.grey.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This dose was skipped.',
                      style: TextStyle(color: Colors.grey.shade900, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Notes (Optional)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'e.g., Taken with food, felt slightly dizzy',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            if (_notesChanged) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    context.read<ScheduleBloc>().add(
                          ScheduleDoseSkipped(
                            LogDoseParams(
                              scheduleId: widget.log.scheduleId,
                              profileId: widget.log.profileId,
                              medicationId: widget.log.medicationId,
                              scheduledAt: widget.log.scheduledAt,
                              notes: _notesController.text.trim().isNotEmpty
                                  ? _notesController.text.trim()
                                  : null,
                            ),
                          ),
                        );
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save Notes'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      context.read<ScheduleBloc>().add(
                            ScheduleDoseReverted(
                              LogDoseParams(
                                scheduleId: widget.log.scheduleId,
                                profileId: widget.log.profileId,
                                medicationId: widget.log.medicationId,
                                scheduledAt: widget.log.scheduledAt,
                              ),
                            ),
                          );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.undo),
                    label: const Text('Revert Dose'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      context.read<ScheduleBloc>().add(
                            ScheduleDoseTaken(
                              LogDoseParams(
                                scheduleId: widget.log.scheduleId,
                                profileId: widget.log.profileId,
                                medicationId: widget.log.medicationId,
                                scheduledAt: widget.log.scheduledAt,
                                notes: _notesController.text.trim().isNotEmpty
                                    ? _notesController.text.trim()
                                    : null,
                              ),
                            ),
                          );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm Taken'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Add Notes (Optional)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'e.g., Taken with food, felt slightly dizzy',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      context.read<ScheduleBloc>().add(
                            ScheduleDoseSkipped(
                              LogDoseParams(
                                scheduleId: widget.log.scheduleId,
                                profileId: widget.log.profileId,
                                medicationId: widget.log.medicationId,
                                scheduledAt: widget.log.scheduledAt,
                                notes: _notesController.text.trim().isNotEmpty
                                    ? _notesController.text.trim()
                                    : null,
                              ),
                            ),
                          );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Skip Dose'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      context.read<ScheduleBloc>().add(
                            ScheduleDoseTaken(
                              LogDoseParams(
                                scheduleId: widget.log.scheduleId,
                                profileId: widget.log.profileId,
                                medicationId: widget.log.medicationId,
                                scheduledAt: widget.log.scheduledAt,
                                notes: _notesController.text.trim().isNotEmpty
                                    ? _notesController.text.trim()
                                    : null,
                              ),
                            ),
                          );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm Taken'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Quick actions grid ───────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.add_circle_outline,
        label: 'Add Medication',
        color: Theme.of(context).colorScheme.primary,
        onTap: () => context.push(AppRoutes.inventoryForm),
      ),
      _QuickAction(
        icon: Icons.schedule_outlined,
        label: 'New Schedule',
        color: Theme.of(context).colorScheme.secondary,
        onTap: () => context.push(AppRoutes.scheduleForm),
      ),
      _QuickAction(
        icon: Icons.medication_outlined,
        label: 'View Inventory',
        color: Colors.teal,
        onTap: () => context.go(AppRoutes.inventory),
      ),
      _QuickAction(
        icon: Icons.person_add_outlined,
        label: 'Add Profile',
        color: Colors.indigo,
        onTap: () => context.push(AppRoutes.profileForm),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: actions.map((a) => _QuickActionTile(action: a)).toList(),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(action.icon, color: action.color, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

// ── Empty placeholder card ───────────────────────────────────────────────────

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey, size: 28),
            const SizedBox(width: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
