import 'package:flutter/material.dart';

import 'package:drug/features/inventory/domain/services/inventory_filter.dart';

class InventorySortMenu extends StatelessWidget {
  const InventorySortMenu({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final InventorySort current;
  final ValueChanged<InventorySort> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<InventorySort>(
      tooltip: 'Sort',
      icon: const Icon(Icons.sort),
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final sort in InventorySort.values)
          PopupMenuItem<InventorySort>(
            value: sort,
            child: Row(
              children: [
                Icon(
                  sort == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                  color: sort == current
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(sort.label),
              ],
            ),
          ),
      ],
    );
  }
}
