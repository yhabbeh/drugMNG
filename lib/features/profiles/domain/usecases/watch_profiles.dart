import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';
import 'package:drug/features/profiles/domain/repositories/profile_repository.dart';

@injectable
class WatchProfiles implements StreamUseCase<List<CaregiverProfile>, NoParams> {
  WatchProfiles(this._repository);

  final ProfileRepository _repository;

  @override
  StreamEitherFailure<List<CaregiverProfile>> call(NoParams params) {
    return _repository.watchProfiles();
  }
}
