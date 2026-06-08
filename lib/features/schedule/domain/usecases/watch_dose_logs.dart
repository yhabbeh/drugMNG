import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/schedule/domain/entities/dose_log.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';

@injectable
class WatchDoseLogs implements StreamUseCase<List<DoseLog>, String> {
  WatchDoseLogs(this._repository);

  final ScheduleRepository _repository;

  @override
  StreamEitherFailure<List<DoseLog>> call(String params) {
    return _repository.watchDoseLogs(params);
  }
}
