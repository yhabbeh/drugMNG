import 'package:flutter_test/flutter_test.dart';

import 'package:drug/core/constants/hive_box_names.dart';

void main() {
  test('HiveBoxNames are defined', () {
    expect(HiveBoxNames.medications, isNotEmpty);
    expect(HiveBoxNames.medicationStock, isNotEmpty);
    expect(HiveBoxNames.caregiverProfiles, isNotEmpty);
    expect(HiveBoxNames.doseSchedules, isNotEmpty);
    expect(HiveBoxNames.doseLogs, isNotEmpty);
    expect(HiveBoxNames.syncQueue, isNotEmpty);
    expect(HiveBoxNames.userPreferences, isNotEmpty);
  });
}
