import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/symptoms/domain/entities/symptom_entry.dart';
import 'package:drug/features/symptoms/domain/repositories/symptom_repository.dart';

@injectable
class WatchSymptoms implements StreamUseCase<List<SymptomEntry>, String> {
  WatchSymptoms(this._repository);

  final SymptomRepository _repository;

  @override
  StreamEitherFailure<List<SymptomEntry>> call(String params) {
    return _repository.watchSymptomsForProfile(params);
  }
}
