import 'package:flutter/material.dart';

import 'package:drug/features/inventory/domain/services/inventory_filter.dart';
import 'package:drug/features/inventory/domain/value_objects/enums.dart';

class InventoryFilterChips extends StatelessWidget {
  const InventoryFilterChips({
    super.key,
    required this.filters,
    required this.onChanged,
  });

  final InventoryFilters filters;
  final ValueChanged<InventoryFilters> onChanged;

  void _toggleForm(DrugForm form) {
    final next = Set<DrugForm>.from(filters.formFilter);
    if (next.contains(form)) {
      next.remove(form);
    } else {
      next.add(form);
    }
    onChanged(filters.copyWith(formFilter: next));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ...DrugForm.values.map(
            (form) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: FilterChip(
                label: Text(_formLabel(form)),
                selected: filters.formFilter.contains(form),
                onSelected: (_) => _toggleForm(form),
                avatar: Icon(
                  _formIcon(form),
                  size: 16,
                  color: filters.formFilter.contains(form)
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 16, indent: 8, endIndent: 8),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: const Text('Low stock'),
              selected: filters.lowStockOnly,
              onSelected: (v) =>
                  onChanged(filters.copyWith(lowStockOnly: v)),
              avatar: const Icon(Icons.warning_amber_rounded, size: 16),
            ),
          ),
          FilterChip(
            label: const Text('Expiring soon'),
            selected: filters.expiringSoonOnly,
            onSelected: (v) =>
                onChanged(filters.copyWith(expiringSoonOnly: v)),
            avatar: const Icon(Icons.schedule, size: 16),
          ),
        ],
      ),
    );
  }

  String _formLabel(DrugForm form) {
    switch (form) {
      case DrugForm.tablet:
        return 'Tablet';
      case DrugForm.capsule:
        return 'Capsule';
      case DrugForm.liquid:
        return 'Liquid';
      case DrugForm.inhaler:
        return 'Inhaler';
      case DrugForm.patch:
        return 'Patch';
      case DrugForm.injection:
        return 'Injection';
      case DrugForm.topical:
        return 'Topical';
      case DrugForm.drops:
        return 'Drops';
      case DrugForm.other:
        return 'Other';
    }
  }

  IconData _formIcon(DrugForm form) {
    switch (form) {
      case DrugForm.tablet:
      case DrugForm.capsule:
        return Icons.medication_outlined;
      case DrugForm.liquid:
        return Icons.local_drink_outlined;
      case DrugForm.inhaler:
        return Icons.air;
      case DrugForm.patch:
        return Icons.healing;
      case DrugForm.injection:
        return Icons.colorize;
      case DrugForm.topical:
        return Icons.spa_outlined;
      case DrugForm.drops:
        return Icons.water_drop_outlined;
      case DrugForm.other:
        return Icons.medical_services_outlined;
    }
  }
}
