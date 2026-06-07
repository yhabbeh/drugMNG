// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/adherence/domain/usecases/get_adherence_summary.dart'
    as _i83;
import '../../features/adherence/domain/usecases/get_missed_doses.dart'
    as _i492;
import '../../features/auth/data/datasources/auth_local_datasource.dart'
    as _i992;
import '../../features/auth/data/datasources/auth_remote_datasource.dart'
    as _i161;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/usecases/get_current_user.dart' as _i111;
import '../../features/auth/domain/usecases/sign_in_anonymously.dart' as _i208;
import '../../features/auth/domain/usecases/sign_in_with_google.dart' as _i692;
import '../../features/auth/domain/usecases/sign_out.dart' as _i568;
import '../../features/auth/domain/usecases/watch_auth_state.dart' as _i935;
import '../../features/auth/presentation/bloc/auth_bloc.dart' as _i797;
import '../../features/inventory/data/datasources/inventory_local_datasource.dart'
    as _i716;
import '../../features/inventory/data/datasources/inventory_remote_datasource.dart'
    as _i103;
import '../../features/inventory/data/repositories/inventory_repository_impl.dart'
    as _i572;
import '../../features/inventory/domain/repositories/inventory_repository.dart'
    as _i422;
import '../../features/inventory/domain/usecases/add_medication.dart' as _i844;
import '../../features/inventory/domain/usecases/delete_medication.dart'
    as _i656;
import '../../features/inventory/domain/usecases/get_expiring_medications.dart'
    as _i331;
import '../../features/inventory/domain/usecases/get_low_stock_medications.dart'
    as _i495;
import '../../features/inventory/domain/usecases/get_medications.dart' as _i832;
import '../../features/inventory/domain/usecases/update_medication.dart'
    as _i422;
import '../../features/inventory/domain/usecases/update_medication_stock.dart'
    as _i119;
import '../../features/inventory/domain/usecases/watch_medications.dart'
    as _i83;
import '../../features/inventory/presentation/bloc/inventory_bloc.dart'
    as _i690;
import '../../features/inventory/presentation/cubit/expiration_warning_cubit.dart'
    as _i473;
import '../../features/profiles/data/datasources/profile_local_datasource.dart'
    as _i544;
import '../../features/profiles/data/datasources/profile_remote_datasource.dart'
    as _i54;
import '../../features/profiles/data/repositories/profile_repository_impl.dart'
    as _i275;
import '../../features/profiles/domain/repositories/profile_repository.dart'
    as _i428;
import '../../features/profiles/domain/usecases/create_profile.dart' as _i217;
import '../../features/profiles/domain/usecases/delete_profile.dart' as _i663;
import '../../features/profiles/domain/usecases/get_all_profiles.dart' as _i369;
import '../../features/profiles/domain/usecases/update_profile.dart' as _i610;
import '../../features/profiles/domain/usecases/watch_profiles.dart' as _i504;
import '../../features/profiles/presentation/bloc/profiles_bloc.dart' as _i630;
import '../../features/profiles/presentation/cubit/active_profile_cubit.dart'
    as _i343;
import '../../features/schedule/data/datasources/schedule_local_datasource.dart'
    as _i219;
import '../../features/schedule/data/datasources/schedule_remote_datasource.dart'
    as _i115;
import '../../features/schedule/data/repositories/schedule_repository_impl.dart'
    as _i688;
import '../../features/schedule/domain/repositories/schedule_repository.dart'
    as _i736;
import '../../features/schedule/domain/usecases/create_schedule.dart' as _i929;
import '../../features/schedule/domain/usecases/delete_schedule.dart' as _i394;
import '../../features/schedule/domain/usecases/get_adherence_report.dart'
    as _i704;
import '../../features/schedule/domain/usecases/get_dose_logs_for_date.dart'
    as _i593;
import '../../features/schedule/domain/usecases/get_schedules_for_profile.dart'
    as _i237;
import '../../features/schedule/domain/usecases/log_dose_skipped.dart' as _i523;
import '../../features/schedule/domain/usecases/log_dose_taken.dart' as _i4;
import '../../features/schedule/domain/usecases/revert_dose_log.dart' as _i999;
import '../../features/schedule/domain/usecases/update_schedule.dart' as _i836;
import '../../features/schedule/domain/usecases/watch_schedules_for_profile.dart'
    as _i467;
import '../../features/schedule/presentation/bloc/schedule_bloc.dart' as _i1063;
import '../../features/schedule/presentation/cubit/dose_log_cubit.dart'
    as _i735;
import '../network/network_info.dart' as _i932;
import '../network/network_info_impl.dart' as _i865;
import 'modules/core_module.dart' as _i134;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final coreModule = _$CoreModule();
    gh.singleton<_i343.ActiveProfileCubit>(() => _i343.ActiveProfileCubit());
    gh.lazySingleton<_i361.Dio>(() => coreModule.dio);
    gh.lazySingleton<_i895.Connectivity>(() => coreModule.connectivity);
    gh.lazySingleton<_i219.ScheduleLocalDataSource>(
        () => _i219.ScheduleLocalDataSourceImpl.create());
    gh.lazySingleton<_i992.AuthLocalDataSource>(
        () => _i992.AuthLocalDataSourceImpl.create());
    gh.lazySingleton<_i161.AuthRemoteDataSource>(
        () => const _i161.AuthRemoteDataSourceImpl());
    gh.lazySingleton<_i54.ProfileRemoteDataSource>(
        () => _i54.ProfileRemoteDataSourceImpl());
    gh.lazySingleton<_i716.InventoryLocalDataSource>(
        () => _i716.InventoryLocalDataSourceImpl.create());
    gh.lazySingleton<_i115.ScheduleRemoteDataSource>(
        () => _i115.ScheduleRemoteDataSourceImpl());
    gh.lazySingleton<_i787.AuthRepository>(() => _i153.AuthRepositoryImpl(
          remoteDataSource: gh<_i161.AuthRemoteDataSource>(),
          localDataSource: gh<_i992.AuthLocalDataSource>(),
        ));
    gh.lazySingleton<_i103.InventoryRemoteDataSource>(
        () => _i103.InventoryRemoteDataSourceImpl());
    gh.lazySingleton<_i544.ProfileLocalDataSource>(
        () => _i544.ProfileLocalDataSourceImpl.create());
    gh.lazySingleton<_i932.NetworkInfo>(
        () => _i865.NetworkInfoImpl(gh<_i895.Connectivity>()));
    gh.lazySingleton<_i428.ProfileRepository>(() => _i275.ProfileRepositoryImpl(
          remoteDataSource: gh<_i54.ProfileRemoteDataSource>(),
          localDataSource: gh<_i544.ProfileLocalDataSource>(),
          networkInfo: gh<_i932.NetworkInfo>(),
        ));
    gh.lazySingleton<_i736.ScheduleRepository>(
        () => _i688.ScheduleRepositoryImpl(
              remoteDataSource: gh<_i115.ScheduleRemoteDataSource>(),
              localDataSource: gh<_i219.ScheduleLocalDataSource>(),
              networkInfo: gh<_i932.NetworkInfo>(),
              inventoryRepository: gh<_i422.InventoryRepository>(),
            ));
    gh.lazySingleton<_i422.InventoryRepository>(
        () => _i572.InventoryRepositoryImpl(
              remoteDataSource: gh<_i103.InventoryRemoteDataSource>(),
              localDataSource: gh<_i716.InventoryLocalDataSource>(),
              networkInfo: gh<_i932.NetworkInfo>(),
            ));
    gh.lazySingleton<_i111.GetCurrentUser>(
        () => _i111.GetCurrentUser(gh<_i787.AuthRepository>()));
    gh.lazySingleton<_i208.SignInAnonymously>(
        () => _i208.SignInAnonymously(gh<_i787.AuthRepository>()));
    gh.lazySingleton<_i692.SignInWithGoogle>(
        () => _i692.SignInWithGoogle(gh<_i787.AuthRepository>()));
    gh.lazySingleton<_i568.SignOut>(
        () => _i568.SignOut(gh<_i787.AuthRepository>()));
    gh.lazySingleton<_i935.WatchAuthState>(
        () => _i935.WatchAuthState(gh<_i787.AuthRepository>()));
    gh.factory<_i83.GetAdherenceSummary>(
        () => _i83.GetAdherenceSummary(gh<_i736.ScheduleRepository>()));
    gh.factory<_i492.GetMissedDoses>(
        () => _i492.GetMissedDoses(gh<_i736.ScheduleRepository>()));
    gh.factory<_i929.CreateSchedule>(
        () => _i929.CreateSchedule(gh<_i736.ScheduleRepository>()));
    gh.factory<_i394.DeleteSchedule>(
        () => _i394.DeleteSchedule(gh<_i736.ScheduleRepository>()));
    gh.factory<_i704.GetAdherenceReport>(
        () => _i704.GetAdherenceReport(gh<_i736.ScheduleRepository>()));
    gh.factory<_i593.GetDoseLogsForDate>(
        () => _i593.GetDoseLogsForDate(gh<_i736.ScheduleRepository>()));
    gh.factory<_i237.GetSchedulesForProfile>(
        () => _i237.GetSchedulesForProfile(gh<_i736.ScheduleRepository>()));
    gh.factory<_i523.LogDoseSkipped>(
        () => _i523.LogDoseSkipped(gh<_i736.ScheduleRepository>()));
    gh.factory<_i4.LogDoseTaken>(
        () => _i4.LogDoseTaken(gh<_i736.ScheduleRepository>()));
    gh.factory<_i999.RevertDoseLog>(
        () => _i999.RevertDoseLog(gh<_i736.ScheduleRepository>()));
    gh.factory<_i836.UpdateSchedule>(
        () => _i836.UpdateSchedule(gh<_i736.ScheduleRepository>()));
    gh.factory<_i467.WatchSchedulesForProfile>(
        () => _i467.WatchSchedulesForProfile(gh<_i736.ScheduleRepository>()));
    gh.factory<_i217.CreateProfile>(
        () => _i217.CreateProfile(gh<_i428.ProfileRepository>()));
    gh.factory<_i663.DeleteProfile>(
        () => _i663.DeleteProfile(gh<_i428.ProfileRepository>()));
    gh.factory<_i369.GetAllProfiles>(
        () => _i369.GetAllProfiles(gh<_i428.ProfileRepository>()));
    gh.factory<_i610.UpdateProfile>(
        () => _i610.UpdateProfile(gh<_i428.ProfileRepository>()));
    gh.factory<_i504.WatchProfiles>(
        () => _i504.WatchProfiles(gh<_i428.ProfileRepository>()));
    gh.singleton<_i630.ProfilesBloc>(() => _i630.ProfilesBloc(
          getAllProfiles: gh<_i369.GetAllProfiles>(),
          watchProfiles: gh<_i504.WatchProfiles>(),
          createProfile: gh<_i217.CreateProfile>(),
          updateProfile: gh<_i610.UpdateProfile>(),
          deleteProfile: gh<_i663.DeleteProfile>(),
        ));
    gh.factory<_i844.AddMedication>(
        () => _i844.AddMedication(gh<_i422.InventoryRepository>()));
    gh.factory<_i656.DeleteMedication>(
        () => _i656.DeleteMedication(gh<_i422.InventoryRepository>()));
    gh.factory<_i331.GetExpiringMedications>(
        () => _i331.GetExpiringMedications(gh<_i422.InventoryRepository>()));
    gh.factory<_i495.GetLowStockMedications>(
        () => _i495.GetLowStockMedications(gh<_i422.InventoryRepository>()));
    gh.factory<_i832.GetMedications>(
        () => _i832.GetMedications(gh<_i422.InventoryRepository>()));
    gh.factory<_i422.UpdateMedication>(
        () => _i422.UpdateMedication(gh<_i422.InventoryRepository>()));
    gh.factory<_i119.UpdateMedicationStock>(
        () => _i119.UpdateMedicationStock(gh<_i422.InventoryRepository>()));
    gh.factory<_i83.WatchMedications>(
        () => _i83.WatchMedications(gh<_i422.InventoryRepository>()));
    gh.singleton<_i690.InventoryBloc>(() => _i690.InventoryBloc(
          watchMedications: gh<_i83.WatchMedications>(),
          addMedication: gh<_i844.AddMedication>(),
          updateMedication: gh<_i422.UpdateMedication>(),
          deleteMedication: gh<_i656.DeleteMedication>(),
          updateMedicationStock: gh<_i119.UpdateMedicationStock>(),
        ));
    gh.singleton<_i735.DoseLogCubit>(() =>
        _i735.DoseLogCubit(getDoseLogsForDate: gh<_i593.GetDoseLogsForDate>()));
    gh.singleton<_i473.ExpirationWarningCubit>(() =>
        _i473.ExpirationWarningCubit(
            getExpiringMedications: gh<_i331.GetExpiringMedications>()));
    gh.singleton<_i797.AuthBloc>(() => _i797.AuthBloc(
          watchAuthState: gh<_i935.WatchAuthState>(),
          signInWithGoogle: gh<_i692.SignInWithGoogle>(),
          signInAnonymously: gh<_i208.SignInAnonymously>(),
          signOut: gh<_i568.SignOut>(),
        ));
    gh.singleton<_i1063.ScheduleBloc>(() => _i1063.ScheduleBloc(
          getSchedulesForProfile: gh<_i237.GetSchedulesForProfile>(),
          watchSchedulesForProfile: gh<_i467.WatchSchedulesForProfile>(),
          createSchedule: gh<_i929.CreateSchedule>(),
          updateSchedule: gh<_i836.UpdateSchedule>(),
          deleteSchedule: gh<_i394.DeleteSchedule>(),
          logDoseTaken: gh<_i4.LogDoseTaken>(),
          logDoseSkipped: gh<_i523.LogDoseSkipped>(),
          revertDoseLog: gh<_i999.RevertDoseLog>(),
        ));
    return this;
  }
}

class _$CoreModule extends _i134.CoreModule {}
