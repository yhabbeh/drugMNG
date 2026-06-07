import 'package:equatable/equatable.dart';

final class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.isAnonymous,
    required this.createdAt,
  });

  final String uid;
  final String? email;
  final String displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final DateTime createdAt;

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAnonymous,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl, isAnonymous, createdAt];
}
