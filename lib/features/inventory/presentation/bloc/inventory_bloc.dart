import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/usecases/add_medication.dart';
import 'package:drug/features/inventory/domain/usecases/delete_medication.dart';
import 'package:drug/features/inventory/domain/usecases/inventory_params.dart';
import 'package:drug/features/inventory/domain/usecases/update_medication.dart';
import 'package:drug/features/inventory/domain/usecases/update_medication_stock.dart';
import 'package:drug/features/inventory/domain/usecases/watch_medications.dart';

sealed class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

final class MedicationsStarted extends InventoryEvent {
  const MedicationsStarted();
}

final class MedicationAdded extends InventoryEvent {
  const MedicationAdded(this.medication);
  final Medication medication;

  @override
  List<Object?> get props => [medication];
}

final class MedicationUpdated extends InventoryEvent {
  const MedicationUpdated(this.medication);
  final Medication medication;

  @override
  List<Object?> get props => [medication];
}

final class MedicationDeleted extends InventoryEvent {
  const MedicationDeleted(this.medicationId);
  final String medicationId;

  @override
  List<Object?> get props => [medicationId];
}

final class MedicationStockAdjusted extends InventoryEvent {
  const MedicationStockAdjusted(this.params);
  final UpdateStockParams params;

  @override
  List<Object?> get props => [params];
}

final class MedicationsRefreshRequested extends InventoryEvent {
  const MedicationsRefreshRequested();
}

sealed class InventoryState extends Equatable {
  const InventoryState();

  @override
  List<Object?> get props => [];
}

final class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

final class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

final class InventoryLoaded extends InventoryState {
  const InventoryLoaded({
    required this.medications,
    this.isLoading = false,
  });

  final List<Medication> medications;
  final bool isLoading;

  @override
  List<Object?> get props => [medications, isLoading];
}

final class InventoryError extends InventoryState {
  const InventoryError(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

@Singleton()
final class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  InventoryBloc({
    required WatchMedications watchMedications,
    required AddMedication addMedication,
    required UpdateMedication updateMedication,
    required DeleteMedication deleteMedication,
    required UpdateMedicationStock updateMedicationStock,
  })  : _watchMedications = watchMedications,
        _addMedication = addMedication,
        _updateMedication = updateMedication,
        _deleteMedication = deleteMedication,
        _updateMedicationStock = updateMedicationStock,
        super(const InventoryInitial()) {
    on<MedicationsStarted>(_onStarted);
    on<MedicationAdded>(_onAdded);
    on<MedicationUpdated>(_onUpdated);
    on<MedicationDeleted>(_onDeleted);
    on<MedicationStockAdjusted>(_onStockAdjusted);
    on<MedicationsRefreshRequested>(_onRefreshRequested);
  }

  final WatchMedications _watchMedications;
  final AddMedication _addMedication;
  final UpdateMedication _updateMedication;
  final DeleteMedication _deleteMedication;
  final UpdateMedicationStock _updateMedicationStock;

  Future<void> _onStarted(
    MedicationsStarted event,
    Emitter<InventoryState> emit,
  ) async {
    emit(const InventoryLoading());
    await emit.forEach<Either<Failure, List<Medication>>>(
      _watchMedications(const NoParams()),
      onData: (either) {
        return either.fold(
          (failure) => InventoryError(failure),
          (medications) => InventoryLoaded(medications: medications),
        );
      },
      onError: (error, stackTrace) => InventoryError(
        ServerFailure(error.toString()),
      ),
    );
  }

  Future<void> _onAdded(
    MedicationAdded event,
    Emitter<InventoryState> emit,
  ) async {
    emit(const InventoryLoading());
    final result = await _addMedication(event.medication);
    result.fold(
      (failure) => emit(InventoryError(failure)),
      (_) {},
    );
  }

  Future<void> _onUpdated(
    MedicationUpdated event,
    Emitter<InventoryState> emit,
  ) async {
    emit(const InventoryLoading());
    final result = await _updateMedication(event.medication);
    result.fold(
      (failure) => emit(InventoryError(failure)),
      (_) {},
    );
  }

  Future<void> _onDeleted(
    MedicationDeleted event,
    Emitter<InventoryState> emit,
  ) async {
    emit(const InventoryLoading());
    final result = await _deleteMedication(event.medicationId);
    result.fold(
      (failure) => emit(InventoryError(failure)),
      (_) {},
    );
  }

  Future<void> _onStockAdjusted(
    MedicationStockAdjusted event,
    Emitter<InventoryState> emit,
  ) async {
    emit(const InventoryLoading());
    final result = await _updateMedicationStock(event.params);
    result.fold(
      (failure) => emit(InventoryError(failure)),
      (_) {},
    );
  }

  Future<void> _onRefreshRequested(
    MedicationsRefreshRequested event,
    Emitter<InventoryState> emit,
  ) async {
    // Stream-driven; no explicit refresh needed.
    // The watchMedications stream will emit the latest data automatically.
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
