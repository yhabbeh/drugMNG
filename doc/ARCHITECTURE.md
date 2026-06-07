# ARCHITECTURE.md
# Home Medication Management — Clean Architecture Blueprint

---

## 1. Guiding Principles

This project enforces **strict Clean Architecture** with unidirectional dependency rules. No exceptions. The autonomous coding agent must treat these rules as hard constraints, not suggestions. Any deviation will cause architectural drift that compounds across features.

**Core invariant:** Dependencies point **inward only**.
```
Presentation → Domain ← Data
```
- The **Domain layer** is a pure Dart package. Zero Flutter, zero infrastructure imports.
- The **Data layer** implements Domain interfaces. It knows about Sqflite, Dio, Firebase — Domain does not.
- The **Presentation layer** consumes Domain use cases via BLoC/Cubit. It never touches a repository or data source directly.

---

## 2. Folder Structure

```
lib/
├── core/
│   ├── config/
│   │   ├── app_config.dart              # Env-specific config (baseUrl, timeouts)
│   │   └── flavor_config.dart
│   ├── constants/
│   │   ├── hive_box_names.dart
│   │   └── notification_channels.dart
│   ├── di/
│   │   ├── injection_container.dart     # GetIt root registration
│   │   └── modules/                     # Feature-scoped DI modules
│   │       ├── auth_module.dart
│   │       ├── inventory_module.dart
│   │       ├── schedule_module.dart
│   │       └── sync_module.dart
│   ├── error/
│   │   ├── exceptions.dart              # ServerException, CacheException, etc.
│   │   ├── failures.dart                # ServerFailure, CacheFailure, etc.
│   │   └── failure_mapper.dart          # Exception → Failure mapping utility
│   ├── network/
│   │   ├── network_info.dart            # NetworkInfo interface
│   │   └── network_info_impl.dart       # connectivity_plus implementation
│   ├── sync/
│   │   ├── sync_manager.dart            # Orchestrates online/offline state machine
│   │   ├── sync_queue.dart              # Persistent outbox of pending mutations
│   │   ├── conflict_resolver.dart       # Last-write-wins / vector-clock resolver
│   │   └── sync_status.dart             # Enum: synced | pending | conflict | error
│   ├── notifications/
│   │   ├── notification_service.dart    # flutter_local_notifications facade
│   │   ├── notification_scheduler.dart  # Domain-facing scheduling interface
│   │   └── notification_payload.dart
│   ├── router/
│   │   ├── app_router.dart              # GoRouter config
│   │   └── route_guards.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   └── utils/
│       ├── date_time_utils.dart
│       ├── result.dart                  # Custom Result<T, F> type (see §6)
│       └── typedefs.dart                # EitherFailure<T>, etc.
│
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_profile.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart          # abstract interface
│   │   │   └── usecases/
│   │   │       ├── sign_in_with_google.dart
│   │   │       ├── sign_in_anonymously.dart
│   │   │       └── sign_out.dart
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   └── auth_local_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── user_profile_model.dart       # extends UserProfile entity
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       └── pages/
│   │           └── sign_in_page.dart
│   │
│   ├── profiles/                        # Family/Caregiver profile management
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── caregiver_profile.dart
│   │   │   ├── repositories/
│   │   │   │   └── profile_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_all_profiles.dart
│   │   │       ├── create_profile.dart
│   │   │       ├── update_profile.dart
│   │   │       └── delete_profile.dart
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── profile_local_datasource.dart
│   │   │   │   └── profile_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── caregiver_profile_model.dart
│   │   │   └── repositories/
│   │   │       └── profile_repository_impl.dart
│   │   └── presentation/
│   │       ├── cubit/
│   │       │   ├── profile_cubit.dart
│   │       │   └── profile_state.dart
│   │       ├── pages/
│   │       │   └── profile_management_page.dart
│   │       └── widgets/
│   │           └── profile_avatar_selector.dart
│   │
│   ├── inventory/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── medication.dart
│   │   │   │   ├── medication_stock.dart
│   │   │   │   └── expiration_warning.dart
│   │   │   ├── repositories/
│   │   │   │   └── inventory_repository.dart
│   │   │   ├── usecases/
│   │   │   │   ├── get_medications.dart
│   │   │   │   ├── add_medication.dart
│   │   │   │   ├── update_medication_stock.dart
│   │   │   │   ├── delete_medication.dart
│   │   │   │   ├── get_expiring_medications.dart
│   │   │   │   └── get_low_stock_medications.dart
│   │   │   └── value_objects/
│   │   │       ├── drug_form.dart       # tablet, capsule, liquid, inhaler, etc.
│   │   │       └── dosage_unit.dart
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── inventory_local_datasource.dart
│   │   │   │   └── inventory_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── medication_model.dart
│   │   │   │   └── medication_stock_model.dart
│   │   │   └── repositories/
│   │   │       └── inventory_repository_impl.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── inventory_bloc.dart
│   │       │   ├── inventory_event.dart
│   │       │   └── inventory_state.dart
│   │       ├── cubit/
│   │       │   ├── expiration_warning_cubit.dart
│   │       │   └── expiration_warning_state.dart
│   │       ├── pages/
│   │       │   ├── inventory_list_page.dart
│   │       │   └── add_edit_medication_page.dart
│   │       └── widgets/
│   │           ├── medication_card.dart
│   │           ├── stock_level_indicator.dart
│   │           └── expiration_badge.dart
│   │
│   ├── schedule/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── dose_schedule.dart
│   │   │   │   ├── dose_log.dart
│   │   │   │   └── recurrence_rule.dart
│   │   │   ├── repositories/
│   │   │   │   └── schedule_repository.dart
│   │   │   ├── usecases/
│   │   │   │   ├── get_schedules_for_profile.dart
│   │   │   │   ├── create_schedule.dart
│   │   │   │   ├── update_schedule.dart
│   │   │   │   ├── delete_schedule.dart
│   │   │   │   ├── log_dose_taken.dart
│   │   │   │   ├── log_dose_skipped.dart
│   │   │   │   └── get_adherence_report.dart
│   │   │   └── value_objects/
│   │   │       ├── schedule_type.dart   # fixed | prn | variable_interval
│   │   │       └── recurrence_pattern.dart
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── schedule_local_datasource.dart
│   │   │   │   └── schedule_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   ├── dose_schedule_model.dart
│   │   │   │   ├── dose_log_model.dart
│   │   │   │   └── recurrence_rule_model.dart
│   │   │   └── repositories/
│   │   │       └── schedule_repository_impl.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── schedule_bloc.dart
│   │       │   ├── schedule_event.dart
│   │       │   └── schedule_state.dart
│   │       ├── cubit/
│   │       │   ├── dose_log_cubit.dart
│   │       │   └── dose_log_state.dart
│   │       ├── pages/
│   │       │   ├── schedule_overview_page.dart
│   │       │   └── create_schedule_page.dart
│   │       └── widgets/
│   │           ├── daily_dose_timeline.dart
│   │           ├── dose_action_sheet.dart
│   │           └── adherence_chart.dart
│   │
│   └── dashboard/
│       └── presentation/
│           ├── cubit/
│           │   ├── dashboard_cubit.dart
│           │   └── dashboard_state.dart
│           ├── pages/
│           │   └── dashboard_page.dart
│           └── widgets/
│               ├── upcoming_doses_widget.dart
│               ├── expiry_alerts_widget.dart
│               └── profile_switcher.dart
│
└── main.dart
```

---

## 3. Dependency Rules (Enforced)

### 3.1 Domain Layer — Zero External Dependencies
- Entities are plain Dart classes (immutable, `const` constructors, `Equatable`).
- Repository interfaces are `abstract interface class`. No implementation details.
- Use cases implement `UseCase<ReturnType, Params>` or `StreamUseCase<ReturnType, Params>`.
- **Forbidden imports:** `flutter/`, `sqflite`, `hive`, `dio`, `firebase_*`, any `_impl.dart`.

### 3.2 Data Layer — Infrastructure Only
- Models extend or implement Domain entities. They carry `fromJson`, `toJson`, `fromLocal` (Hive/Sqflite DTO), `toLocal`.
- Repository implementations depend on `>=2` datasources (local + remote) and `NetworkInfo`.
- Datasources are injected; never instantiated inside the repository.
- **Forbidden imports:** anything from `presentation/`.

### 3.3 Presentation Layer — BLoC/Cubit + Widgets Only
- Widgets receive entities or display models — never raw JSON or data models.
- BLoCs/Cubits receive use cases via constructor injection (GetIt).
- Pages are thin: they provide BLoC providers and route to child widgets.
- **Forbidden imports:** repositories, datasources, models, Dio, Hive, Sqflite.

---

## 4. State Management Rules

### Use BLoC when:
- The feature has multiple event types that drive state transitions (e.g., `InventoryBloc`: LoadInventory, AddMedication, DeleteMedication, FilterChanged).
- State transitions require event-sourcing semantics (e.g., background sync events triggering UI updates).
- The feature has complex async event queuing needs (e.g., `ScheduleBloc`).

### Use Cubit when:
- The state is driven by a single async call or simple user action stream (e.g., `ExpirationWarningCubit`, `DashboardCubit`).
- It's a form/wizard step with linear state progression.
- The widget is a self-contained display component with minimal interaction logic.

### BLoC/Cubit Lifecycle Rules
- Never close a BLoC manually inside a widget. Use `BlocProvider` with `create:` for auto-disposal.
- For shared state across routes (e.g., active `CaregiverProfile`), provide at the `MaterialApp` level via `RepositoryProvider` + a dedicated Cubit.
- `EventTransformer`: use `droppable()` for search/filter events; `sequential()` for mutation events; `restartable()` for real-time stream subscriptions.

---

## 5. Repository Pattern — Offline-First Contract

Every `RepositoryImpl` that involves network I/O must follow this contract:

```
READ  → cache-first: return local immediately, then attempt remote refresh.
WRITE → local-first: persist locally and enqueue to SyncQueue, then attempt remote.
```

```dart
// Pseudocode contract for all RepositoryImpl.getXxx methods
Future<Either<Failure, T>> getXxx(Params params) async {
  // 1. Always attempt local read first
  final cached = await localDataSource.getXxx(params);
  // 2. If offline, return cached (may be empty)
  if (!await networkInfo.isConnected) {
    return Right(cached);
  }
  // 3. If online, refresh from remote, update cache, return fresh data
  try {
    final fresh = await remoteDataSource.getXxx(params);
    await localDataSource.cacheXxx(fresh);
    return Right(fresh);
  } on ServerException catch (e) {
    // Remote failed but cache exists — degrade gracefully
    return cached.isNotEmpty ? Right(cached) : Left(ServerFailure(e.message));
  }
}
```

---

## 6. Error Handling Strategy

### Custom Result Type (`core/utils/result.dart`)
Use `fpdart`'s `Either<Failure, T>` throughout the Domain and Data layers.

```dart
// core/utils/typedefs.dart
import 'package:fpdart/fpdart.dart';
import '../error/failures.dart';

typedef EitherFailure<T> = Future<Either<Failure, T>>;
typedef StreamEitherFailure<T> = Stream<Either<Failure, T>>;
```

### Failure Hierarchy (`core/error/failures.dart`)
```
Failure (abstract, Equatable)
├── ServerFailure
├── NetworkFailure
├── CacheFailure
├── AuthFailure
├── ConflictFailure        ← sync conflict detected
├── ValidationFailure      ← domain-level rule violation
└── NotificationFailure
```

### Presentation Mapping
BLoCs map `Left<Failure>` → typed error state. Never leak raw exceptions to the UI. Use `failure.fold(...)` to extract user-facing messages.

---

## 7. Sync Architecture

### SyncQueue (`core/sync/sync_queue.dart`)
- Backed by a persistent Hive box (`hive_box_names.dart: syncQueueBox`).
- Each entry: `{ id, operation: enum(create|update|delete), entityType, payload, retryCount, timestamp }`.
- `SyncManager` processes the queue using an exponential backoff strategy (max 5 retries).

### Conflict Resolution
- Default strategy: **Last-Write-Wins** based on `updatedAt` UTC timestamps.
- For critical mutations (dose logs), use **append-only** semantics — never overwrite, always merge.
- `ConflictResolver` emits a `ConflictFailure` to the BLoC if auto-resolution is not possible; UI presents a disambiguation dialog.

### SyncManager State Machine
```
States: idle → syncing → synced | error | conflict
Triggers:
  - App foreground (AppLifecycleState.resumed)
  - Network connectivity restored (connectivity_plus stream)
  - Explicit user pull-to-refresh
  - WorkManager periodic task (every 15 min, battery-permissive)
```

---

## 8. Notification Architecture

`NotificationScheduler` (in `core/notifications/`) is the **only** component that interacts with `flutter_local_notifications` and `firebase_messaging`.

- Domain use cases invoke `NotificationScheduler` via an injected interface — they never import the concrete implementation.
- Schedule changes in `ScheduleBloc` dispatch `NotificationScheduler.reschedule(schedule)` after successful persistence.
- All notification payloads carry `scheduleId` + `profileId` to route deep links correctly via GoRouter.
