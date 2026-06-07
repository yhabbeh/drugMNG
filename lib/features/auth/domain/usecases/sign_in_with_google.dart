import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/auth/domain/entities/user_profile.dart';
import 'package:drug/features/auth/domain/repositories/auth_repository.dart';

@LazySingleton()
class SignInWithGoogle implements UseCase<UserProfile, NoParams> {
  SignInWithGoogle(this._repository);

  final AuthRepository _repository;

  @override
  EitherFailure<UserProfile> call(NoParams params) {
    return _repository.signInWithGoogle();
  }
}
