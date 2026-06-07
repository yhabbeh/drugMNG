import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/services/inventory_filter.dart';
import 'package:drug/features/inventory/domain/value_objects/enums.dart';
import 'package:flutter_test/flutter_test.dart';

Medication _m({
  required String id,
  required String name,
  DrugForm form = DrugForm.tablet,
  int stock = 30,
  int? threshold = 10,
  DateTime? expires,
  DateTime? created,
  String? manufacturer,
  String? notes,
}) {
  return Medication(
    id: id,
    name: name,
    drugForm: form,
    currentStock: stock,
    refillThreshold: threshold,
    expirationDate: expires ?? DateTime(2027, 1, 1),
    createdAt: created ?? DateTime(2025, 1, 1),
    updatedAt: created ?? DateTime(2025, 1, 1),
    manufacturer: manufacturer,
    notes: notes,
  );
}

void main() {
  const filter = InventoryFilter();
  final base = DateTime(2026, 6, 10);

  group('InventoryFilters', () {
    test('isDefault when no filters and sort is nameAsc', () {
      expect(const InventoryFilters().isDefault, isTrue);
      expect(const InventoryFilters().isActive, isFalse);
      expect(const InventoryFilters().activeChipCount, 0);
    });

    test('isActive flips true on any filter', () {
      expect(
        const InventoryFilters(query: 'aspirin').isActive,
        isTrue,
      );
      expect(
        const InventoryFilters(formFilter: {DrugForm.tablet}).isActive,
        isTrue,
      );
      expect(const InventoryFilters(lowStockOnly: true).isActive, isTrue);
      expect(const InventoryFilters(expiringSoonOnly: true).isActive, isTrue);
    });

    test('activeChipCount counts formFilter + 2 booleans', () {
      const f = InventoryFilters(
        formFilter: {DrugForm.tablet, DrugForm.capsule},
        lowStockOnly: true,
        expiringSoonOnly: false,
      );
      expect(f.activeChipCount, 3);
    });

    test('copyWith preserves untouched fields', () {
      const f = InventoryFilters(sort: InventorySort.stockAsc);
      final f2 = f.copyWith(query: 'ibuprofen');
      expect(f2.sort, InventorySort.stockAsc);
      expect(f2.query, 'ibuprofen');
    });
  });

  group('InventoryFilter.apply', () {
    final sample = [
      _m(id: '1', name: 'Aspirin', form: DrugForm.tablet, stock: 50),
      _m(id: '2', name: 'Ibuprofen', form: DrugForm.capsule, stock: 5),
      _m(
        id: '3',
        name: 'Ventolin',
        form: DrugForm.inhaler,
        stock: 2,
        expires: base.add(const Duration(days: 10)),
      ),
      _m(
        id: '4',
        name: 'Cough Syrup',
        form: DrugForm.liquid,
        stock: 100,
        expires: base.add(const Duration(days: 365)),
      ),
      _m(
        id: '5',
        name: 'Tylenol',
        form: DrugForm.tablet,
        stock: 8,
        manufacturer: 'Acme Pharma',
        notes: 'For headache',
      ),
    ];

    test('returns the full list when filters are default', () {
      final result = filter.apply(sample, const InventoryFilters());
      expect(result.length, 5);
    });

    test('query matches name case-insensitively', () {
      final result = filter.apply(
        sample,
        const InventoryFilters(query: 'ibu'),
      );
      expect(result.map((m) => m.id), ['2']);
    });

    test('query matches manufacturer', () {
      final result = filter.apply(
        sample,
        const InventoryFilters(query: 'acme'),
      );
      expect(result.map((m) => m.id), ['5']);
    });

    test('query matches notes', () {
      final result = filter.apply(
        sample,
        const InventoryFilters(query: 'headache'),
      );
      expect(result.map((m) => m.id), ['5']);
    });

    test('query trims whitespace', () {
      final result = filter.apply(
        sample,
        const InventoryFilters(query: '  aspirin  '),
      );
      expect(result.map((m) => m.id), ['1']);
    });

    test('formFilter includes only matching forms', () {
      final result = filter.apply(
        sample,
        const InventoryFilters(
          formFilter: {DrugForm.tablet, DrugForm.inhaler},
        ),
      );
      expect(result.map((m) => m.id).toSet(), {'1', '3', '5'});
    });

    test('lowStockOnly uses refillThreshold', () {
      final result = filter.apply(
        sample,
        const InventoryFilters(lowStockOnly: true),
      );
      expect(result.map((m) => m.id).toSet(), {'2', '3', '5'});
    });

    test('lowStockOnly ignores meds without threshold', () {
      final noThreshold = _m(
        id: '99',
        name: 'Mystery',
        stock: 0,
        threshold: null,
      );
      final result = filter.apply(
        [...sample, noThreshold],
        const InventoryFilters(lowStockOnly: true),
      );
      expect(result.any((m) => m.id == '99'), isFalse);
    });

    test('expiringSoonOnly matches within 30 days from now', () {
      final result = filter.apply(
        sample,
        const InventoryFilters(expiringSoonOnly: true),
      );
      expect(result.map((m) => m.id), ['3']);
    });

    test('expiringSoonOnly includes already expired', () {
      final expired = _m(
        id: '6',
        name: 'Old',
        expires: base.subtract(const Duration(days: 5)),
      );
      final result = filter.apply(
        [...sample, expired],
        const InventoryFilters(expiringSoonOnly: true),
      );
      expect(result.any((m) => m.id == '6'), isTrue);
    });

    test('combines query + form + lowStock', () {
      final result = filter.apply(
        sample,
        const InventoryFilters(
          query: 'a',
          formFilter: {DrugForm.tablet},
          lowStockOnly: true,
        ),
      );
      expect(result.map((m) => m.id), ['5']);
    });

    group('sort', () {
      test('nameAsc (default)', () {
        final result = filter.apply(sample, const InventoryFilters());
        expect(result.first.name, 'Aspirin');
        expect(result.last.name, 'Ventolin');
      });

      test('nameDesc', () {
        final result = filter.apply(
          sample,
          const InventoryFilters(sort: InventorySort.nameDesc),
        );
        expect(result.first.name, 'Ventolin');
        expect(result.last.name, 'Aspirin');
      });

      test('expirationAsc puts soonest first', () {
        final result = filter.apply(
          sample,
          const InventoryFilters(sort: InventorySort.expirationAsc),
        );
        expect(result.first.id, '3');
      });

      test('stockAsc puts lowest first', () {
        final result = filter.apply(
          sample,
          const InventoryFilters(sort: InventorySort.stockAsc),
        );
        expect(result.first.id, '3');
        expect(result.last.id, '4');
      });

      test('recentlyAdded puts newest first', () {
        final withDates = [
          _m(id: '1', name: 'A', created: DateTime(2025, 1, 1)),
          _m(id: '2', name: 'B', created: DateTime(2025, 6, 1)),
          _m(id: '3', name: 'C', created: DateTime(2025, 12, 1)),
        ];
        final result = filter.apply(
          withDates,
          const InventoryFilters(sort: InventorySort.recentlyAdded),
        );
        expect(result.map((m) => m.id), ['3', '2', '1']);
      });
    });

    test('filter then sort: low-stock query results still sorted', () {
      final result = filter.apply(
        sample,
        const InventoryFilters(
          lowStockOnly: true,
          sort: InventorySort.nameAsc,
        ),
      );
      expect(result.map((m) => m.id), ['2', '5', '3']);
    });

    test('does not mutate the source list', () {
      final original = List<Medication>.from(sample);
      filter.apply(sample, const InventoryFilters(sort: InventorySort.nameDesc));
      expect(sample, original);
    });

    test('empty source returns empty', () {
      expect(
        filter.apply(const [], const InventoryFilters()),
        isEmpty,
      );
    });
  });
}
