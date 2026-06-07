import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:drug/features/adherence/domain/entities/missed_dose.dart';

final class MissedDoseTile extends StatelessWidget {
  const MissedDoseTile({super.key, required this.dose});

  final MissedDose dose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateStr = DateFormat('EEE, MMM d • h:mm a').format(dose.scheduledAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.errorContainer,
          child: Icon(
            Icons.event_busy_outlined,
            color: cs.onErrorContainer,
            size: 20,
          ),
        ),
        title: Text(
          dose.medicationName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(dateStr),
        trailing: Icon(
          Icons.chevron_right,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
