import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/symptoms/domain/entities/symptom_entry.dart';
import 'package:drug/features/symptoms/domain/repositories/symptom_repository.dart';

@injectable
class LogSymptom implements UseCase<Unit, SymptomEntry> {
  LogSymptom(this._repository);

  final SymptomRepository _repository;

  @override
  EitherFailure<Unit> call(SymptomEntry params) {
    return _repository.logSymptom(params);
  }
}
