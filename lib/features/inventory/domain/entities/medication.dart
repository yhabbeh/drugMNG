import 'package:equatable/equatable.dart';

import 'package:drug/features/inventory/domain/value_objects/enums.dart';

const Object _sentinel = Object();

final class Medication extends Equatable {
  const Medication({
    required this.id,
    required this.name,
    required this.drugForm,
    this.profileId,
    this.dosageAmount,
    this.dosageUnit,
    this.notes,
    required this.currentStock,
    this.refillThreshold,
    required this.expirationDate,
    this.manufacturer,
    this.batchNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final DrugForm drugForm;
  final String? profileId;
  final double? dosageAmount;
  final DosageUnit? dosageUnit;
  final String? notes;
  final int currentStock;
  final int? refillThreshold;
  final DateTime expirationDate;
  final String? manufacturer;
  final String? batchNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medication copyWith({
    String? id,
    String? name,
    DrugForm? drugForm,
    Object? profileId = _sentinel,
    double? dosageAmount,
    DosageUnit? dosageUnit,
    String? notes,
    int? currentStock,
    int? refillThreshold,
    DateTime? expirationDate,
    String? manufacturer,
    String? batchNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      drugForm: drugForm ?? this.drugForm,
      profileId: identical(profileId, _sentinel)
          ? this.profileId
          : profileId as String?,
      dosageAmount: dosageAmount ?? this.dosageAmount,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      notes: notes ?? this.notes,
      currentStock: currentStock ?? this.currentStock,
      refillThreshold: refillThreshold ?? this.refillThreshold,
      expirationDate: expirationDate ?? this.expirationDate,
      manufacturer: manufacturer ?? this.manufacturer,
      batchNumber: batchNumber ?? this.batchNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        drugForm,
        profileId,
        dosageAmount,
        dosageUnit,
        notes,
        currentStock,
        refillThreshold,
        expirationDate,
        manufacturer,
        batchNumber,
        createdAt,
        updatedAt,
      ];
}
