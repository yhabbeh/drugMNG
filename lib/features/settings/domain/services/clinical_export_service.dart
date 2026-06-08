import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import 'package:drug/core/constants/hive_box_names.dart';
import 'package:drug/features/schedule/data/models/dose_log_model.dart';

final class ClinicalExportService {
  static String generateCsv(String profileId) {
    final box = Hive.box(HiveBoxNames.doseLogs);
    final logs = box.values.map((raw) {
      return DoseLogModel.fromJson(
        jsonDecode(raw as String) as Map<String, dynamic>,
      ).toDomain();
    }).where((l) => l.profileId == profileId).toList();

    // Sort logs chronologically descending
    logs.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    final csv = StringBuffer();
    // CSV Header
    csv.writeln('Date,Time,Medication,Status,Scheduled At,Taken At,Notes');

    for (final log in logs) {
      final date = DateFormat('yyyy-MM-dd').format(log.scheduledAt);
      final time = DateFormat('HH:mm').format(log.scheduledAt);
      final medName = log.medicationName.replaceAll('"', '""');
      final status = log.status.name;
      final scheduledAt = log.scheduledAt.toIso8601String();
      final takenAt = log.takenAt?.toIso8601String() ?? '';
      final notes = (log.notes ?? '').replaceAll('"', '""');

      csv.writeln('"$date","$time","$medName","$status","$scheduledAt","$takenAt","$notes"');
    }

    return csv.toString();
  }
}
