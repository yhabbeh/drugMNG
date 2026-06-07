import 'package:bloc_test/bloc_test.dart';
import 'package:drug/core/error/failures.dart';
import 'package:drug/features/adherence/domain/entities/adherence_range.dart';
import 'package:drug/features/adherence/domain/entities/adherence_summary.dart';
import 'package:drug/features/adherence/domain/entities/daily_adherence_point.dart';
import 'package:drug/features/adherence/domain/usecases/get_adherence_summary.dart';
import 'package:drug/features/adherence/domain/usecases/get_missed_doses.dart';
import 'package:drug/features/adherence/presentation/bloc/adherence_bloc.dart';
import 'package:drug/features/adherence/presentation/bloc/adherence_event.dart';
import 'package:drug/features/adherence/presentation/bloc/adherence_state.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetAdherenceSummary extends Mock implements GetAdherenceSummary {}

class _MockGetMissedDoses extends Mock implements GetMissedDoses {}

AdherenceSummary _summary(AdherenceRange range) {
  return AdherenceSummary(
    range: range,
    taken: 5,
    skipped: 1,
    missed: 0,
    pending: 0,
    streakDays: 3,
    dailyPoints: const [],
  );
}

void main() {
  late _MockGetAdherenceSummary getSummary;
  late _MockGetMissedDoses getMissed;
  late AdherenceBloc bloc;

  setUpAll(() {
    registerFallbackValue(
      const AdherenceRangeParams(profileId: '', range: AdherenceRange.week),
    );
    registerFallbackValue(
      GetLogsForDateParams(
        profileId: '',
        date: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
  });

  setUp(() {
    getSummary = _MockGetAdherenceSummary();
    getMissed = _MockGetMissedDoses();
    when(() => getSummary(any())).thenAnswer(
      (_) async => right(_summary(AdherenceRange.week)),
    );
    when(() => getMissed(any())).thenAnswer(
      (_) async => right([]),
    );
    bloc = AdherenceBloc(
      getAdherenceSummary: getSummary,
      getMissedDoses: getMissed,
    );
  });

  test('initial state is AdherenceInitial', () {
    expect(bloc.state, isA<AdherenceInitial>());
  });

  blocTest<AdherenceBloc, AdherenceState>(
    'emits [Loading, Loaded] when AdherenceStarted succeeds',
    build: () => bloc,
    act: (b) => b.add(
      const AdherenceStarted(profileId: 'p1', range: AdherenceRange.week),
    ),
    expect: () => [
      isA<AdherenceLoading>(),
      isA<AdherenceLoaded>(),
    ],
  );

  blocTest<AdherenceBloc, AdherenceState>(
    'AdherenceRangeChanged reloads with new range',
    build: () {
      when(() => getSummary(any())).thenAnswer(
        (inv) async {
          final p = inv.positionalArguments.first as AdherenceRangeParams;
          return right(_summary(p.range));
        },
      );
      return bloc;
    },
    act: (b) async {
      b.add(const AdherenceStarted(profileId: 'p1'));
      await Future<void>.delayed(Duration.zero);
      b.add(const AdherenceRangeChanged(AdherenceRange.month));
    },
    skip: 2,
    expect: () => [
      isA<AdherenceLoading>().having((s) => s.range, 'range', AdherenceRange.month),
      isA<AdherenceLoaded>().having((s) => s.range, 'range', AdherenceRange.month),
    ],
  );

  blocTest<AdherenceBloc, AdherenceState>(
    'emits AdherenceError when summary fails',
    build: () {
      when(() => getSummary(any())).thenAnswer(
        (_) async => left(const CacheFailure('oops')),
      );
      return AdherenceBloc(
        getAdherenceSummary: getSummary,
        getMissedDoses: getMissed,
      );
    },
    act: (b) => b.add(const AdherenceStarted(profileId: 'p1')),
    expect: () => [
      isA<AdherenceLoading>(),
      isA<AdherenceError>().having((e) => e.message, 'message', 'oops'),
    ],
  );

  blocTest<AdherenceBloc, AdherenceState>(
    'AdherenceRefreshed reloads with current range',
    build: () => bloc,
    act: (b) async {
      b.add(const AdherenceStarted(profileId: 'p1', range: AdherenceRange.month));
      await Future<void>.delayed(Duration.zero);
      b.add(const AdherenceRefreshed());
    },
    skip: 2,
    expect: () => [
      isA<AdherenceLoading>(),
      isA<AdherenceLoaded>(),
    ],
  );

  test('DailyAdherencePoint equality works', () {
    final d = DateTime(2025, 1, 1);
    expect(
      DailyAdherencePoint(date: d, taken: 1, skipped: 0, missed: 0, pending: 0),
      equals(DailyAdherencePoint(date: d, taken: 1, skipped: 0, missed: 0, pending: 0)),
    );
  });

  test('AdherenceSummary adherencePercent 0 when no logs', () {
    final s = AdherenceSummary(
      range: AdherenceRange.week,
      taken: 0,
      skipped: 0,
      missed: 0,
      pending: 0,
      streakDays: 0,
      dailyPoints: const [],
    );
    expect(s.adherencePercent, 0);
    expect(s.total, 0);
    expect(s.logged, 0);
  });
}
