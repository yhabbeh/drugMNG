import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/inventory/domain/entities/expiration_warning.dart';
import 'package:drug/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:drug/features/inventory/domain/usecases/inventory_params.dart';

@injectable
class GetExpiringMedications
    implements UseCase<List<ExpirationWarning>, ExpiringParams> {
  GetExpiringMedications(this._repository);

  final InventoryRepository _repository;

  @override
  EitherFailure<List<ExpirationWarning>> call(ExpiringParams params) {
    return _repository.getExpiringMedications(params);
  }
}
