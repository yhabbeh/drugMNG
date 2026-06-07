import 'package:fpdart/fpdart.dart';

import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/profiles/domain/repositories/profile_repository.dart';

@injectable
class DeleteProfile implements UseCase<Unit, String> {
  DeleteProfile(this._repository);

  final ProfileRepository _repository;

  @override
  EitherFailure<Unit> call(String params) {
    return _repository.deleteProfile(params);
  }
}
