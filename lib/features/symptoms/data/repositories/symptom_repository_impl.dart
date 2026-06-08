import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/error/exceptions.dart';
import 'package:drug/core/error/failure_mapper.dart';
import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/symptoms/data/datasources/symptom_local_datasource.dart';
import 'package:drug/features/symptoms/data/models/symptom_entry_model.dart';
import 'package:drug/features/symptoms/domain/entities/symptom_entry.dart';
import 'package:drug/features/symptoms/domain/repositories/symptom_repository.dart';

@LazySingleton(as: SymptomRepository)
final class SymptomRepositoryImpl implements SymptomRepository {
  SymptomRepositoryImpl({
    required SymptomLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final SymptomLocalDataSource _localDataSource;

  @override
  EitherFailure<List<SymptomEntry>> getSymptomsForProfile(String profileId) async {
    try {
      final models = _localDataSource.getSymptoms(profileId);
      return Right(models.map((m) => m.toDomain()).toList());
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  StreamEitherFailure<List<SymptomEntry>> watchSymptomsForProfile(String profileId) {
    return _localDataSource.watchSymptoms(profileId).map(
          (models) => Right(models.map((m) => m.toDomain()).toList()),
        );
  }

  @override
  EitherFailure<Unit> logSymptom(SymptomEntry symptom) async {
    try {
      final model = SymptomEntryModel.fromDomain(symptom);
      await _localDataSource.saveSymptom(model);
      return const Right(unit);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  EitherFailure<Unit> deleteSymptom(String id) async {
    try {
      await _localDataSource.deleteSymptom(id);
      return const Right(unit);
    } on AppException catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
