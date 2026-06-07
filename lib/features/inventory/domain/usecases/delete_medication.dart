import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/inventory/domain/repositories/inventory_repository.dart';

@injectable
class DeleteMedication implements UseCase<Unit, String> {
  DeleteMedication(this._repository);

  final InventoryRepository _repository;

  @override
  EitherFailure<Unit> call(String params) {
    return _repository.deleteMedication(params);
  }
}
