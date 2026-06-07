import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:drug/core/router/app_routes.dart';
import 'package:drug/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/services/inventory_filter.dart';
import 'package:drug/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:drug/features/inventory/presentation/cubit/expiration_warning_cubit.dart';
import 'package:drug/features/inventory/presentation/widgets/inventory_filter_chips.dart';
import 'package:drug/features/inventory/presentation/widgets/inventory_search_bar.dart';
import 'package:drug/features/inventory/presentation/widgets/inventory_sort_menu.dart';

class InventoryListPage extends StatefulWidget {
  const InventoryListPage({super.key});

  @override
  State<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends State<InventoryListPage> {
  static const _filter = InventoryFilter();

  InventoryFilters _filters = const InventoryFilters();

  @override
  void initState() {
    super.initState();
    context.read<InventoryBloc>().add(const MedicationsStarted());
    context.read<ExpirationWarningCubit>().refresh();
  }

  void _onFiltersChanged(InventoryFilters next) {
    setState(() => _filters = next);
  }

  void _clearFilters() {
    setState(() => _filters = const InventoryFilters());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          InventorySortMenu(
            current: _filters.sort,
            onChanged: (sort) =>
                _onFiltersChanged(_filters.copyWith(sort: sort)),
          ),
          if (_filters.isActive)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_outlined),
              tooltip: 'Clear filters',
              onPressed: _clearFilters,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.inventoryForm),
        child: const Icon(Icons.add),
      ),
      body: BlocListener<InventoryBloc, InventoryState>(
        listener: (context, state) {
          if (state is InventoryLoaded) {
            context.read<ExpirationWarningCubit>().refresh();
          }
        },
        child: BlocBuilder<InventoryBloc, InventoryState>(
          builder: (context, state) {
            return switch (state) {
              InventoryInitial() =>
                const Center(child: CircularProgressIndicator()),
              InventoryLoading() =>
                const Center(child: CircularProgressIndicator()),
              InventoryLoaded(:final medications, :final isLoading) =>
                _buildBody(context, medications, isLoading: isLoading),
              InventoryError(:final failure) =>
                Center(child: Text('Error: ${failure.message}')),
            };
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<Medication> medications, {
    bool isLoading = false,
  }) {
    if (medications.isEmpty) {
      return Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.medication_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No medications yet',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => context.push(AppRoutes.inventoryForm),
                  child: const Text('Add Medication'),
                ),
              ],
            ),
          ),
          const _ExpiryBanner(),
        ],
      );
    }

    final filtered = _filter.apply(medications, _filters);

    return Stack(
      children: [
        Column(
          children: [
            const _ExpiryBanner(),
            InventorySearchBar(
              initialValue: _filters.query,
              onChanged: (q) => _onFiltersChanged(_filters.copyWith(query: q)),
            ),
            InventoryFilterChips(
              filters: _filters,
              onChanged: _onFiltersChanged,
            ),
            _FilterSummary(
              filtered: filtered.length,
              total: medications.length,
              filters: _filters,
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _NoMatchesView(filters: _filters)
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 88),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final medication = filtered[index];
                        return _MedicationCard(
                          medication: medication,
                          onTap: () => context.push(
                            '${AppRoutes.inventory}/detail',
                            extra: medication,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        if (isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}

class _FilterSummary extends StatelessWidget {
  const _FilterSummary({
    required this.filtered,
    required this.total,
    required this.filters,
  });

  final int filtered;
  final int total;
  final InventoryFilters filters;

  @override
  Widget build(BuildContext context) {
    if (filters.isDefault) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            'Showing $filtered of $total',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _NoMatchesView extends StatelessWidget {
  const _NoMatchesView({required this.filters});

  final InventoryFilters filters;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final query = filters.query.trim();
    final message = query.isNotEmpty
        ? 'No matches for "$query"'
        : 'No medications match your filters';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ExpiryBanner extends StatelessWidget {
  const _ExpiryBanner();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpirationWarningCubit, ExpirationWarningState>(
      builder: (context, state) {
        if (state is! ExpirationWarningLoaded) return const SizedBox.shrink();
        if (state.criticalCount == 0 && state.warningCount == 0) {
          return const SizedBox.shrink();
        }
        final color = state.criticalCount > 0 ? Colors.red : Colors.orange;
        final text = state.criticalCount > 0
            ? '${state.criticalCount} medication(s) expiring soon!'
            : '${state.warningCount} medication(s) expiring this month';
        return MaterialBanner(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: color.shade50,
          leading: Icon(Icons.warning_amber_rounded, color: color),
          content: Text(text, style: TextStyle(color: color.shade700)),
          actions: [
            TextButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) =>
                      ExpiryBottomSheet(warnings: state.warnings),
                );
              },
              child: const Text('View All'),
            ),
          ],
        );
      },
    );
  }
}

final class _MedicationCard extends StatelessWidget {
  const _MedicationCard({
    required this.medication,
    required this.onTap,
  });

  final Medication medication;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDate = DateTime(medication.expirationDate.year,
        medication.expirationDate.month, medication.expirationDate.day);
    final daysUntilExpiry = expiryDate.difference(today).inDays;
    final isExpired = daysUntilExpiry < 0;
    final isExpiring = daysUntilExpiry <= 30;
    final isLowStock = medication.refillThreshold != null &&
        medication.currentStock <= medication.refillThreshold!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        selectedColor: isExpired ? Colors.red : null,
        leading: CircleAvatar(
          backgroundColor: isExpired
              ? Colors.red.shade100
              : isExpiring
                  ? Colors.orange.shade100
                  : Colors.teal.shade100,
          child: Icon(
            Icons.medication,
            color: isExpired
                ? Colors.red
                : isExpiring
                    ? Colors.orange
                    : Colors.teal,
          ),
        ),
        title: Text(medication.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(medication.drugForm.name),
            const SizedBox(height: 4),
            Row(
              children: [
                _Badge(
                  label: 'Stock: ${medication.currentStock}',
                  color: isLowStock ? Colors.red : Colors.green,
                ),
                if (isExpired) ...[
                  const SizedBox(width: 8),
                  const _Badge(
                    label: 'Expired',
                    color: Colors.red,
                  ),
                ] else if (isExpiring) ...[
                  const SizedBox(width: 8),
                  _Badge(
                    label: '$daysUntilExpiry days',
                    color: Colors.orange,
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

final class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final MaterialColor color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color.shade700),
      ),
    );
  }
}
