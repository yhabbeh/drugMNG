import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:drug/core/router/app_routes.dart';
import 'package:drug/features/profiles/presentation/cubit/active_profile_cubit.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/entities/recurrence_rule.dart';
import 'package:drug/features/schedule/presentation/bloc/schedule_bloc.dart';

class ScheduleListPage extends StatefulWidget {
  const ScheduleListPage({super.key});

  @override
  State<ScheduleListPage> createState() => _ScheduleListPageState();
}

class _ScheduleListPageState extends State<ScheduleListPage> {
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
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ActiveProfileCubit, ActiveProfileState>(
      listener: (context, activeState) {
        if (activeState is ActiveProfileSelected) {
          _load(activeState.profile.id);
        }
      },
      child: BlocBuilder<ActiveProfileCubit, ActiveProfileState>(
        builder: (context, activeState) {
          if (activeState is ActiveProfileEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Schedule')),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No active profile selected',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => context.go(AppRoutes.profiles),
                      child: const Text('Select Profile'),
                    ),
                  ],
                ),
              ),
            );
          }

          final profile = (activeState as ActiveProfileSelected).profile;

          return Scaffold(
            appBar: AppBar(title: Text('${profile.displayName}\'s Schedule')),
            floatingActionButton: FloatingActionButton(
              onPressed: () => context.push(AppRoutes.scheduleForm),
              child: const Icon(Icons.add),
            ),
            body: BlocBuilder<ScheduleBloc, ScheduleState>(
              builder: (context, state) {
                return switch (state) {
                  ScheduleInitial() || ScheduleDoseActionSuccess() =>
                    const Center(child: CircularProgressIndicator()),
                  ScheduleLoading() => const Center(child: CircularProgressIndicator()),
                  ScheduleLoaded(:final schedules, :final isLoading) =>
                    _buildBody(context, schedules, isLoading: isLoading),
                  ScheduleError(:final failure) =>
                    Center(child: Text('Error: ${failure.message}')),
                };
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<DoseSchedule> schedules, {
    bool isLoading = false,
  }) {
    if (schedules.isEmpty) {
      return Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No schedules yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => context.push(AppRoutes.scheduleForm),
                  child: const Text('Add Schedule'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 88),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            return _ScheduleCard(
              schedule: schedule,
              onToggle: (active) {
                context.read<ScheduleBloc>().add(
                      ScheduleUpdated(
                        schedule.copyWith(
                          isActive: active,
                          updatedAt: DateTime.now(),
                        ),
                      ),
                    );
              },
              onTap: () => context.push(
                AppRoutes.scheduleForm,
                extra: schedule,
              ),
              onDelete: () => _confirmDelete(context, schedule),
            );
          },
        ),
        if (isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, DoseSchedule schedule) {
    final names = schedule.medications.map((m) => m.medicationName).join(', ');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Schedule'),
        content: Text(
          'Are you sure you want to delete the schedule for "$names"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context
                  .read<ScheduleBloc>()
                  .add(ScheduleDeleted(schedule.id));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.schedule,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  final DoseSchedule schedule;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final times = schedule.recurrenceRule.times;
    final timeStr = times.isNotEmpty
        ? times
            .map((t) {
              final period = t.hour >= 12 ? 'PM' : 'AM';
              final hour12 = t.hour == 0
                  ? 12
                  : t.hour > 12
                      ? t.hour - 12
                      : t.hour;
              return '${hour12.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} $period';
            })
            .join(', ')
        : 'As needed';

    final typeStr = switch (schedule.recurrenceRule.type) {
      ScheduleType.daily => 'Daily',
      ScheduleType.weekly => 'Weekly',
      ScheduleType.customInterval =>
        'Every ${schedule.recurrenceRule.intervalHours ?? '?'}h',
      ScheduleType.prn => 'As needed',
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              schedule.isActive ? Colors.teal.shade100 : Colors.grey.shade200,
          child: Icon(
            schedule.isActive ? Icons.schedule : Icons.pause_circle_outline,
            color: schedule.isActive ? Colors.teal : Colors.grey,
          ),
        ),
        title: Text(
          schedule.medications.map((m) => m.medicationName).join(', '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(timeStr),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _Badge(label: typeStr),
                ...schedule.medications
                    .where((m) => m.dosageAmount != null)
                    .map(
                      (m) => _Badge(
                        label:
                            '${m.medicationName}: ${m.dosageAmount} ${m.dosageUnit?.name ?? ''}',
                      ),
                    ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: schedule.isActive,
              onChanged: onToggle,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
      ),
    );
  }
}
