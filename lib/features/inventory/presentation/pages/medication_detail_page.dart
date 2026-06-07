import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:drug/core/router/app_routes.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:drug/features/inventory/presentation/pages/stock_adjust_sheet.dart';

class MedicationDetailPage extends StatelessWidget {
  const MedicationDetailPage({super.key, required this.medication});

  final Medication medication;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDate = DateTime(medication.expirationDate.year, medication.expirationDate.month, medication.expirationDate.day);
    final daysUntilExpiry = expiryDate.difference(today).inDays;
    final isLowStock = medication.refillThreshold != null &&
        medication.currentStock <= medication.refillThreshold!;

    return Scaffold(
      appBar: AppBar(
        title: Text(medication.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(
              AppRoutes.inventoryForm,
              extra: medication,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoTile(label: 'Drug Form', value: medication.drugForm.name),
          if (medication.dosageAmount != null)
            _InfoTile(
              label: 'Dosage',
              value: '${medication.dosageAmount} ${medication.dosageUnit?.name ?? ''}',
            ),
          _StockCard(
            currentStock: medication.currentStock,
            refillThreshold: medication.refillThreshold,
            isLowStock: isLowStock,
            onAdjust: () => showStockAdjustSheet(context, medication),
          ),
          _ExpiryCard(daysUntilExpiry: daysUntilExpiry, date: medication.expirationDate),
          if (medication.notes != null && medication.notes!.isNotEmpty)
            _InfoTile(label: 'Notes', value: medication.notes!),
          if (medication.manufacturer != null)
            _InfoTile(label: 'Manufacturer', value: medication.manufacturer!),
          if (medication.batchNumber != null)
            _InfoTile(label: 'Batch Number', value: medication.batchNumber!),
          _InfoTile(
            label: 'Created',
            value: _formatDate(medication.createdAt),
          ),
          _InfoTile(
            label: 'Last Updated',
            value: _formatDate(medication.updatedAt),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete "${medication.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<InventoryBloc>().add(
                MedicationDeleted(medication.id),
              );
              context.pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

final class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

final class _StockCard extends StatelessWidget {
  const _StockCard({
    required this.currentStock,
    required this.refillThreshold,
    required this.isLowStock,
    required this.onAdjust,
  });

  final int currentStock;
  final int? refillThreshold;
  final bool isLowStock;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Stock', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: onAdjust,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Adjust'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$currentStock units',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: isLowStock ? Colors.red : null,
              ),
            ),
            if (refillThreshold != null)
              Text(
                'Refill when below: $refillThreshold',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

final class _ExpiryCard extends StatelessWidget {
  const _ExpiryCard({required this.daysUntilExpiry, required this.date});

  final int daysUntilExpiry;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final color = daysUntilExpiry <= 7
        ? Colors.red
        : daysUntilExpiry <= 30
            ? Colors.orange
            : Colors.green;
    final status = daysUntilExpiry <= 0
        ? 'Expired'
        : daysUntilExpiry <= 7
            ? 'Expiring soon'
            : daysUntilExpiry <= 30
                ? 'Expiring this month'
                : 'Valid';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.event, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expiration: ${date.month}/${date.day}/${date.year}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  status,
                  style: TextStyle(color: color, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
