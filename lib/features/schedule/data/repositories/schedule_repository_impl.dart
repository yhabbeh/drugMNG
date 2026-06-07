import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/error/exceptions.dart';
import 'package:drug/core/error/failure_mapper.dart';
import 'package:drug/core/network/network_info.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:drug/features/inventory/domain/usecases/inventory_params.dart';
import 'package:drug/features/schedule/data/datasources/schedule_local_datasource.dart';
import 'package:drug/features/schedule/data/datasources/schedule_remote_datasource.dart';
import 'package:drug/features/schedule/data/models/dose_log_model.dart';
import 'package:drug/features/schedule/data/models/dose_schedule_model.dart';
import 'package:drug/features/schedule/domain/entities/adherence_report.dart';
import 'package:drug/features/schedule/domain/entities/dose_log.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/domain/entities/recurrence_rule.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';
import 'package:uuid/uuid.dart';

@LazySingleton(as: ScheduleRepository)
final class ScheduleRepositoryImpl implements ScheduleRepository {
  ScheduleRepositoryImpl({
    required ScheduleRemoteDataSource remoteDataSource,
    required ScheduleLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
    required InventoryRepository inventoryRepository,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo,
        _inventoryRepository = inventoryRepository;

  final ScheduleRemoteDataSource _remoteDataSource;
  final ScheduleLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final InventoryRepository _inventoryRepository;

  @override
  EitherFailure<List<DoseSchedule>> getSchedulesForProfile(
    String profileId,
  ) async {
    try {
      final local = _localDataSource.getAllSchedules(profileId);
      if (local.isNotEmpty) {
        unawaited(_refreshSchedulesCache(profileId));
        return Right(local.map((m) => m.toDomain()).toList());
      }

      final remote = await _remoteDataSource.getAllSchedules(profileId);
      for (final schedule in remote) {
        await _localDataSource.saveSchedule(schedule);
      }
      return Right(remote.map((m) => m.toDomain()).toList());
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  StreamEitherFailure<List<DoseSchedule>> watchSchedulesForProfile(
    String profileId,
  ) {
    return _localDataSource.watchSchedules(profileId).map(
          (models) => Right(models.map((m) => m.toDomain()).toList()),
        );
  }

  @override
  EitherFailure<Unit> createSchedule(DoseSchedule schedule) async {
    try {
      // Assign a UUID if the form did not provide one.
      final scheduleWithId = schedule.id.isEmpty
          ? schedule.copyWith(id: const Uuid().v4())
          : schedule;
      final model = DoseScheduleModel.fromDomain(scheduleWithId);
      final isConnected = await _networkInfo.isConnected;

      if (isConnected) {
        final remote = await _remoteDataSource.createSchedule(model);
        await _localDataSource.saveSchedule(remote);
        return const Right(unit);
      }

      await _localDataSource.saveSchedule(model);
      return const Right(unit);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  EitherFailure<Unit> updateSchedule(DoseSchedule schedule) async {
    try {
      final model = DoseScheduleModel.fromDomain(schedule);
      final isConnected = await _networkInfo.isConnected;

      await _localDataSource.saveSchedule(model);
      if (isConnected) {
        await _remoteDataSource.updateSchedule(model);
      }
      return const Right(unit);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  EitherFailure<Unit> deleteSchedule(String id) async {
    try {
      await _localDataSource.deleteSchedule(id);
      return const Right(unit);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  EitherFailure<Unit> logDoseTaken(LogDoseParams params) async {
    try {
      final schedules = _localDataSource.getAllSchedules(params.profileId);
      final scheduleModel = schedules.cast<DoseScheduleModel?>().firstWhere(
            (s) => s?.id == params.scheduleId,
            orElse: () => null,
          );

      String displayMedName = '';
      if (scheduleModel != null) {
        final schedule = scheduleModel.toDomain();
        final matchMed = schedule.medications.firstWhereOrNull(
          (m) => m.medicationId == params.medicationId,
        );
        displayMedName = matchMed?.medicationName ?? schedule.medicationName;
      }

      if (displayMedName.isEmpty && params.medicationId.isNotEmpty) {
        final medResult = await _inventoryRepository.getMedications();
        medResult.fold(
          (_) {},
          (meds) {
            final match = meds.firstWhereOrNull((m) => m.id == params.medicationId);
            if (match != null) {
              displayMedName = match.name;
            }
          },
        );
      }

      if (displayMedName.isEmpty) {
        displayMedName = 'Medication';
      }

      final existingLogs = _localDataSource.getLogsForDate(params.profileId, params.scheduledAt);
      final existingLog = existingLogs.firstWhereOrNull(
        (l) => l.scheduleId == params.scheduleId &&
               l.medicationId == params.medicationId &&
               l.scheduledAt.isAtSameMomentAs(params.scheduledAt),
      );

      bool shouldDeductStock = true;
      String logId = const Uuid().v4();

      if (existingLog != null) {
        logId = existingLog.id;
        if (existingLog.status == DoseStatus.taken.name) {
          shouldDeductStock = false;
        }
      }

      final log = DoseLog(
        id: logId,
        scheduleId: params.scheduleId,
        profileId: params.profileId,
        medicationId: params.medicationId,
        medicationName: displayMedName,
        scheduledAt: params.scheduledAt,
        takenAt: DateTime.now(),
        status: DoseStatus.taken,
        notes: params.notes,
        stockDeductedCount: 1,
      );
      final model = DoseLogModel.fromDomain(log);
      await _localDataSource.logDose(model);

      if (shouldDeductStock && params.medicationId.isNotEmpty) {
        await _inventoryRepository.updateMedicationStock(
          UpdateStockParams(
            medicationId: params.medicationId,
            quantityChange: -1,
            reason: 'Dose taken',
          ),
        );
      }

      final isConnected = await _networkInfo.isConnected;
      if (isConnected) {
        await _remoteDataSource.logDoseTaken(model);
      }
      return const Right(unit);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  EitherFailure<Unit> logDoseSkipped(LogDoseParams params) async {
    try {
      final schedules = _localDataSource.getAllSchedules(params.profileId);
      final scheduleModel = schedules.cast<DoseScheduleModel?>().firstWhere(
            (s) => s?.id == params.scheduleId,
            orElse: () => null,
          );

      String displayMedName = '';
      if (scheduleModel != null) {
        final schedule = scheduleModel.toDomain();
        final matchMed = schedule.medications.firstWhereOrNull(
          (m) => m.medicationId == params.medicationId,
        );
        displayMedName = matchMed?.medicationName ?? schedule.medicationName;
      }

      if (displayMedName.isEmpty && params.medicationId.isNotEmpty) {
        final medResult = await _inventoryRepository.getMedications();
        medResult.fold(
          (_) {},
          (meds) {
            final match = meds.firstWhereOrNull((m) => m.id == params.medicationId);
            if (match != null) {
              displayMedName = match.name;
            }
          },
        );
      }

      if (displayMedName.isEmpty) {
        displayMedName = 'Medication';
      }

      final existingLogs = _localDataSource.getLogsForDate(params.profileId, params.scheduledAt);
      final existingLog = existingLogs.firstWhereOrNull(
        (l) => l.scheduleId == params.scheduleId &&
               l.medicationId == params.medicationId &&
               l.scheduledAt.isAtSameMomentAs(params.scheduledAt),
      );

      bool shouldRestoreStock = false;
      String logId = const Uuid().v4();

      if (existingLog != null) {
        logId = existingLog.id;
        if (existingLog.status == DoseStatus.taken.name) {
          shouldRestoreStock = true;
        }
      }

      final log = DoseLog(
        id: logId,
        scheduleId: params.scheduleId,
        profileId: params.profileId,
        medicationId: params.medicationId,
        medicationName: displayMedName,
        scheduledAt: params.scheduledAt,
        takenAt: null,
        status: DoseStatus.skipped,
        notes: params.notes,
        stockDeductedCount: 0,
      );
      final model = DoseLogModel.fromDomain(log);
      await _localDataSource.logDose(model);

      if (shouldRestoreStock && params.medicationId.isNotEmpty) {
        await _inventoryRepository.updateMedicationStock(
          UpdateStockParams(
            medicationId: params.medicationId,
            quantityChange: 1,
            reason: 'Dose change to skipped',
          ),
        );
      }

      final isConnected = await _networkInfo.isConnected;
      if (isConnected) {
        await _remoteDataSource.logDoseSkipped(model);
      }
      return const Right(unit);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  EitherFailure<Unit> revertDoseLog(LogDoseParams params) async {
    try {
      final existingLogs = _localDataSource.getLogsForDate(params.profileId, params.scheduledAt);
      final existingLog = existingLogs.firstWhereOrNull(
        (l) => l.scheduleId == params.scheduleId &&
               l.medicationId == params.medicationId &&
               l.scheduledAt.isAtSameMomentAs(params.scheduledAt),
      );

      if (existingLog != null) {
        if (existingLog.status == DoseStatus.taken.name && params.medicationId.isNotEmpty) {
          await _inventoryRepository.updateMedicationStock(
            UpdateStockParams(
              medicationId: params.medicationId,
              quantityChange: 1,
              reason: 'Dose reverted',
            ),
          );
        }
        await _localDataSource.deleteLog(existingLog.id);
      }
      return const Right(unit);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  List<DateTime> _getScheduledOccurrencesForDate(DoseSchedule schedule, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    final scheduleStart = DateTime(schedule.startDate.year, schedule.startDate.month, schedule.startDate.day);
    if (startOfDay.isBefore(scheduleStart)) return [];

    if (schedule.endDate != null) {
      final scheduleEnd = DateTime(
        schedule.endDate!.year,
        schedule.endDate!.month,
        schedule.endDate!.day,
        23,
        59,
        59,
        999,
      );
      if (endOfDay.isAfter(scheduleEnd)) return [];
    }

    if (!schedule.isActive) return [];

    final occurrences = <DateTime>[];

    switch (schedule.recurrenceRule.type) {
      case ScheduleType.daily:
        for (final time in schedule.recurrenceRule.times) {
          occurrences.add(DateTime(date.year, date.month, date.day, time.hour, time.minute));
        }
      case ScheduleType.weekly:
        final daysOfWeek = schedule.recurrenceRule.daysOfWeek ?? [];
        if (daysOfWeek.contains(date.weekday)) {
          for (final time in schedule.recurrenceRule.times) {
            occurrences.add(DateTime(date.year, date.month, date.day, time.hour, time.minute));
          }
        }
      case ScheduleType.customInterval:
        final interval = Duration(hours: schedule.recurrenceRule.intervalHours ?? 24);
        var current = schedule.startDate;
        if (current.isBefore(startOfDay)) {
          final hoursDiff = startOfDay.difference(current).inHours;
          final intervalsToSkip = (hoursDiff / (schedule.recurrenceRule.intervalHours ?? 24)).floor();
          current = current.add(interval * intervalsToSkip);
        }
        while (current.isBefore(startOfDay)) {
          current = current.add(interval);
        }
        while (!current.isAfter(endOfDay)) {
          if (!current.isBefore(startOfDay)) {
            occurrences.add(current);
          }
          current = current.add(interval);
        }
      case ScheduleType.prn:
        break;
    }

    return occurrences;
  }

  @override
  EitherFailure<List<DoseLog>> getDoseLogsForDate(
    GetLogsForDateParams params,
  ) async {
    try {
      final localLogs = _localDataSource
          .getLogsForDate(
            params.profileId,
            params.date,
          )
          .map((m) => m.toDomain())
          .toList();

      final schedulesModel = _localDataSource.getAllSchedules(params.profileId);
      final schedules = schedulesModel.map((m) => m.toDomain()).toList();

      final generatedLogs = <DoseLog>[];
      final now = DateTime.now();

      for (final schedule in schedules) {
        final occurrences = _getScheduledOccurrencesForDate(schedule, params.date);
        for (final occurrence in occurrences) {
          for (final med in schedule.medications) {
            final existingLog = localLogs.firstWhereOrNull(
              (l) => l.scheduleId == schedule.id && 
                     l.medicationId == med.medicationId &&
                     l.scheduledAt.isAtSameMomentAs(occurrence),
            );

            if (existingLog != null) {
              generatedLogs.add(existingLog);
            } else {
              final isPast = occurrence.isBefore(now);
              generatedLogs.add(DoseLog(
                id: '',
                scheduleId: schedule.id,
                profileId: params.profileId,
                medicationId: med.medicationId,
                medicationName: med.medicationName,
                scheduledAt: occurrence,
                status: isPast ? DoseStatus.missed : DoseStatus.pending,
              ));
            }
          }
        }
      }

      for (final localLog in localLogs) {
        final alreadyAdded = generatedLogs.any(
          (g) => g.id == localLog.id || 
                 (g.scheduleId == localLog.scheduleId &&
                  g.medicationId == localLog.medicationId &&
                  g.scheduledAt.isAtSameMomentAs(localLog.scheduledAt)),
        );
        if (!alreadyAdded) {
          generatedLogs.add(localLog);
        }
      }

      return Right(generatedLogs);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  EitherFailure<AdherenceReport> getAdherenceReport(
    AdherenceParams params,
  ) async {
    try {
      final logs = _localDataSource.getLogsForDate(
        params.profileId,
        params.periodStart,
      );
      final totalScheduled = logs.length;
      final taken = logs.where((l) => l.status == 'taken').length;
      final skipped = logs.where((l) => l.status == 'skipped').length;
      final missed = totalScheduled - taken - skipped;

      return Right(AdherenceReport(
        profileId: params.profileId,
        periodStart: params.periodStart,
        periodEnd: params.periodEnd,
        totalScheduled: totalScheduled,
        taken: taken,
        skipped: skipped,
        missed: missed,
      ));
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  Future<void> _refreshSchedulesCache(String profileId) async {
    try {
      final remote = await _remoteDataSource.getAllSchedules(profileId);
      for (final schedule in remote) {
        await _localDataSource.saveSchedule(schedule);
      }
    } catch (_) {}
  }
}
