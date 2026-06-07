import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:drug/core/error/failures.dart';

typedef EitherFailure<T> = Future<Either<Failure, T>>;
typedef StreamEitherFailure<T> = Stream<Either<Failure, T>>;

abstract interface class UseCase<T, Params> {
  EitherFailure<T> call(Params params);
}

abstract interface class StreamUseCase<T, Params> {
  StreamEitherFailure<T> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
