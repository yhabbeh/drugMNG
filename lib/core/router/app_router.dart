import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:drug/core/router/app_routes.dart';
import 'package:drug/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:drug/features/auth/presentation/pages/sign_in_page.dart';
import 'package:drug/features/adherence/presentation/pages/adherence_page.dart';
import 'package:drug/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:drug/features/inventory/domain/entities/medication.dart';
import 'package:drug/features/inventory/presentation/pages/inventory_list_page.dart';
import 'package:drug/features/inventory/presentation/pages/medication_detail_page.dart';
import 'package:drug/features/inventory/presentation/pages/medication_form_page.dart';
import 'package:drug/features/profiles/domain/entities/caregiver_profile.dart';
import 'package:drug/features/profiles/presentation/pages/profile_form_page.dart';
import 'package:drug/features/profiles/presentation/pages/profile_list_page.dart';
import 'package:drug/features/schedule/domain/entities/dose_schedule.dart';
import 'package:drug/features/schedule/presentation/pages/dose_action_page.dart';
import 'package:drug/features/schedule/presentation/pages/schedule_form_page.dart';
import 'package:drug/features/schedule/presentation/pages/schedule_list_page.dart';
import 'package:drug/features/settings/presentation/pages/settings_page.dart';

GoRouter buildAppRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthenticated = authState is AuthAuthenticated;
      final isOnSignIn = state.matchedLocation == AppRoutes.signIn;

      if (!isAuthenticated && !isOnSignIn) return AppRoutes.signIn;
      if (isAuthenticated && isOnSignIn) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.signIn,
        name: 'signIn',
        builder: (context, state) => const SignInPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.inventory,
            name: 'inventory',
            builder: (context, state) => const InventoryListPage(),
            routes: [
              GoRoute(
                path: 'form',
                name: 'inventoryForm',
                builder: (context, state) {
                  final medication = state.extra as Medication?;
                  return MedicationFormPage(medication: medication);
                },
              ),
              GoRoute(
                path: 'detail',
                name: 'inventoryDetail',
                builder: (context, state) {
                  final medication = state.extra as Medication;
                  return MedicationDetailPage(medication: medication);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.schedule,
            name: 'schedule',
            builder: (context, state) => const ScheduleListPage(),
            routes: [
              GoRoute(
                path: 'form',
                name: 'scheduleForm',
                builder: (context, state) {
                  final schedule = state.extra as DoseSchedule?;
                  return ScheduleFormPage(schedule: schedule);
                },
              ),
              GoRoute(
                path: 'dose-action',
                name: 'scheduleDoseAction',
                builder: (context, state) {
                  final payload = state.extra as String?;
                  return DoseActionPage(payload: payload);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.profiles,
            name: 'profiles',
            builder: (context, state) => const ProfileListPage(),
            routes: [
              GoRoute(
                path: 'form',
                name: 'profileForm',
                builder: (context, state) {
                  final profile = state.extra as CaregiverProfile?;
                  return ProfileFormPage(profile: profile);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: AppRoutes.adherence,
            name: 'adherence',
            builder: (context, state) => const AdherencePage(),
          ),
        ],
      ),
    ],
  );
}

final class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    late StreamSubscription<dynamic> subscription;
    subscription = stream.listen(
      (_) => notifyListeners(),
      onError: (_) => subscription.cancel(),
    );
  }
}

final class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.medication_outlined), label: 'Inventory'),
          NavigationDestination(icon: Icon(Icons.schedule_outlined), label: 'Schedule'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profiles'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.inventory)) return 1;
    if (location.startsWith(AppRoutes.schedule)) return 2;
    if (location.startsWith(AppRoutes.profiles)) return 3;
    if (location.startsWith(AppRoutes.settings)) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.dashboard);
      case 1:
        context.go(AppRoutes.inventory);
      case 2:
        context.go(AppRoutes.schedule);
      case 3:
        context.go(AppRoutes.profiles);
      case 4:
        context.go(AppRoutes.settings);
      default:
    }
  }
}
