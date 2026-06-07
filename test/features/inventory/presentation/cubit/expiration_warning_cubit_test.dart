import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/inventory/domain/entities/expiration_warning.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/usecases/get_expiring_medications.dart';
import 'package:drug/features/inventory/domain/usecases/inventory_params.dart';
import 'package:drug/features/inventory/domain/value_objects/enums.dart';
import 'package:drug/features/inventory/presentation/cubit/expiration_warning_cubit.dart';

class MockGetExpiringMedications extends Mock
    implements GetExpiringMedications {}

void main() {
  late MockGetExpiringMedications mockGetExpiringMedications;
  late ExpirationWarningCubit cubit;

  setUpAll(() {
    registerFallbackValue(const ExpiringParams(withinDays: 90));
  });

  setUp(() {
    mockGetExpiringMedications = MockGetExpiringMedications();
    cubit = ExpirationWarningCubit(
      getExpiringMedications: mockGetExpiringMedications,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('ExpirationWarningCubit', () {
    test('emits initial state on creation', () {
      expect(cubit.state, isA<ExpirationWarningInitial>());
    });

    Future<void> testRefresh({
      required List<ExpirationWarning> warnings,
      required int expectedCritical,
      required int expectedWarning,
      required int expectedInfo,
      int withinDays = 90,
    }) async {
      when(() => mockGetExpiringMedications(any())).thenAnswer(
        (_) async => Right<Failure, List<ExpirationWarning>>(warnings),
      );

      await cubit.refresh(withinDays: withinDays);

      final state = cubit.state as ExpirationWarningLoaded;
      expect(state.warnings.length, warnings.length);
      expect(state.criticalCount, expectedCritical);
      expect(state.warningCount, expectedWarning);
      expect(state.infoCount, expectedInfo);
    }

    test('emits loaded state with grouped counts', () async {
      await testRefresh(
        warnings: [
          ExpirationWarning(
            medication: Medication(
              id: '1',
              name: 'Critical Med',
              drugForm: DrugForm.tablet,
              currentStock: 10,
              expirationDate: DateTime.now().add(const Duration(days: 3)),
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
            ),
            daysUntilExpiry: 3,
            severity: ExpirationSeverity.critical,
          ),
          ExpirationWarning(
            medication: Medication(
              id: '2',
              name: 'Warning Med',
              drugForm: DrugForm.capsule,
              currentStock: 20,
              expirationDate: DateTime.now().add(const Duration(days: 14)),
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
            ),
            daysUntilExpiry: 14,
            severity: ExpirationSeverity.warning,
          ),
          ExpirationWarning(
            medication: Medication(
              id: '3',
              name: 'Info Med',
              drugForm: DrugForm.liquid,
              currentStock: 5,
              expirationDate: DateTime.now().add(const Duration(days: 60)),
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
            ),
            daysUntilExpiry: 60,
            severity: ExpirationSeverity.info,
          ),
        ],
        expectedCritical: 1,
        expectedWarning: 1,
        expectedInfo: 1,
      );
    });

    test('emits loaded state with all critical warnings', () async {
      await testRefresh(
        warnings: [
          ExpirationWarning(
            medication: Medication(
              id: '1',
              name: 'Med A',
              drugForm: DrugForm.tablet,
              currentStock: 10,
              expirationDate: DateTime.now().add(const Duration(days: 1)),
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
            ),
            daysUntilExpiry: 1,
            severity: ExpirationSeverity.critical,
          ),
          ExpirationWarning(
            medication: Medication(
              id: '2',
              name: 'Med B',
              drugForm: DrugForm.capsule,
              currentStock: 5,
              expirationDate: DateTime.now().add(const Duration(days: 5)),
              createdAt: DateTime(2025, 1, 1),
              updatedAt: DateTime(2025, 1, 1),
            ),
            daysUntilExpiry: 5,
            severity: ExpirationSeverity.critical,
          ),
        ],
        expectedCritical: 2,
        expectedWarning: 0,
        expectedInfo: 0,
      );
    });

    test('emits empty loaded state on error', () async {
      when(() => mockGetExpiringMedications(any())).thenAnswer(
        (_) async => const Left<Failure, List<ExpirationWarning>>(
          CacheFailure('Failed'),
        ),
      );

      await cubit.refresh();

      final state = cubit.state as ExpirationWarningLoaded;
      expect(state.warnings, isEmpty);
      expect(state.criticalCount, 0);
      expect(state.warningCount, 0);
      expect(state.infoCount, 0);
    });

    test('refresh uses default withinDays of 90', () async {
      when(() => mockGetExpiringMedications(any())).thenAnswer(
        (_) async => const Right<Failure, List<ExpirationWarning>>([]),
      );

      await cubit.refresh();

      verify(
        () => mockGetExpiringMedications(
          const ExpiringParams(withinDays: 90),
        ),
      ).called(1);
    });

    test('refresh uses custom withinDays', () async {
      when(() => mockGetExpiringMedications(any())).thenAnswer(
        (_) async => const Right<Failure, List<ExpirationWarning>>([]),
      );

      await cubit.refresh(withinDays: 7);

      verify(
        () => mockGetExpiringMedications(
          const ExpiringParams(withinDays: 7),
        ),
      ).called(1);
    });
  });
}
