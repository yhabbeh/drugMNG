import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:drug/features/inventory/domain/usecases/inventory_params.dart';

@injectable
class UpdateMedicationStock implements UseCase<Unit, UpdateStockParams> {
  UpdateMedicationStock(this._repository);

  final InventoryRepository _repository;

  @override
  EitherFailure<Unit> call(UpdateStockParams params) {
    return _repository.updateMedicationStock(params);
  }
}
