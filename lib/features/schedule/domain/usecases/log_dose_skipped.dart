import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';

@injectable
class LogDoseSkipped implements UseCase<Unit, LogDoseParams> {
  LogDoseSkipped(this._repository);

  final ScheduleRepository _repository;

  @override
  EitherFailure<Unit> call(LogDoseParams params) {
    return _repository.logDoseSkipped(params);
  }
}
