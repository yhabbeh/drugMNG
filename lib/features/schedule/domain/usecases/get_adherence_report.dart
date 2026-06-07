import 'package:injectable/injectable.dart';

import 'package:drug/core/utils/usecase.dart';
import 'package:drug/features/schedule/domain/entities/adherence_report.dart';
import 'package:drug/features/schedule/domain/repositories/schedule_repository.dart';
import 'package:drug/features/schedule/domain/usecases/schedule_params.dart';

@injectable
class GetAdherenceReport
    implements UseCase<AdherenceReport, AdherenceParams> {
  GetAdherenceReport(this._repository);

  final ScheduleRepository _repository;

  @override
  EitherFailure<AdherenceReport> call(AdherenceParams params) {
    return _repository.getAdherenceReport(params);
  }
}
