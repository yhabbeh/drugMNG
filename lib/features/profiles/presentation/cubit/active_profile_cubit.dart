import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';

sealed class ActiveProfileState extends Equatable {
  const ActiveProfileState();

  @override
  List<Object?> get props => [];
}

final class ActiveProfileEmpty extends ActiveProfileState {
  const ActiveProfileEmpty();
}

final class ActiveProfileSelected extends ActiveProfileState {
  const ActiveProfileSelected(this.profile);
  final CaregiverProfile profile;

  @override
  List<Object?> get props => [profile];
}

@Singleton()
final class ActiveProfileCubit extends Cubit<ActiveProfileState> {
  ActiveProfileCubit() : super(const ActiveProfileEmpty());

  void selectProfile(CaregiverProfile profile) {
    emit(ActiveProfileSelected(profile));
  }

  void clearProfile() {
    emit(const ActiveProfileEmpty());
  }
}
