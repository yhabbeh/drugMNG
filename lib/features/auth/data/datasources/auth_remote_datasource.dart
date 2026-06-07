import 'package:injectable/injectable.dart';
import 'package:drug/features/auth/data/models/user_profile_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<UserProfileModel> signInWithGoogle();
  Future<UserProfileModel> signInAnonymously();
  Future<void> signOut();
  Future<UserProfileModel?> getCurrentUser();
  Stream<UserProfileModel?> watchAuthState();
}

@LazySingleton(as: AuthRemoteDataSource)
final class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl();

  @override
  Future<UserProfileModel> signInAnonymously() async {
    return UserProfileModel(uid: 'local_user', email: null, displayName: 'Local User', photoUrl: null, isAnonymous: true, createdAt: DateTime.now());
  }

  @override
  Future<UserProfileModel> signInWithGoogle() async {
    throw UnimplementedError('Google sign-in not yet implemented');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<UserProfileModel?> getCurrentUser() async {
    return UserProfileModel(uid: 'local_user', email: null, displayName: 'Local User', photoUrl: null, isAnonymous: true, createdAt: DateTime.now());
  }

  @override
  Stream<UserProfileModel?> watchAuthState() {
    return Stream.value(UserProfileModel(uid: 'local_user', email: null, displayName: 'Local User', photoUrl: null, isAnonymous: true, createdAt: DateTime.now()));
  }
}
