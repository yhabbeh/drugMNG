import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/symptoms/domain/entities/symptom_entry.dart';
import 'package:drug/features/symptoms/domain/repositories/symptom_repository.dart';

@injectable
class GetSymptomsTimeline implements UseCase<List<SymptomEntry>, String> {
  GetSymptomsTimeline(this._repository);

  final SymptomRepository _repository;

  @override
  EitherFailure<List<SymptomEntry>> call(String params) {
    return _repository.getSymptomsForProfile(params);
  }
}
