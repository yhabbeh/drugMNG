import 'package:drug/core/error/failures.dart';
import 'package:drug/features/adherence/domain/entities/adherence_range.dart';
import 'package:drug/features/adherence/domain/usecases/get_adherence_summary.dart';
import 'package:drug/features/schedule/domain/entities/dose_log.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockScheduleRepository extends Mock implements ScheduleRepository {}

DoseLog _log({
  required String id,
  required DateTime scheduledAt,
  required DoseStatus status,
  String name = 'Med',
}) {
  return DoseLog(
    id: id,
    scheduleId: 'sch',
    profileId: 'p1',
    medicationId: 'm1',
    medicationName: name,
    scheduledAt: scheduledAt,
    status: status,
  );
}

void main() {
  late _MockScheduleRepository repo;
  late GetAdherenceSummary usecase;

  setUpAll(() {
    registerFallbackValue(
      GetLogsForDateParams(
        profileId: '',
        date: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
  });

  setUp(() {
    repo = _MockScheduleRepository();
    usecase = GetAdherenceSummary(repo);
  });

  group('GetAdherenceSummary', () {
    final now = DateTime(2025, 6, 10, 12);

    test('returns zero summary when no logs exist', () async {
      when(() => repo.getDoseLogsForDate(any())).thenAnswer(
        (_) async => right(<DoseLog>[]),
      );

      final result = await usecase(AdherenceRangeParams(
        profileId: 'p1',
        range: AdherenceRange.week,
        now: now,
      ));

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (summary) {
          expect(summary.taken, 0);
          expect(summary.skipped, 0);
          expect(summary.missed, 0);
          expect(summary.pending, 0);
          expect(summary.streakDays, 0);
          expect(summary.adherencePercent, 0);
          expect(summary.dailyPoints, hasLength(7));
        },
      );
      verify(() => repo.getDoseLogsForDate(any())).called(7);
    });

    test('aggregates counts across the range', () async {
      when(() => repo.getDoseLogsForDate(any())).thenAnswer(
        (inv) async {
          final p =
              inv.positionalArguments.first as GetLogsForDateParams;
          final base = DateTime(p.date.year, p.date.month, p.date.day);
          return right(<DoseLog>[
            _log(id: '${p.date.day}-1', scheduledAt: base.add(const Duration(hours: 8)), status: DoseStatus.taken),
            _log(id: '${p.date.day}-2', scheduledAt: base.add(const Duration(hours: 14)), status: DoseStatus.taken),
            _log(id: '${p.date.day}-3', scheduledAt: base.add(const Duration(hours: 20)), status: DoseStatus.skipped),
          ]);
        },
      );

      final result = await usecase(AdherenceRangeParams(
        profileId: 'p1',
        range: AdherenceRange.week,
        now: now,
      ));

      result.fold(
        (_) => fail('expected Right'),
        (summary) {
          expect(summary.taken, 14);
          expect(summary.skipped, 7);
          expect(summary.missed, 0);
          expect(summary.adherencePercent, closeTo((14 / 21) * 100, 0.01));
        },
      );
    });

    test('counts a 3-day streak ending at last logged day', () async {
      when(() => repo.getDoseLogsForDate(any())).thenAnswer(
        (inv) async {
          final p =
              inv.positionalArguments.first as GetLogsForDateParams;
          final base = DateTime(p.date.year, p.date.month, p.date.day);
          if (p.date.day >= 8 && p.date.day <= 10) {
            return right(<DoseLog>[
              _log(id: '${p.date.day}-t', scheduledAt: base.add(const Duration(hours: 9)), status: DoseStatus.taken),
            ]);
          } else if (p.date.day == 7) {
            return right(<DoseLog>[
              _log(id: '7-s', scheduledAt: base.add(const Duration(hours: 9)), status: DoseStatus.skipped),
            ]);
          }
          return right(<DoseLog>[]);
        },
      );

      final result = await usecase(AdherenceRangeParams(
        profileId: 'p1',
        range: AdherenceRange.week,
        now: now,
      ));

      result.fold(
        (_) => fail('expected Right'),
        (summary) {
          expect(summary.streakDays, 3);
        },
      );
    });

    test('streak is broken when a day has any missed dose', () async {
      when(() => repo.getDoseLogsForDate(any())).thenAnswer(
        (inv) async {
          final p =
              inv.positionalArguments.first as GetLogsForDateParams;
          final base = DateTime(p.date.year, p.date.month, p.date.day);
          if (p.date.day == 10) {
            return right(<DoseLog>[
              _log(id: '10-t', scheduledAt: base.add(const Duration(hours: 9)), status: DoseStatus.taken),
            ]);
          } else if (p.date.day == 9) {
            return right(<DoseLog>[
              _log(id: '9-m', scheduledAt: base.add(const Duration(hours: 9)), status: DoseStatus.missed),
            ]);
          } else if (p.date.day == 8) {
            return right(<DoseLog>[
              _log(id: '8-t', scheduledAt: base.add(const Duration(hours: 9)), status: DoseStatus.taken),
            ]);
          }
          return right(<DoseLog>[]);
        },
      );

      final result = await usecase(AdherenceRangeParams(
        profileId: 'p1',
        range: AdherenceRange.week,
        now: now,
      ));

      result.fold(
        (_) => fail('expected Right'),
        (summary) {
          expect(summary.streakDays, 1);
        },
      );
    });

    test('returns Failure when repository fails', () async {
      when(() => repo.getDoseLogsForDate(any())).thenAnswer(
        (_) async => left(const CacheFailure('boom')),
      );

      final result = await usecase(AdherenceRangeParams(
        profileId: 'p1',
        range: AdherenceRange.week,
        now: now,
      ));

      expect(result.isLeft(), isTrue);
    });
  });
}
