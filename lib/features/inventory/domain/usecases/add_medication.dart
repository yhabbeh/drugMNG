import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/repositories/inventory_repository.dart';

@injectable
class AddMedication implements UseCase<Unit, Medication> {
  AddMedication(this._repository);

  final InventoryRepository _repository;

  @override
  EitherFailure<Unit> call(Medication params) {
    return _repository.addMedication(params);
  }
}
