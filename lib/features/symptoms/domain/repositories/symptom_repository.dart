import 'package:fpdart/fpdart.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/symptoms/domain/entities/symptom_entry.dart';

abstract interface class SymptomRepository {
  EitherFailure<List<SymptomEntry>> getSymptomsForProfile(String profileId);
  StreamEitherFailure<List<SymptomEntry>> watchSymptomsForProfile(String profileId);
  EitherFailure<Unit> logSymptom(SymptomEntry symptom);
  EitherFailure<Unit> deleteSymptom(String id);
}
