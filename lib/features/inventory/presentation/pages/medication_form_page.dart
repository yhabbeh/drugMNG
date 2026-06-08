import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/value_objects/enums.dart';
import 'package:drug/features/inventory/presentation/bloc/inventory_bloc.dart';

class MedicationFormPage extends StatefulWidget {
  const MedicationFormPage({super.key, this.medication});

  final Medication? medication;

  @override
  State<MedicationFormPage> createState() => _MedicationFormPageState();
}

class _MedicationFormPageState extends State<MedicationFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageAmountController;
  late final TextEditingController _notesController;
  late final TextEditingController _stockController;
  late final TextEditingController _refillThresholdController;
  late final TextEditingController _estimatedDosesPerDayController;
  late final TextEditingController _manufacturerController;
  late final TextEditingController _batchNumberController;
  late DrugForm _drugForm;
  late DosageUnit? _dosageUnit;
  late DateTime _expirationDate;
  bool _datePicked = false;

  bool get _isEditing => widget.medication != null;

  @override
  void initState() {
    super.initState();
    final med = widget.medication;
    _nameController = TextEditingController(text: med?.name ?? '');
    _dosageAmountController = TextEditingController(
      text: med?.dosageAmount?.toString() ?? '',
    );
    _notesController = TextEditingController(text: med?.notes ?? '');
    _stockController = TextEditingController(
      text: (med?.currentStock ?? 0).toString(),
    );
    _refillThresholdController = TextEditingController(
      text: med?.refillThreshold?.toString() ?? '',
    );
    _estimatedDosesPerDayController = TextEditingController(
      text: med?.estimatedDosesPerDay?.toString() ?? '',
    );
    _manufacturerController = TextEditingController(text: med?.manufacturer ?? '');
    _batchNumberController = TextEditingController(text: med?.batchNumber ?? '');
    _drugForm = med?.drugForm ?? DrugForm.tablet;
    _dosageUnit = med?.dosageUnit;
    _expirationDate = med?.expirationDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageAmountController.dispose();
    _notesController.dispose();
    _stockController.dispose();
    _refillThresholdController.dispose();
    _estimatedDosesPerDayController.dispose();
    _manufacturerController.dispose();
    _batchNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? 'Edit Medication' : 'Add Medication';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<DrugForm>(
                initialValue: _drugForm,
                decoration: const InputDecoration(
                  labelText: 'Drug Form',
                  border: OutlineInputBorder(),
                ),
                items: DrugForm.values.map((f) {
                  return DropdownMenuItem(value: f, child: Text(f.name));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _drugForm = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dosageAmountController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage Amount',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<DosageUnit>(
                      initialValue: _dosageUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: DosageUnit.values.map((u) {
                        return DropdownMenuItem(value: u, child: Text(u.name));
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _dosageUnit = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Current Stock',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value.trim()) == null) {
                          return 'Must be a number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _refillThresholdController,
                      decoration: const InputDecoration(
                        labelText: 'Refill Threshold',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expiration Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _datePicked
                        ? '${_expirationDate.month}/${_expirationDate.day}/${_expirationDate.year}'
                        : (_isEditing
                            ? '${_expirationDate.month}/${_expirationDate.day}/${_expirationDate.year}'
                            : 'Tap to select'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _estimatedDosesPerDayController,
                decoration: const InputDecoration(
                  labelText: 'Estimated Doses Per Day (optional, for PRN)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _manufacturerController,
                decoration: const InputDecoration(
                  labelText: 'Manufacturer (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _batchNumberController,
                decoration: const InputDecoration(
                  labelText: 'Batch Number (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submit,
                child: Text(_isEditing ? 'Save Changes' : 'Add Medication'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expirationDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (date != null) {
      setState(() {
        _expirationDate = date;
        _datePicked = true;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final med = widget.medication;

    final medication = Medication(
      id: med?.id ?? '',
      name: _nameController.text.trim(),
      drugForm: _drugForm,
      profileId: med?.profileId,
      dosageAmount: double.tryParse(_dosageAmountController.text.trim()),
      dosageUnit: _dosageUnit,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      currentStock: int.parse(_stockController.text.trim()),
      refillThreshold: int.tryParse(_refillThresholdController.text.trim()),
      estimatedDosesPerDay: double.tryParse(_estimatedDosesPerDayController.text.trim()),
      expirationDate: _expirationDate,
      manufacturer: _manufacturerController.text.trim().isEmpty
          ? null
          : _manufacturerController.text.trim(),
      batchNumber: _batchNumberController.text.trim().isEmpty
          ? null
          : _batchNumberController.text.trim(),
      createdAt: med?.createdAt ?? now,
      updatedAt: now,
    );

    if (_isEditing) {
      context.read<InventoryBloc>().add(MedicationUpdated(medication));
    } else {
      context.read<InventoryBloc>().add(MedicationAdded(medication));
    }
    context.pop();
  }
}
