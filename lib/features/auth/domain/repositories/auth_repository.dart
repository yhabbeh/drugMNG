import 'package:fpdart/fpdart.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/auth/domain/entities/user_profile.dart';

abstract interface class AuthRepository {
  EitherFailure<UserProfile> signInWithGoogle();
  EitherFailure<UserProfile> signInAnonymously();
  EitherFailure<Unit> signOut();
  EitherFailure<UserProfile?> getCurrentUser();
  StreamEitherFailure<UserProfile?> watchAuthState();
}
