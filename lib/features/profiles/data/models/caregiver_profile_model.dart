import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';

final class CaregiverProfileModel {
  const CaregiverProfileModel({
    required this.id,
    required this.ownerUid,
    required this.displayName,
    required this.relationship,
    this.avatarUrl,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUid;
  final String displayName;
  final String relationship;
  final String? avatarUrl;
  final int? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CaregiverProfileModel.fromJson(Map<String, dynamic> json) {
    return CaregiverProfileModel(
      id: json['id'] as String,
      ownerUid: json['ownerUid'] as String,
      displayName: json['displayName'] as String,
      relationship: json['relationship'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      color: json['color'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerUid': ownerUid,
      'displayName': displayName,
      'relationship': relationship,
      'avatarUrl': avatarUrl,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CaregiverProfileModel.fromDomain(CaregiverProfile profile) {
    return CaregiverProfileModel(
      id: profile.id,
      ownerUid: profile.ownerUid,
      displayName: profile.displayName,
      relationship: profile.relationship.name,
      avatarUrl: profile.avatarUrl,
      color: profile.color,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  CaregiverProfile toDomain() {
    return CaregiverProfile(
      id: id,
      ownerUid: ownerUid,
      displayName: displayName,
      relationship: Relationship.values.firstWhere((r) => r.name == relationship),
      avatarUrl: avatarUrl,
      color: color,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
