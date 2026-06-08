import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:drug/features/profiles/presentation/cubit/active_profile_cubit.dart';
import 'package:drug/features/schedule/domain/entities/calendar_dose.dart';
import 'package:drug/features/schedule/domain/entities/dose_log.dart';
import 'package:drug/features/schedule/domain/services/schedule_calendar_builder.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';
import 'package:drug/features/schedule/presentation/bloc/schedule_bloc.dart';
import 'package:drug/features/schedule/presentation/cubit/calendar_cubit.dart';
import 'package:drug/features/schedule/presentation/widgets/shared_dose_action_sheet.dart';

class ScheduleCalendarView extends StatefulWidget {
  const ScheduleCalendarView({super.key});

  @override
  State<ScheduleCalendarView> createState() => _ScheduleCalendarViewState();
}

class _ScheduleCalendarViewState extends State<ScheduleCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initWatch();
  }

  void _initWatch() {
    final activeState = context.read<ActiveProfileCubit>().state;
    if (activeState is ActiveProfileSelected) {
      context.read<CalendarCubit>().startWatching(activeState.profile.id);
    }
  }

  List<CalendarDose> _getEventsForDay(
    DateTime day,
    CalendarLoaded state,
  ) {
    return ScheduleCalendarBuilder.buildDosesForDate(
      date: day,
      schedules: state.schedules,
      logs: state.logs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocListener<ActiveProfileCubit, ActiveProfileState>(
      listener: (context, activeState) {
        if (activeState is ActiveProfileSelected) {
          context.read<CalendarCubit>().startWatching(activeState.profile.id);
        }
      },
      child: BlocBuilder<CalendarCubit, CalendarState>(
        builder: (context, state) {
          if (state is CalendarInitial || state is CalendarLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CalendarError) {
            return Center(child: Text('Error loading calendar: ${state.failure.message}'));
          }

          final loaded = state as CalendarLoaded;
          final eventsForSelectedDay = _getEventsForDay(_selectedDay, loaded);

          return Column(
            children: [
              // ── Calendar Container ──
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TableCalendar<CalendarDose>(
                    firstDay: DateTime.now().subtract(const Duration(days: 365)),
                    lastDay: DateTime.now().add(const Duration(days: 365)),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    eventLoader: (day) => _getEventsForDay(day, loaded),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: cs.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      markerMargin: const EdgeInsets.only(top: 6),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isEmpty) return const SizedBox.shrink();
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: events.take(4).map((event) {
                            final color = switch (event.status) {
                              CalendarDoseStatus.taken => Colors.green.shade600,
                              CalendarDoseStatus.skipped => Colors.grey.shade600,
                              CalendarDoseStatus.missed => Colors.red.shade600,
                              CalendarDoseStatus.pending => Colors.blue.shade600,
                            };
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ── Day Header ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      isSameDay(_selectedDay, DateTime.now())
                          ? "Today's Doses"
                          : DateFormat('EEEE, MMMM d').format(_selectedDay),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${eventsForSelectedDay.length} scheduled',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Doses List ──
              Expanded(
                child: eventsForSelectedDay.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No doses scheduled',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: eventsForSelectedDay.length,
                        itemBuilder: (context, index) {
                          final dose = eventsForSelectedDay[index];
                          final activeProfile = context.read<ActiveProfileCubit>().state as ActiveProfileSelected;
                          final profileId = activeProfile.profile.id;

                          final log = DoseLog(
                            id: '',
                            scheduleId: dose.scheduleId,
                            profileId: profileId,
                            medicationId: dose.medicationId,
                            medicationName: dose.medicationName,
                            scheduledAt: dose.scheduledAt,
                            takenAt: dose.takenAt,
                            status: switch (dose.status) {
                              CalendarDoseStatus.taken => DoseStatus.taken,
                              CalendarDoseStatus.skipped => DoseStatus.skipped,
                              CalendarDoseStatus.missed => DoseStatus.missed,
                              CalendarDoseStatus.pending => DoseStatus.pending,
                            },
                          );

                          return _CalendarDoseCard(log: log);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CalendarDoseCard extends StatelessWidget {
  const _CalendarDoseCard({required this.log});

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
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => SharedDoseActionSheet(log: log),
          );
        },
      ),
    );
  }
}
