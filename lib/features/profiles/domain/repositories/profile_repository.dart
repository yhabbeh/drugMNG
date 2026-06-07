import 'package:fpdart/fpdart.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';

abstract interface class ProfileRepository {
  EitherFailure<List<CaregiverProfile>> getAllProfiles();
  StreamEitherFailure<List<CaregiverProfile>> watchProfiles();
  EitherFailure<CaregiverProfile> createProfile(CaregiverProfile profile);
  EitherFailure<CaregiverProfile> updateProfile(CaregiverProfile profile);
  EitherFailure<Unit> deleteProfile(String profileId);
}
