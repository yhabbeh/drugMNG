import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/auth/domain/repositories/auth_repository.dart';

@LazySingleton()
class SignOut implements UseCase<Unit, NoParams> {
  SignOut(this._repository);

  final AuthRepository _repository;

  @override
  EitherFailure<Unit> call(NoParams params) {
    return _repository.signOut();
  }
}
