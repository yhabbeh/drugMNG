## 2. Core Domain Entities

These are pure Dart classes without any dependency on external libraries (like Isar annotations) to keep the domain layer clean.

```dart
// domain/entities/profile.dart
class Profile {
  final String id;
  final String name;
  final DateTime dateOfBirth;
  final String? relation; // e.g., 'Self', 'Spouse', 'Child'

  Profile({
    required this.id,
    required this.name,
    required this.dateOfBirth,
    this.relation,
  });
}

// domain/entities/medication.dart
enum MedicationForm { pill, liquid, injection, inhaler, drops, other }

class Medication {
  final String id;
  final String name;
  final String? activeIngredients; // For future interaction checks
  final MedicationForm form;
  final String strength; // e.g., "500mg"
  final int totalQuantity; // Current stock
  final DateTime expiryDate;
  final String? barcode;

  Medication({
    required this.id,
    required this.name,
    this.activeIngredients,
    required this.form,
    required this.strength,
    required this.totalQuantity,
    required this.expiryDate,
    this.barcode,
  });

  bool get isLowStock => totalQuantity < 10; // Logic could be moved to UseCase
  bool get isNearExpiry => expiryDate.difference(DateTime.now()).inDays < 30;
}

// domain/entities/schedule.dart
enum ScheduleType { chronic, temporary }

class Schedule {
  final String id;
  final String profileId;
  final String medicationId;
  final ScheduleType type;
  final DateTime startDate;
  final DateTime? endDate; // Nullable for chronic
  final List<String> doseTimings; // e.g., ["08:00", "20:00"]
  final int quantityPerDose; // e.g., 1 pill
  final bool requiresFullScreenAlarm; // Critical meds

  Schedule({
    required this.id,
    required this.profileId,
    required this.medicationId,
    required this.type,
    required this.startDate,
    this.endDate,
    required this.doseTimings,
    required this.quantityPerDose,
    this.requiresFullScreenAlarm = false,
  });
}

// domain/entities/dose_log.dart
enum DoseStatus { taken, skipped, missed, pending }

class DoseLog {
  final String id;
  final String scheduleId;
  final String profileId;
  final String medicationId;
  final DateTime scheduledTime;
  final DateTime? actualTakenTime;
  final DoseStatus status;
  final int quantity;

  DoseLog({
    required this.id,
    required this.scheduleId,
    required this.profileId,
    required this.medicationId,
    required this.scheduledTime,
    this.actualTakenTime,
    required this.status,
    required this.quantity,
  });
}
```
