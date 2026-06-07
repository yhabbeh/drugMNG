import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/domain/repositories/inventory_repository.dart';

@injectable
class WatchMedications implements StreamUseCase<List<Medication>, NoParams> {
  WatchMedications(this._repository);

  final InventoryRepository _repository;

  @override
  StreamEitherFailure<List<Medication>> call(NoParams params) {
    return _repository.watchMedications();
  }
}
