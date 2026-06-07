import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';
import 'package:drug/features/profiles/domain/repositories/profile_repository.dart';

@injectable
class UpdateProfile implements UseCase<CaregiverProfile, CaregiverProfile> {
  UpdateProfile(this._repository);

  final ProfileRepository _repository;

  @override
  EitherFailure<CaregiverProfile> call(CaregiverProfile params) {
    return _repository.updateProfile(params);
  }
}
