import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/symptoms/domain/repositories/symptom_repository.dart';

@injectable
class DeleteSymptom implements UseCase<Unit, String> {
  DeleteSymptom(this._repository);

  final SymptomRepository _repository;

  @override
  EitherFailure<Unit> call(String params) {
    return _repository.deleteSymptom(params);
  }
}
