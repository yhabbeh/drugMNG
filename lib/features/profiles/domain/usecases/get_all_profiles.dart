import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';
import 'package:drug/features/profiles/domain/repositories/profile_repository.dart';

@injectable
class GetAllProfiles implements UseCase<List<CaregiverProfile>, NoParams> {
  GetAllProfiles(this._repository);

  final ProfileRepository _repository;

  @override
  EitherFailure<List<CaregiverProfile>> call(NoParams params) {
    return _repository.getAllProfiles();
  }
}
