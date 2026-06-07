import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/repositories/inventory_repository.dart';

@injectable
class GetLowStockMedications implements UseCase<List<Medication>, NoParams> {
  GetLowStockMedications(this._repository);

  final InventoryRepository _repository;

  @override
  EitherFailure<List<Medication>> call(NoParams params) {
    return _repository.getLowStockMedications();
  }
}
