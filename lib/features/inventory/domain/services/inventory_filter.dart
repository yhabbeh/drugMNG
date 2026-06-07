import 'package:equatable/equatable.dart';

import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/value_objects/enums.dart';

enum InventorySort {
  nameAsc('Name A → Z'),
  nameDesc('Name Z → A'),
  expirationAsc('Expiration: soonest'),
  stockAsc('Stock: low → high'),
  recentlyAdded('Recently added');

  const InventorySort(this.label);

  final String label;
}

class InventoryFilters extends Equatable {
  const InventoryFilters({
    this.query = '',
    this.formFilter = const <DrugForm>{},
    this.lowStockOnly = false,
    this.expiringSoonOnly = false,
    this.sort = InventorySort.nameAsc,
  });

  final String query;
  final Set<DrugForm> formFilter;
  final bool lowStockOnly;
  final bool expiringSoonOnly;
  final InventorySort sort;

  bool get isActive =>
      query.isNotEmpty ||
      formFilter.isNotEmpty ||
      lowStockOnly ||
      expiringSoonOnly;

  bool get isDefault => !isActive && sort == InventorySort.nameAsc;

  int get activeChipCount =>
      formFilter.length + (lowStockOnly ? 1 : 0) + (expiringSoonOnly ? 1 : 0);

  InventoryFilters copyWith({
    String? query,
    Set<DrugForm>? formFilter,
    bool? lowStockOnly,
    bool? expiringSoonOnly,
    InventorySort? sort,
  }) {
    return InventoryFilters(
      query: query ?? this.query,
      formFilter: formFilter ?? this.formFilter,
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
      expiringSoonOnly: expiringSoonOnly ?? this.expiringSoonOnly,
      sort: sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => [
        query,
        formFilter,
        lowStockOnly,
        expiringSoonOnly,
        sort,
      ];
}

class InventoryFilter {
  const InventoryFilter();

  List<Medication> apply(List<Medication> source, InventoryFilters f) {
    final filtered = _filter(source, f);
    return _sort(filtered, f.sort);
  }

  List<Medication> _filter(List<Medication> source, InventoryFilters f) {
    final query = f.query.trim().toLowerCase();
    return source.where((m) {
      if (query.isNotEmpty) {
        final inName = m.name.toLowerCase().contains(query);
        final inManufacturer =
            (m.manufacturer ?? '').toLowerCase().contains(query);
        final inNotes = (m.notes ?? '').toLowerCase().contains(query);
        if (!inName && !inManufacturer && !inNotes) return false;
      }
      if (f.formFilter.isNotEmpty && !f.formFilter.contains(m.drugForm)) {
        return false;
      }
      if (f.lowStockOnly && !_isLowStock(m)) return false;
      if (f.expiringSoonOnly && !_isExpiringSoon(m)) return false;
      return true;
    }).toList();
  }

  List<Medication> _sort(List<Medication> source, InventorySort sort) {
    final copy = List<Medication>.from(source);
    switch (sort) {
      case InventorySort.nameAsc:
        copy.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case InventorySort.nameDesc:
        copy.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      case InventorySort.expirationAsc:
        copy.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
      case InventorySort.stockAsc:
        copy.sort((a, b) => a.currentStock.compareTo(b.currentStock));
      case InventorySort.recentlyAdded:
        copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return copy;
  }

  static bool _isLowStock(Medication m) {
    final threshold = m.refillThreshold;
    if (threshold == null) return false;
    return m.currentStock <= threshold;
  }

  static bool _isExpiringSoon(Medication m) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(
      m.expirationDate.year,
      m.expirationDate.month,
      m.expirationDate.day,
    );
    return expiry.difference(today).inDays <= 30;
  }
}
