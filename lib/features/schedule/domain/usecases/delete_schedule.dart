import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';

@injectable
class DeleteSchedule implements UseCase<Unit, String> {
  DeleteSchedule(this._repository);

  final ScheduleRepository _repository;

  @override
  EitherFailure<Unit> call(String params) {
    return _repository.deleteSchedule(params);
  }
}
