import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/value_objects/enums.dart';

final class MedicationModel {
  const MedicationModel({
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
  final String drugForm;
  final String? profileId;
  final double? dosageAmount;
  final String? dosageUnit;
  final String? notes;
  final int currentStock;
  final int? refillThreshold;
  final DateTime expirationDate;
  final String? manufacturer;
  final String? batchNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      drugForm: json['drugForm'] as String,
      profileId: json['profileId'] as String?,
      dosageAmount: (json['dosageAmount'] as num?)?.toDouble(),
      dosageUnit: json['dosageUnit'] as String?,
      notes: json['notes'] as String?,
      currentStock: json['currentStock'] as int,
      refillThreshold: json['refillThreshold'] as int?,
      expirationDate: DateTime.parse(json['expirationDate'] as String),
      manufacturer: json['manufacturer'] as String?,
      batchNumber: json['batchNumber'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'drugForm': drugForm,
      'profileId': profileId,
      'dosageAmount': dosageAmount,
      'dosageUnit': dosageUnit,
      'notes': notes,
      'currentStock': currentStock,
      'refillThreshold': refillThreshold,
      'expirationDate': expirationDate.toIso8601String(),
      'manufacturer': manufacturer,
      'batchNumber': batchNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MedicationModel.fromDomain(Medication medication) {
    return MedicationModel(
      id: medication.id,
      name: medication.name,
      drugForm: medication.drugForm.name,
      profileId: medication.profileId,
      dosageAmount: medication.dosageAmount,
      dosageUnit: medication.dosageUnit?.name,
      notes: medication.notes,
      currentStock: medication.currentStock,
      refillThreshold: medication.refillThreshold,
      expirationDate: medication.expirationDate,
      manufacturer: medication.manufacturer,
      batchNumber: medication.batchNumber,
      createdAt: medication.createdAt,
      updatedAt: medication.updatedAt,
    );
  }

  Medication toDomain() {
    return Medication(
      id: id,
      name: name,
      drugForm: DrugForm.values.firstWhere((f) => f.name == drugForm),
      profileId: profileId,
      dosageAmount: dosageAmount,
      dosageUnit: dosageUnit != null
          ? DosageUnit.values.firstWhere((u) => u.name == dosageUnit)
          : null,
      notes: notes,
      currentStock: currentStock,
      refillThreshold: refillThreshold,
      expirationDate: expirationDate,
      manufacturer: manufacturer,
      batchNumber: batchNumber,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
