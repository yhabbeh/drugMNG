import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:drug/core/di/injection_container.dart';
import 'package:drug/core/local_storage/hive_registrar.dart';
import 'package:drug/core/notifications/notification_scheduler.dart';
import 'package:drug/core/notifications/notification_scheduler_impl.dart';
import 'package:drug/core/router/app_router.dart';
import 'package:drug/core/theme/app_theme.dart';
import 'package:drug/features/adherence/domain/usecases/get_adherence_summary.dart';
import 'package:drug/features/adherence/domain/usecases/get_missed_doses.dart';
import 'package:drug/features/adherence/presentation/bloc/adherence_bloc.dart';
import 'package:drug/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:drug/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:drug/features/inventory/presentation/cubit/expiration_warning_cubit.dart';
import 'package:drug/features/profiles/presentation/bloc/profiles_bloc.dart';
import 'package:drug/features/profiles/presentation/cubit/active_profile_cubit.dart';
import 'package:drug/features/schedule/presentation/bloc/schedule_bloc.dart';
import 'package:drug/features/schedule/presentation/cubit/dose_log_cubit.dart';
import 'package:drug/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:drug/features/settings/domain/settings_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  await HiveRegistrar.init();
  await configureDependencies();

  final authBloc = sl<AuthBloc>()..add(const AuthStarted());
  final profilesBloc = sl<ProfilesBloc>()..add(const ProfilesStarted());
  final activeProfileCubit = sl<ActiveProfileCubit>();
  final inventoryBloc = sl<InventoryBloc>();
  final expirationWarningCubit = sl<ExpirationWarningCubit>();
  final scheduleBloc = sl<ScheduleBloc>();
  final doseLogCubit = sl<DoseLogCubit>();
  final settingsCubit = SettingsCubit();
  sl.registerLazySingleton<SettingsCubit>(() => settingsCubit);

  final adherenceBloc = AdherenceBloc(
    getAdherenceSummary: sl<GetAdherenceSummary>(),
    getMissedDoses: sl<GetMissedDoses>(),
  );

  final router = buildAppRouter(authBloc);

  final notificationPlugin = await NotificationSchedulerImpl.init(
    onSelectNotification: (payload) {
      if (payload != null) {
        router.go('/schedule/dose-action', extra: payload);
      }
    },
  );
  final notificationScheduler = NotificationSchedulerImpl(
    plugin: notificationPlugin,
  );
  sl.registerLazySingleton<NotificationScheduler>(
    () => notificationScheduler,
  );

  runApp(
    DrugApp(
      router: router,
      authBloc: authBloc,
      profilesBloc: profilesBloc,
      activeProfileCubit: activeProfileCubit,
      inventoryBloc: inventoryBloc,
      expirationWarningCubit: expirationWarningCubit,
      scheduleBloc: scheduleBloc,
      doseLogCubit: doseLogCubit,
      settingsCubit: settingsCubit,
      adherenceBloc: adherenceBloc,
    ),
  );
}

final class DrugApp extends StatelessWidget {
  const DrugApp({
    super.key,
    required this.router,
    required this.authBloc,
    required this.profilesBloc,
    required this.activeProfileCubit,
    required this.inventoryBloc,
    required this.expirationWarningCubit,
    required this.scheduleBloc,
    required this.doseLogCubit,
    required this.settingsCubit,
    required this.adherenceBloc,
  });

  final GoRouter router;
  final AuthBloc authBloc;
  final ProfilesBloc profilesBloc;
  final ActiveProfileCubit activeProfileCubit;
  final InventoryBloc inventoryBloc;
  final ExpirationWarningCubit expirationWarningCubit;
  final ScheduleBloc scheduleBloc;
  final DoseLogCubit doseLogCubit;
  final SettingsCubit settingsCubit;
  final AdherenceBloc adherenceBloc;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
        BlocProvider.value(value: profilesBloc),
        BlocProvider.value(value: activeProfileCubit),
        BlocProvider.value(value: inventoryBloc),
        BlocProvider.value(value: expirationWarningCubit),
        BlocProvider.value(value: scheduleBloc),
        BlocProvider.value(value: doseLogCubit),
        BlocProvider.value(value: settingsCubit),
        BlocProvider.value(value: adherenceBloc),
      ],
      child: _AppView(router: router),
    );
  }
}

final class _AppView extends StatelessWidget {
  const _AppView({required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (a, b) => a.themeMode != b.themeMode,
      builder: (context, settings) {
        return MaterialApp.router(
          title: 'Home Medication Manager',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          routerConfig: router,
        );
      },
    );
  }
}
