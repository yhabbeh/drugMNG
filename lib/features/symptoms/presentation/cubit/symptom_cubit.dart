import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/error/failures.dart';
import 'package:drug/features/symptoms/domain/entities/symptom_entry.dart';
import 'package:drug/features/symptoms/domain/usecases/delete_symptom.dart';
import 'package:drug/features/symptoms/domain/usecases/log_symptom.dart';
import 'package:drug/features/symptoms/domain/usecases/watch_symptoms.dart';

sealed class SymptomState extends Equatable {
  const SymptomState();

  @override
  List<Object?> get props => [];
}

final class SymptomInitial extends SymptomState {
  const SymptomInitial();
}

final class SymptomLoading extends SymptomState {
  const SymptomLoading();
}

final class SymptomLoaded extends SymptomState {
  const SymptomLoaded(this.symptoms);

  final List<SymptomEntry> symptoms;

  @override
  List<Object?> get props => [symptoms];
}

final class SymptomError extends SymptomState {
  const SymptomError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

@injectable
class SymptomCubit extends Cubit<SymptomState> {
  SymptomCubit({
    required WatchSymptoms watchSymptoms,
    required LogSymptom logSymptom,
    required DeleteSymptom deleteSymptom,
  })  : _watchSymptoms = watchSymptoms,
        _logSymptom = logSymptom,
        _deleteSymptom = deleteSymptom,
        super(const SymptomInitial());

  final WatchSymptoms _watchSymptoms;
  final LogSymptom _logSymptom;
  final DeleteSymptom _deleteSymptom;

  StreamSubscription? _subscription;

  void startWatching(String profileId) {
    emit(const SymptomLoading());
    _subscription?.cancel();

    _subscription = _watchSymptoms(profileId).listen((result) {
      result.fold(
        (failure) => emit(SymptomError(failure)),
        (symptoms) {
          final sorted = [...symptoms]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
          emit(SymptomLoaded(sorted));
        },
      );
    });
  }

  Future<void> saveEntry(SymptomEntry symptom) async {
    final result = await _logSymptom(symptom);
    result.fold(
      (failure) => emit(SymptomError(failure)),
      (_) {},
    );
  }

  Future<void> removeEntry(String id) async {
    final result = await _deleteSymptom(id);
    result.fold(
      (failure) => emit(SymptomError(failure)),
      (_) {},
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
