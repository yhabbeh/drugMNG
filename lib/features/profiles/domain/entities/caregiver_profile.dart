import 'package:equatable/equatable.dart';

enum Relationship {
  self,
  spouse,
  child,
  parent,
  other,
}

final class CaregiverProfile extends Equatable {
  const CaregiverProfile({
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
  final Relationship relationship;
  final String? avatarUrl;
  final int? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  CaregiverProfile copyWith({
    String? id,
    String? ownerUid,
    String? displayName,
    Relationship? relationship,
    String? avatarUrl,
    int? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CaregiverProfile(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      displayName: displayName ?? this.displayName,
      relationship: relationship ?? this.relationship,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerUid,
        displayName,
        relationship,
        avatarUrl,
        color,
        createdAt,
        updatedAt,
      ];
}
