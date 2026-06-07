import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:drug/core/notifications/notification_payload.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';
import 'package:drug/features/schedule/presentation/bloc/schedule_bloc.dart';

class DoseActionPage extends StatelessWidget {
  const DoseActionPage({super.key, this.payload});

  final String? payload;

  @override
  Widget build(BuildContext context) {
    NotificationPayload? data;
    if (payload != null) {
      try {
        data = NotificationPayload.decode(payload!);
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dose Reminder')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.medication,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                data?.medicationId ?? 'Medication',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (data != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Scheduled at ${data.scheduledAt}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Did you take your dose?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    if (data != null) {
                      context.read<ScheduleBloc>().add(
                            ScheduleDoseTaken(
                              LogDoseParams(
                                scheduleId: data.scheduleId,
                                profileId: data.profileId,
                                medicationId: data.medicationId,
                                scheduledAt: DateTime.parse(data.scheduledAt),
                              ),
                            ),
                          );
                    }
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Taken'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (data != null) {
                      context.read<ScheduleBloc>().add(
                            ScheduleDoseSkipped(
                              LogDoseParams(
                                scheduleId: data.scheduleId,
                                profileId: data.profileId,
                                medicationId: data.medicationId,
                                scheduledAt: DateTime.parse(data.scheduledAt),
                              ),
                            ),
                          );
                    }
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Skip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
