import 'package:equatable/equatable.dart';

import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';
import 'package:drug/features/profiles/domain/repositories/profile_repository.dart';

final class CreateProfileParams extends Equatable {
  const CreateProfileParams({
    required this.ownerUid,
    required this.displayName,
    required this.relationship,
    this.avatarUrl,
    this.color,
  });

  final String ownerUid;
  final String displayName;
  final Relationship relationship;
  final String? avatarUrl;
  final int? color;

  @override
  List<Object?> get props => [ownerUid, displayName, relationship, avatarUrl, color];
}

@injectable
class CreateProfile implements UseCase<CaregiverProfile, CreateProfileParams> {
  CreateProfile(this._repository);

  final ProfileRepository _repository;

  @override
  EitherFailure<CaregiverProfile> call(CreateProfileParams params) {
    return _repository.createProfile(
      CaregiverProfile(
        id: '', // assigned by datasource
        ownerUid: params.ownerUid,
        displayName: params.displayName,
        relationship: params.relationship,
        avatarUrl: params.avatarUrl,
        color: params.color,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}
