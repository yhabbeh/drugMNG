import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/usecases/inventory_params.dart';
import 'package:drug/features/inventory/presentation/bloc/inventory_bloc.dart';

class StockAdjustSheet extends StatefulWidget {
  const StockAdjustSheet({super.key, required this.medication});

  final Medication medication;

  @override
  State<StockAdjustSheet> createState() => _StockAdjustSheetState();
}

class _StockAdjustSheetState extends State<StockAdjustSheet> {
  late final TextEditingController _controller;
  int _adjustment = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Adjust Stock: ${widget.medication.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text('Current stock: ${widget.medication.currentStock}'),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton.filled(
                onPressed: () {
                  setState(() => _adjustment--);
                  _controller.text = _adjustment.toString();
                },
                icon: const Icon(Icons.remove),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '0',
                  ),
                  onChanged: (value) {
                    _adjustment = int.tryParse(value) ?? 0;
                  },
                ),
              ),
              const SizedBox(width: 16),
              IconButton.filled(
                onPressed: () {
                  setState(() => _adjustment++);
                  _controller.text = _adjustment.toString();
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'New stock will be: ${widget.medication.currentStock + _adjustment}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _adjustment == 0
                ? null
                : () {
                    context.read<InventoryBloc>().add(
                      MedicationStockAdjusted(
                        UpdateStockParams(
                          medicationId: widget.medication.id,
                          quantityChange: _adjustment,
                          reason: 'Manual adjustment',
                        ),
                      ),
                    );
                    Navigator.of(context).pop();
                  },
            child: const Text('Apply Adjustment'),
          ),
        ],
      ),
    );
  }
}

Future<void> showStockAdjustSheet(
  BuildContext context,
  Medication medication,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => StockAdjustSheet(medication: medication),
  );
}
