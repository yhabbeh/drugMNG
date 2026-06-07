import 'package:drug/features/auth/domain/entities/user_profile.dart';

final class UserProfileModel {
  const UserProfileModel({
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

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      isAnonymous: json['isAnonymous'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isAnonymous': isAnonymous,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserProfile toDomain() {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      isAnonymous: isAnonymous,
      createdAt: createdAt,
    );
  }

  factory UserProfileModel.fromDomain(UserProfile user) {
    return UserProfileModel(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      isAnonymous: user.isAnonymous,
      createdAt: user.createdAt,
    );
  }
}
