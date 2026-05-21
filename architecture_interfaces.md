## 4. Dart Interfaces / Abstract Classes

These interfaces reside in the Domain layer and define contracts that the Data layer will implement. We use `dartz`'s `Either` for structured error handling.

```dart
// core/error/failures.dart
abstract class Failure {}
class ServerFailure extends Failure {}
class CacheFailure extends Failure {}
class MLKitFailure extends Failure {}
class NotFoundFailure extends Failure {}

// features/scanner/domain/repositories/i_scanner_repository.dart
import 'package:dartz/dartz.dart';
// Note: In real app, import 'package:your_app/core/error/failures.dart';
// Note: In real app, import 'package:your_app/features/inventory/domain/entities/medication.dart';

abstract class IScannerRepository {
  /// Fetches medication details using a barcode via remote API.
  Future<Either<Failure, Medication>> getMedicationByBarcode(String barcode);

  /// Uses Google ML Kit to extract raw text from an image path for OCR fallback.
  Future<Either<Failure, String>> extractTextFromImage(String imagePath);

  /// (Optional) A method to try and parse the extracted text into structured Medication data
  Future<Either<Failure, Medication>> parseMedicationFromText(String extractedText);
}


// features/schedule/domain/repositories/i_schedule_repository.dart
import 'package:dartz/dartz.dart';
// Note: In real app, import 'package:your_app/core/error/failures.dart';
// Note: In real app, import 'package:your_app/features/schedule/domain/entities/schedule.dart';
// Note: In real app, import 'package:your_app/features/schedule/domain/entities/dose_log.dart';

abstract class IScheduleRepository {
  /// Creates a new medication schedule (Chronic or Temporary)
  Future<Either<Failure, void>> createSchedule(Schedule schedule);

  /// Retrieves all active schedules for a specific profile
  Future<Either<Failure, List<Schedule>>> getSchedulesByProfile(String profileId);

  /// Updates an existing schedule
  Future<Either<Failure, void>> updateSchedule(Schedule schedule);

  /// Deletes a schedule
  Future<Either<Failure, void>> deleteSchedule(String scheduleId);

  /// Logs a dose action (Taken, Skipped)
  /// If Taken, this should also trigger a use case to deduct from InventoryRepository
  Future<Either<Failure, void>> logDoseAction(DoseLog log);

  /// Retrieves upcoming doses for a specific date range
  Future<Either<Failure, List<DoseLog>>> getUpcomingDoses(DateTime start, DateTime end);
}
```
