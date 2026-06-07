import 'package:hive_flutter/hive_flutter.dart';

import 'package:drug/core/constants/hive_box_names.dart';

abstract final class HiveRegistrar {
  static Future<void> init() async {
    await Hive.initFlutter();

    await Future.wait([
      Hive.openBox(HiveBoxNames.medications),
      Hive.openBox(HiveBoxNames.medicationStock),
      Hive.openBox(HiveBoxNames.caregiverProfiles),
      Hive.openBox(HiveBoxNames.doseSchedules),
      Hive.openBox(HiveBoxNames.doseLogs),
      Hive.openBox(HiveBoxNames.syncQueue),
      Hive.openBox(HiveBoxNames.userPreferences),
    ]);
  }
}
