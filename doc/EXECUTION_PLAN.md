# EXECUTION_PLAN.md
# Home Medication Management — Atomic Execution Plan

---

## Sequencing Philosophy

Tasks are ordered to respect the Clean Architecture dependency graph:
**Domain → Data → Presentation**, always. No Presentation task should begin before its Data counterpart is complete. No Data task should begin before its Domain counterpart is complete.

Infrastructure (DI, routing, error types) is built first because everything depends on it. Feature work begins only after the foundation is hardened.

**Task Status Notation:** `[ ]` = not started · `[~]` = in progress · `[x]` = done

---

## Phase 0: Project Scaffold & Infrastructure

_Status: [x] TASK-0.1 · [x] TASK-0.2 · [x] TASK-0.3 · [x] TASK-0.4 · [x] TASK-0.5 · [x] TASK-0.6_

---

### TASK-0.1 — Project Bootstrap & Dependency Installation

**Objective:** Initialize the Flutter project with all declared dependencies, enforce build constraints, and verify the build graph is clean.

**Layer Focus:** Root / Configuration

**Steps:**
1. `flutter create home_medication_manager --org com.yourorg --platforms android,ios`
2. Replace `pubspec.yaml` with the exact contents of `TECH_STACK_AND_STANDARDS.md §1`.
3. Run `flutter pub get`.
4. Configure `analysis_options.yaml` with `flutter_lints` + the following additional rules:
   - `avoid_dynamic_calls: true`
   - `always_use_package_imports: true`
   - `prefer_const_constructors: true`
   - `unawaited_futures: true`
5. Set `dart.sdk` constraint to `>=3.4.0 <4.0.0` in `pubspec.yaml`.
6. Create the top-level folder structure from `ARCHITECTURE.md §2` (empty files with `// TODO` stubs are acceptable at this stage).

**Definition of Done:**
- `flutter pub get` exits 0 with no dependency conflicts.
- `flutter analyze` exits 0 with zero warnings or errors.
- `flutter build apk --debug` exits 0.
- Folder structure from `ARCHITECTURE.md §2` exists and is committed.

_Status: [x] Done_

---

### TASK-0.2 — Core Error Types & Result Typedefs

_Status: [x] Done_

**Objective:** Implement the Failure hierarchy, exception types, and `EitherFailure` typedefs that every subsequent layer depends on.

**Layer Focus:** `lib/core/error/` and `lib/core/utils/`

**Files to Create:**
- `lib/core/error/exceptions.dart`
- `lib/core/error/failures.dart`
- `lib/core/error/failure_mapper.dart`
- `lib/core/utils/typedefs.dart`

**Specification:**

`failures.dart`:
```dart
import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure([this.message = 'An unexpected error occurred.']);
  final String message;
  @override
  List<Object> get props => [message];
}

final class ServerFailure extends Failure { const ServerFailure([super.message]); }
final class NetworkFailure extends Failure { const NetworkFailure([super.message]); }
final class CacheFailure extends Failure { const CacheFailure([super.message]); }
final class AuthFailure extends Failure { const AuthFailure([super.message]); }
final class ConflictFailure extends Failure { const ConflictFailure([super.message]); }
final class ValidationFailure extends Failure { const ValidationFailure([super.message]); }
final class NotificationFailure extends Failure { const NotificationFailure([super.message]); }
```

`exceptions.dart`: Mirror the Failure hierarchy with exception counterparts (e.g., `ServerException`, `CacheException`). Each carries a `message` and optional `statusCode`.

`failure_mapper.dart`: A single static method `Failure fromException(Exception e)` that maps exceptions to failures via exhaustive pattern matching.

`typedefs.dart`:
```dart
import 'package:fpdart/fpdart.dart';
import '../error/failures.dart';

typedef EitherFailure<T> = Future<Either<Failure, T>>;
typedef StreamEitherFailure<T> = Stream<Either<Failure, T>>;
```

**Definition of Done:**
- All files exist and are free of `flutter analyze` warnings.
- A unit test in `test/core/error/failure_mapper_test.dart` verifies each exception type maps to the correct `Failure` subtype.
- No imports from `data/` or `presentation/` exist in any of these files.

---

### TASK-0.3 — Dependency Injection Container (GetIt + Injectable)

_Status: [x] Done_

**Objective:** Establish the DI container shell with feature module stubs. All future injectable registrations will slot into this structure.

**Layer Focus:** `lib/core/di/`

**Files to Create:**
- `lib/core/di/injection_container.dart`
- `lib/core/di/injection_container.config.dart` (code-gen output — do not hand-write)
- `lib/core/di/modules/core_module.dart`

**Specification:**

`injection_container.dart`:
```dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection_container.config.dart';

final GetIt sl = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async => sl.init();
```

`core_module.dart`:
```dart
import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';

@module
abstract class CoreModule {
  @lazySingleton
  Dio get dio => Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ))..interceptors.addAll([/* AuthInterceptor, LoggingInterceptor */]);
}
```

Run `flutter pub run build_runner build` to generate `.config.dart`.

**Definition of Done:**
- `configureDependencies()` runs without throwing in `main.dart`.
- `flutter pub run build_runner build --delete-conflicting-outputs` exits 0.
- `flutter analyze` clean.

---

### TASK-0.4 — Network Info & Connectivity

_Status: [x] Done_

**Objective:** Implement the `NetworkInfo` abstraction used by all repository implementations to switch between online/offline paths.

**Layer Focus:** `lib/core/network/`

**Files to Create:**
- `lib/core/network/network_info.dart`
- `lib/core/network/network_info_impl.dart`

**Specification:**
```dart
// network_info.dart
abstract interface class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onConnectivityChanged;
}

// network_info_impl.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: NetworkInfo)
final class NetworkInfoImpl implements NetworkInfo {
  NetworkInfoImpl(this._connectivity);
  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  @override
  Stream<bool> get onConnectivityChanged =>
    _connectivity.onConnectivityChanged.map((r) => r != ConnectivityResult.none);
}
```

Register `Connectivity` in `CoreModule` as a `@lazySingleton`.

**Definition of Done:**
- Unit test in `test/core/network/network_info_impl_test.dart` mocks `Connectivity` and verifies both `isConnected` states and stream emissions.
- `flutter analyze` clean.

---

### TASK-0.5 — App Router (GoRouter) Setup

_Status: [x] Done_

**Objective:** Configure the root `GoRouter` with typed route definitions and placeholder pages.

**Layer Focus:** `lib/core/router/`

**Files to Create:**
- `lib/core/router/app_router.dart`
- `lib/core/router/route_guards.dart`
- `lib/core/router/app_routes.dart` (path constants)

**Specification:**
- Use GoRouter's `ShellRoute` to wrap authenticated routes with the main `Scaffold` (bottom nav).
- Define the following top-level routes: `/`, `/inventory`, `/schedule`, `/profiles`, `/settings`.
- `RouteGuard`: a `redirect` callback that checks auth state from the `AuthBloc` and redirects to `/sign-in` if unauthenticated. Auth state is read from a `GoRouterRefreshStream` wrapping the `AuthBloc` stream.
- All page parameters use typed `GoRouteData` extra objects — never raw `Map<String, dynamic>`.

**Definition of Done:**
- App navigates to `DashboardPage` stub without crash.
- Unauthenticated state redirects to `/sign-in`.
- `flutter analyze` clean.

---

### TASK-0.6 — Hive Local Storage Initialization

_Status: [x] Done_

**Objective:** Bootstrap Hive, register all type adapters, and open all required boxes at app startup.

**Layer Focus:** `lib/core/` + `lib/main.dart`

**Files to Create / Modify:**
- `lib/core/constants/hive_box_names.dart`
- `lib/core/local_storage/hive_registrar.dart`
- `lib/main.dart` (initialization sequence only)

**Specification:**

`hive_box_names.dart`:
```dart
abstract final class HiveBoxNames {
  static const String medications = 'medications_box';
  static const String medicationStock = 'medication_stock_box';
  static const String caregiverProfiles = 'caregiver_profiles_box';
  static const String doseSchedules = 'dose_schedules_box';
  static const String doseLogs = 'dose_logs_box';
  static const String syncQueue = 'sync_queue_box';
  static const String userPreferences = 'user_preferences_box';
}
```

`hive_registrar.dart`: A class with a single static `Future<void> init()` method that calls `Hive.initFlutter()`, registers all generated type adapters, and opens all boxes. Boxes must be opened before `configureDependencies()` runs.

`main.dart` initialization order:
```
1. WidgetsFlutterBinding.ensureInitialized()
2. await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
3. await HiveRegistrar.init()
4. await configureDependencies()
5. runApp(App())
```

**Definition of Done:**
- App boots without Hive initialization errors on both Android and iOS simulators.
- All boxes listed in `HiveBoxNames` are accessible post-boot via `Hive.box(name)` without throwing.

---

## Phase 1: Authentication Feature

_Status: [x] TASK-1.1 · [x] TASK-1.2 · [x] TASK-1.3_

---

### TASK-1.1 — Auth Domain Layer

**Objective:** Define the `UserProfile` entity, `AuthRepository` interface, and all auth-related use cases.

**Layer Focus:** `lib/features/auth/domain/` — **Domain only. No implementation.**

**Files to Create:**
```
lib/features/auth/domain/entities/user_profile.dart
lib/features/auth/domain/repositories/auth_repository.dart
lib/features/auth/domain/usecases/sign_in_with_google.dart
lib/features/auth/domain/usecases/sign_in_anonymously.dart
lib/features/auth/domain/usecases/sign_out.dart
lib/features/auth/domain/usecases/get_current_user.dart
lib/features/auth/domain/usecases/watch_auth_state.dart
```

**Entity Specification:**
```dart
final class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.isAnonymous,
    required this.createdAt,
  });
  final String uid;
  final String? email;
  final String displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final DateTime createdAt;
  ...
}
```

**Repository Interface:**
```dart
abstract interface class AuthRepository {
  EitherFailure<UserProfile> signInWithGoogle();
  EitherFailure<UserProfile> signInAnonymously();
  EitherFailure<Unit> signOut();
  EitherFailure<UserProfile?> getCurrentUser();
  StreamEitherFailure<UserProfile?> watchAuthState();
}
```

**Definition of Done:**
- All files exist with complete implementations (no TODOs in domain layer).
- Zero imports from `data/` or `presentation/` or any infrastructure package.
- Unit tests for each use case using a `MockAuthRepository` (mocktail) verify correct delegation and failure propagation.
- `flutter analyze` clean.

---

### TASK-1.2 — Auth Data Layer

**Objective:** Implement `UserProfileModel`, auth datasources (Firebase Auth), and `AuthRepositoryImpl`.

**Layer Focus:** `lib/features/auth/data/`

**Files to Create:**
```
lib/features/auth/data/models/user_profile_model.dart
lib/features/auth/data/datasources/auth_remote_datasource.dart
lib/features/auth/data/datasources/auth_local_datasource.dart
lib/features/auth/data/repositories/auth_repository_impl.dart
```

**`AuthRepositoryImpl` must:**
- Cache the last-known `UserProfile` in Hive (box: `userPreferences`) for offline access.
- On `signOut`, clear the local cache.
- `watchAuthState` wraps `FirebaseAuth.instance.authStateChanges()`.

**Definition of Done:**
- `AuthRepositoryImpl` is registered with `@LazySingleton(as: AuthRepository)`.
- Unit tests mock both datasources; verify that a `FirebaseAuthException` maps to `AuthFailure`.
- Integration: `GetCurrentUser` use case resolves a non-null `UserProfile` after mock Google sign-in.

_Status: [x] Done_

---

### TASK-1.3 — Auth Presentation Layer (BLoC + UI)

**Objective:** Build `AuthBloc` and the sign-in page.

**Layer Focus:** `lib/features/auth/presentation/`

**AuthBloc Events:**
```dart
sealed class AuthEvent extends Equatable {}
final class AuthStarted extends AuthEvent {}
final class AuthGoogleSignInRequested extends AuthEvent {}
final class AuthAnonymousSignInRequested extends AuthEvent {}
final class AuthSignOutRequested extends AuthEvent {}
```

**AuthBloc States:**
```dart
sealed class AuthState extends Equatable {}
final class AuthInitial extends AuthState {}
final class AuthLoading extends AuthState {}
final class AuthAuthenticated extends AuthState { final UserProfile user; }
final class AuthUnauthenticated extends AuthState {}
final class AuthError extends AuthState { final Failure failure; }
```

**AuthBloc:**
- `AuthStarted` triggers `WatchAuthState` stream subscription; state updated on each emission.
- Provided at `MaterialApp` level.
- `GoRouterRefreshStream` listens to the `AuthBloc` stream for route guards.

**SignInPage:**
- Two buttons: "Continue with Google" and "Continue without account".
- All loading/error state driven by `BlocBuilder<AuthBloc, AuthState>`.
- No business logic in the widget tree.

**Definition of Done:**
- `bloc_test` verifies state transitions for all events including error scenarios.
- UI renders correctly in all 4 states (initial, loading, authenticated, error).
- GoRouter redirect fires correctly when `AuthAuthenticated` / `AuthUnauthenticated` states change.

_Status: [x] Done_

---

## Phase 2: Caregiver Profiles Feature

_Status: [x] TASK-2.1 · [ ] TASK-2.2 · [ ] TASK-2.3_

---

### TASK-2.1 — Profiles Domain Layer

**Objective:** Define `CaregiverProfile` entity, repository interface, and CRUD use cases.

**Layer Focus:** `lib/features/profiles/domain/`

**Entity Specification:**
```dart
final class CaregiverProfile extends Equatable {
  const CaregiverProfile({
    required this.id,
    required this.ownerUid,
    required this.displayName,
    required this.relationship,     // self | spouse | child | parent | other
    this.avatarUrl,
    this.color,                     // int hex for UI avatar color
    required this.createdAt,
    required this.updatedAt,
  });
  ...
}
```

**Use Cases to Implement:**
- `GetAllProfiles(NoParams)` → `EitherFailure<List<CaregiverProfile>>`
- `WatchProfiles(NoParams)` → `StreamEitherFailure<List<CaregiverProfile>>`
- `CreateProfile(CreateProfileParams)` → `EitherFailure<CaregiverProfile>`
- `UpdateProfile(CaregiverProfile)` → `EitherFailure<CaregiverProfile>`
- `DeleteProfile(String profileId)` → `EitherFailure<Unit>`

**Definition of Done:**
- All use cases unit-tested with `MockProfileRepository`.
- Domain layer has zero non-Dart/non-Equatable imports.

_Status: [x] Done_

---

### TASK-2.2 — Profiles Data Layer

**Objective:** Implement Hive-backed local datasource, Firestore remote datasource, and `ProfileRepositoryImpl` with offline-first strategy.

**Layer Focus:** `lib/features/profiles/data/`

**Hive Type ID:** `30–34`

**ProfileRepositoryImpl contract:**
- `getAll` / `watchAll`: cache-first (Hive box stream for watch, local read + remote refresh for get).
- `create` / `update` / `delete`: local-first → enqueue to `SyncQueue` → attempt remote.
- Firestore collection path: `users/{uid}/profiles/{profileId}`.

**Definition of Done:**
- Unit tests verify offline path: when `NetworkInfo.isConnected = false`, remote datasource is never called.
- Unit tests verify sync enqueue: when remote fails, item is present in `SyncQueue`.
- `@LazySingleton(as: ProfileRepository)` registered.

---

### TASK-2.3 — Profiles Presentation Layer (Cubit + UI)

**Objective:** Build `ProfileCubit`, profile management page, and profile switcher widget.

**Layer Focus:** `lib/features/profiles/presentation/`

**ProfileCubit States:**
```dart
sealed class ProfileState extends Equatable {}
final class ProfileInitial extends ProfileState {}
final class ProfileLoading extends ProfileState {}
final class ProfileLoaded extends ProfileState {
  final List<CaregiverProfile> profiles;
  final CaregiverProfile activeProfile;
  ...
}
final class ProfileOperationSuccess extends ProfileState { final String message; }
final class ProfileError extends ProfileState { final Failure failure; }
```

**`ActiveProfileCubit`**: A separate, app-level Cubit (singleton-scoped at `MaterialApp`) holding the currently selected `CaregiverProfile`. All features that require `profileId` read from this cubit.

**Definition of Done:**
- `bloc_test` verifies CRUD operations and correct state progression.
- `ProfileSwitcherWidget` correctly updates `ActiveProfileCubit` on selection.
- Delete confirmation dialog prevents accidental deletion.

---

## Phase 3: Inventory Feature

---

### TASK-3.1 — Inventory Domain Layer

**Objective:** Define all inventory entities, value objects, repository interface, and use cases.

**Layer Focus:** `lib/features/inventory/domain/`

**Entities:**
- `Medication` (see `TECH_STACK_AND_STANDARDS.md §2.2` for template)
- `MedicationStock`: `{ medicationId, currentCount, unitSize, refillThreshold, lastUpdated }`
- `ExpirationWarning`: `{ medication, daysUntilExpiry, severity: enum(critical|warning|info) }`

**Value Objects:**
```dart
enum DrugForm { tablet, capsule, liquid, inhaler, patch, injection, topical, drops, other }
enum DosageUnit { mg, mcg, ml, units, drops, puffs, applications }
```

**Use Cases:**
- `GetMedications(GetMedicationsParams)` → `EitherFailure<List<Medication>>`
- `WatchMedications(String profileId)` → `StreamEitherFailure<List<Medication>>`
- `AddMedication(Medication)` → `EitherFailure<Unit>`
- `UpdateMedication(Medication)` → `EitherFailure<Unit>`
- `DeleteMedication(String id)` → `EitherFailure<Unit>`
- `UpdateMedicationStock(UpdateStockParams)` → `EitherFailure<Unit>`
- `GetExpiringMedications(ExpiringParams)` → `EitherFailure<List<ExpirationWarning>>`
  - `ExpiringParams`: `{ profileId, withinDays: int }` — threshold-based query
- `GetLowStockMedications(String profileId)` → `EitherFailure<List<Medication>>`

**Definition of Done:**
- All 8 use cases unit-tested.
- `ExpirationWarning.severity` computed correctly: `critical` ≤ 7 days, `warning` ≤ 30 days, `info` > 30 days.

---

### TASK-3.2 — Inventory Data Layer

**Objective:** Implement Hive models, local/remote datasources, and `InventoryRepositoryImpl`.

**Layer Focus:** `lib/features/inventory/data/`

**Hive Type IDs:** `10–14`

**`InventoryLocalDataSource` contract:**
- `watchMedications(String profileId)` returns a `Stream` from a Hive box `watch()` filtered by profileId.
- `getExpiringMedications(String profileId, int withinDays)`: pure local query, no network call.

**`InventoryRemoteDataSource` contract:**
- Uses Retrofit client generated from `lib/features/inventory/data/datasources/inventory_api_client.dart`.
- All mutations append to `SyncQueue` on `NetworkFailure` or `ServerFailure`.

**Definition of Done:**
- `InventoryRepositoryImpl` unit-tested with both online and offline paths for every operation.
- Hive stream emissions tested with a fake box.
- `@LazySingleton(as: InventoryRepository)` registered.

---

### TASK-3.3 — Inventory BLoC

**Objective:** Implement `InventoryBloc` with all events, states, and event transformer configuration.

**Layer Focus:** `lib/features/inventory/presentation/bloc/`

**Events:**
```dart
sealed class InventoryEvent extends Equatable {}
final class InventorySubscriptionRequested extends InventoryEvent { final String profileId; }
final class InventoryMedicationAdded extends InventoryEvent { final Medication medication; }
final class InventoryMedicationUpdated extends InventoryEvent { final Medication medication; }
final class InventoryMedicationDeleted extends InventoryEvent { final String id; }
final class InventoryStockUpdated extends InventoryEvent { final UpdateStockParams params; }
final class InventoryFilterChanged extends InventoryEvent { final String? query; final DrugForm? form; }
```

**States:** (see `ARCHITECTURE.md §5` for `SyncStatus` integration in `InventoryLoaded`)

**Transformer rules:**
- `InventorySubscriptionRequested` → `restartable()`
- `InventoryFilterChanged` → `debounce(Duration(milliseconds: 300))`
- All mutation events → `sequential()`

**Definition of Done:**
- `bloc_test` covers all events including stream re-subscription on profile switch.
- Filter state correctly subsets `medications` list without triggering a new use case call.
- `SyncStatus` in state updates when `SyncManager` emits status changes.

---

### TASK-3.4 — Expiration Warning Cubit

**Objective:** Implement `ExpirationWarningCubit` that polls expiring medications for the active profile and drives dashboard badge counts.

**Layer Focus:** `lib/features/inventory/presentation/cubit/`

**Behavior:**
- Initialized with `activeProfileId` from `ActiveProfileCubit`.
- On load, calls `GetExpiringMedications` with `withinDays: 30`.
- Exposed as a `Stream`-backed auto-refreshing cubit (refreshes on app foreground).

**Definition of Done:**
- `bloc_test` verifies correct state for no warnings, warnings present, and load error.
- `ExpirationBadge` widget correctly shows count from this cubit.

---

### TASK-3.5 — Inventory Presentation Layer (UI)

**Objective:** Build `InventoryListPage`, `AddEditMedicationPage`, and supporting widgets.

**Layer Focus:** `lib/features/inventory/presentation/pages/` and `widgets/`

**InventoryListPage:**
- `BlocBuilder` on `InventoryLoaded.medications` for the list.
- `BlocListener` on `InventoryError` for `SnackBar` display.
- Filter bar drives `InventoryFilterChanged` event.
- `SyncStatus` banner displayed when `syncStatus != SyncStatus.synced`.

**AddEditMedicationPage:**
- Works for both add (no initial entity) and edit (entity passed via GoRouter extra).
- Form validation is in a separate `AddMedicationFormCubit` (not `InventoryBloc`).
- On submit: dispatches `InventoryMedicationAdded` or `InventoryMedicationUpdated`.

**Widgets:**
- `MedicationCard`: displays name, stock level, expiry status. Swipe-to-delete with confirm.
- `StockLevelIndicator`: visual progress indicator (green/yellow/red based on refill threshold).
- `ExpirationBadge`: colored chip with days remaining.

**Definition of Done:**
- Widget tests for `MedicationCard` cover all three `StockLevel` states.
- `AddEditMedicationPage` shows validation errors correctly on submit with empty fields.
- Screen renders correctly in `InventoryLoading`, `InventoryLoaded` (empty + populated), `InventoryError` states.

---

## Phase 4: Scheduling Feature

---

### TASK-4.1 — Schedule Domain Layer

**Objective:** Define scheduling entities, recurrence value objects, repository interface, and all use cases.

**Layer Focus:** `lib/features/schedule/domain/`

**Entities:**
```
DoseSchedule {
  id, profileId, medicationId, scheduleType,
  recurrenceRule, startDate, endDate?,
  dosageAmount, dosageUnit, instructions?,
  isActive, createdAt, updatedAt
}

RecurrenceRule {
  type: enum(daily|weekly|custom_interval|prn),
  times: List<TimeOfDay>,           // for fixed schedules
  intervalHours?: int,              // for variable interval
  daysOfWeek?: List<int>,           // 1=Mon..7=Sun
}

DoseLog {
  id, scheduleId, profileId, medicationId,
  scheduledAt, takenAt?, status: enum(taken|skipped|missed|pending),
  notes?, stockDeductedCount
}
```

**Use Cases:**
- `GetSchedulesForProfile(String profileId)` → `EitherFailure<List<DoseSchedule>>`
- `WatchSchedulesForProfile(String profileId)` → `StreamEitherFailure<List<DoseSchedule>>`
- `CreateSchedule(DoseSchedule)` → `EitherFailure<Unit>`
- `UpdateSchedule(DoseSchedule)` → `EitherFailure<Unit>`
- `DeleteSchedule(String id)` → `EitherFailure<Unit>`
- `LogDoseTaken(LogDoseParams)` → `EitherFailure<Unit>` — also decrements `MedicationStock`
- `LogDoseSkipped(LogDoseParams)` → `EitherFailure<Unit>`
- `GetDoseLogsForDate(GetLogsForDateParams)` → `EitherFailure<List<DoseLog>>`
- `GetAdherenceReport(AdherenceParams)` → `EitherFailure<AdherenceReport>`

**`AdherenceReport`**: `{ profileId, periodStart, periodEnd, totalScheduled, taken, skipped, missed, adherencePercent }`

**Definition of Done:**
- All use cases unit-tested. `LogDoseTaken` test verifies `MedicationStock` decrement is called.
- `RecurrenceRule` correctly computes `nextOccurrence(DateTime from)` for all 4 schedule types. This logic lives in the domain entity as a pure method.
- Zero infrastructure imports.

---

### TASK-4.2 — Schedule Data Layer

**Objective:** Implement schedule and dose log models, datasources, and `ScheduleRepositoryImpl`.

**Layer Focus:** `lib/features/schedule/data/`

**Hive Type IDs:** `20–28`

**Critical Implementation Notes:**
- `DoseLog` entries are **append-only** — never deleted or overwritten in local DB. Conflict resolution uses merge, not replace.
- `ScheduleRepositoryImpl.logDoseTaken` must be atomic: log the dose AND decrement stock in the same Hive batch write. Use `HiveInterface.openBox().putAll()` wrapped in a try-catch; on failure, roll back both.
- `WatchSchedulesForProfile` returns a Hive box watch stream merged with Firestore `snapshots()` via `RxDart.combineLatest`.

**Definition of Done:**
- Atomic dose log + stock decrement tested with a Hive in-memory box.
- Firestore path conventions match: `users/{uid}/profiles/{profileId}/schedules/{scheduleId}`, `users/{uid}/profiles/{profileId}/dose_logs/{logId}`.
- `@LazySingleton(as: ScheduleRepository)` registered.

---

### TASK-4.3 — Notification Scheduler (Core)

**Objective:** Implement `NotificationScheduler` that translates `DoseSchedule` domain entities into `flutter_local_notifications` scheduled calls.

**Layer Focus:** `lib/core/notifications/`

**Trade-offs to navigate:**
| Approach | Precision | Battery | iOS Compatibility |
|---|---|---|---|
| `zonedSchedule` (exact) | High | Higher | Requires `requestExactAlarmPermission` (Android 12+) |
| `periodicallyShow` | Medium | Low | Limited to fixed intervals |
| WorkManager + local notification | Medium-High | Medium | Separate iOS implementation required |

**Decision:** Use `zonedSchedule` with `UILocalNotificationDateInterpretation.absoluteTime` for precision-critical dose reminders. Use WorkManager periodic task as a fallback heartbeat for missed notifications.

**`NotificationScheduler` interface:**
```dart
abstract interface class NotificationScheduler {
  Future<void> scheduleForDose(DoseSchedule schedule);
  Future<void> cancelForSchedule(String scheduleId);
  Future<void> cancelAllForProfile(String profileId);
  Future<void> rescheduleAll(List<DoseSchedule> schedules);
}
```

**Notification payload:** JSON-encoded `{ scheduleId, profileId, medicationId, scheduledAt }`. GoRouter deep link on tap navigates to the dose action bottom sheet.

**Definition of Done:**
- `scheduleForDose` correctly computes all future `zonedSchedule` calls from `RecurrenceRule.nextOccurrence()`.
- Cancellation removes all notifications keyed by `scheduleId` prefix.
- Notification tap correctly navigates to dose action bottom sheet in integration test.

---

### TASK-4.4 — Schedule BLoC

**Objective:** Implement `ScheduleBloc` and `DoseLogCubit`.

**Layer Focus:** `lib/features/schedule/presentation/bloc/` and `cubit/`

**ScheduleBloc Events:**
```dart
sealed class ScheduleEvent extends Equatable {}
final class ScheduleSubscriptionRequested extends ScheduleEvent { final String profileId; }
final class ScheduleCreated extends ScheduleEvent { final DoseSchedule schedule; }
final class ScheduleUpdated extends ScheduleEvent { final DoseSchedule schedule; }
final class ScheduleDeleted extends ScheduleEvent { final String id; }
final class ScheduleDoseTaken extends ScheduleEvent { final LogDoseParams params; }
final class ScheduleDoseSkipped extends ScheduleEvent { final LogDoseParams params; }
```

**Post-mutation side effects in ScheduleBloc:**
- After `ScheduleCreated` / `ScheduleUpdated`: call `NotificationScheduler.scheduleForDose(schedule)`.
- After `ScheduleDeleted`: call `NotificationScheduler.cancelForSchedule(id)`.
- After `ScheduleDoseTaken` / `ScheduleDoseSkipped`: emit updated `DoseLog` list without full reload.

**DoseLogCubit:**
- Loads `DoseLog` entries for a given date from `GetDoseLogsForDate`.
- Responds to `ScheduleBloc` state changes via `BlocListener` in the presentation tree — does not directly depend on the BLoC.

**Definition of Done:**
- `bloc_test` verifies notification side effects are called on mutation events (mock `NotificationScheduler`).
- `DoseLogCubit` date-switching correctly reloads entries.
- All state transitions tested including `ConflictFailure` handling.

---

### TASK-4.5 — Schedule Presentation Layer (UI)

**Objective:** Build schedule overview, creation wizard, and dose action UI.

**Layer Focus:** `lib/features/schedule/presentation/`

**ScheduleOverviewPage:**
- Date-picker header to navigate days.
- `DailyDoseTimeline` widget: chronological list of `DoseLog` entries for selected date.
- Each timeline item shows: medication name, time, status chip (taken/skipped/missed/pending), and action button.

**DoseActionSheet** (modal bottom sheet):
- Triggered by notification tap or timeline item tap.
- Buttons: "Mark as Taken", "Skip Dose".
- Dispatches `ScheduleDoseTaken` / `ScheduleDoseSkipped` to `ScheduleBloc`.
- Auto-dismisses on success state.

**CreateSchedulePage:**
- Step wizard (GoRouter sub-routes): Step 1: Select medication. Step 2: Configure recurrence. Step 3: Set times/intervals. Step 4: Review & save.
- Each step is a separate widget; wizard state managed by `CreateScheduleWizardCubit`.

**AdherenceChart:**
- 7-day or 30-day bar chart (using `fl_chart` or a custom painter).
- Data sourced from `GetAdherenceReport` use case.

**Definition of Done:**
- Widget tests for `DailyDoseTimeline` cover all `DoseLog.status` states.
- `CreateSchedulePage` wizard can be navigated forward and backward without state loss.
- `DoseActionSheet` dispatches correct event and shows loading state during async operation.

---

## Phase 5: Sync & Background Tasks

---

### TASK-5.1 — SyncQueue & SyncManager

**Objective:** Implement the persistent outbox pattern for offline mutations and the `SyncManager` state machine.

**Layer Focus:** `lib/core/sync/`

**SyncQueue entry model** (Hive TypeId: 5):
```dart
@HiveType(typeId: 5)
class SyncQueueEntry extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String operation;     // 'create' | 'update' | 'delete'
  @HiveField(2) late String entityType;    // 'medication' | 'schedule' | 'dose_log' | 'profile'
  @HiveField(3) late String payload;       // JSON-encoded entity
  @HiveField(4) late int retryCount;
  @HiveField(5) late DateTime timestamp;
  @HiveField(6) late String profileId;
}
```

**SyncManager state machine:**
```
idle
 ├─[network restored / app foreground / manual trigger]→ syncing
 │   ├─[all queue entries processed]→ synced
 │   ├─[partial failure, retries remaining]→ idle (reschedule)
 │   └─[conflict detected]→ conflict (emit ConflictFailure to affected BLoC)
 └─[max retries exceeded for entry]→ error (dead-letter queue)
```

**Backoff strategy:** `delay = min(2^retryCount * 1000ms, 30000ms)`

**Definition of Done:**
- `SyncManager.processQueue()` correctly processes entries in FIFO order.
- Exponential backoff tested with fake timers (`fake_async`).
- On `ConflictFailure`, the affected entry is moved to a `deadLetterBox` and `SyncStatus.conflict` is emitted.
- `@Singleton` registered. Initialized in `main.dart` after DI setup.

---

### TASK-5.2 — ConflictResolver

**Objective:** Implement the conflict resolution strategies for all entity types.

**Layer Focus:** `lib/core/sync/conflict_resolver.dart`

**Strategies:**
- `Medication`, `DoseSchedule`, `CaregiverProfile`: Last-Write-Wins on `updatedAt`.
- `DoseLog`: Append-only merge — remote and local entries are merged by `id`; duplicates discarded.
- Resolution method signature: `Either<ConflictFailure, T> resolve<T>(T local, T remote)`

**Definition of Done:**
- Unit tests cover LWW for all entity types.
- Merge test for `DoseLog` verifies no duplicates and no data loss.

---

### TASK-5.3 — WorkManager Background Sync

**Objective:** Register a periodic background task (every 15 minutes) that triggers `SyncManager.processQueue()`.

**Layer Focus:** `lib/core/sync/` + Android/iOS platform configuration

**Trade-offs:**
| | WorkManager (Android) | BGAppRefreshTask (iOS) |
|---|---|---|
| Minimum interval | 15 minutes (OS-enforced) | OS-determined (typically 15–30 min) |
| Reliability | High when battery-permissive | OS throttles aggressively |
| Wakelock | No | No |

**Implementation:**
- Register `WorkManager` task in `main.dart` after DI: `Workmanager().registerPeriodicTask(...)`.
- iOS: register `BGAppRefreshTask` identifier in `Info.plist` and call `background_fetch.configure()`.
- Task handler must re-initialize GetIt if the isolate is fresh (background isolate context).
- Task must be idempotent.

**Definition of Done:**
- WorkManager task is registered on Android and visible in Android Studio's Background Task Inspector.
- Task handler correctly handles cold isolate (no DI initialized) by calling `configureDependencies()` before `SyncManager.processQueue()`.

---

## Phase 6: Dashboard Feature

---

### TASK-6.1 — Dashboard Cubit & Page

**Objective:** Aggregate data from multiple features into the `DashboardCubit` and render the home screen.

**Layer Focus:** `lib/features/dashboard/presentation/`

**DashboardCubit** aggregates from:
- `WatchSchedulesForProfile` → today's upcoming doses
- `GetExpiringMedications` → expiry warnings
- `ActiveProfileCubit` → active profile display

**DashboardState:**
```dart
final class DashboardLoaded extends DashboardState {
  final CaregiverProfile activeProfile;
  final List<DoseLog> todaysDoses;            // pending/upcoming only
  final List<ExpirationWarning> expiryAlerts;
  final SyncStatus syncStatus;
  ...
}
```

**DashboardPage** widgets:
- `ProfileSwitcherWidget`: horizontal scroll, tapping updates `ActiveProfileCubit` and triggers `DashboardCubit.reload()`.
- `UpcomingDosesWidget`: next 3 doses with "Take" quick action buttons.
- `ExpiryAlertsWidget`: grouped by severity with navigation to `InventoryListPage`.

**Definition of Done:**
- `DashboardCubit` correctly combines streams from 2+ use cases.
- Profile switch triggers full data reload for new profile.
- `bloc_test` verifies initial load, profile switch, and partial error (one use case fails, others succeed).

---

## Phase 7: Polish & Hardening

---

### TASK-7.1 — Dio Interceptor Pipeline

**Objective:** Implement auth token injection, token refresh, and retry interceptors.

**Interceptors (applied in order):**
1. `AuthInterceptor`: injects `Authorization: Bearer {token}` from `FirebaseAuth.currentUser.getIdToken()`.
2. `RetryInterceptor`: retries 401 responses once after token refresh; retries 503 responses up to 2 times.
3. `LoggingInterceptor` (debug-only): uses `pretty_dio_logger`.

**Definition of Done:** Integration test verifies token refresh flow and retry behavior using a `MockDioAdapter`.

---

### TASK-7.2 — Permission Handling

**Objective:** Request and handle all runtime permissions with graceful degradation.

**Permissions:** Notification permission (Android 13+), Exact alarm permission (Android 12+), Background app refresh (iOS).

**Permission flow:** Request on first schedule creation. On denial, fall back to WorkManager heartbeat notifications with reduced precision. Surface a persistent banner if exact alarm permission is denied.

**Definition of Done:** Denial path fully tested; app does not crash or hang on permission denial.

---

### TASK-7.3 — Integration & E2E Tests

**Objective:** Write integration tests for the 3 critical user journeys.

**Journeys:**
1. **Add medication → create schedule → receive notification → log dose taken → verify stock decremented.**
2. **Offline: add medication → go offline → verify local persistence → go online → verify sync completes.**
3. **Conflict: modify same medication on two "devices" (simulated) → verify conflict resolution.**

**Definition of Done:** All 3 integration tests pass on both Android and iOS simulators in CI.

---

## Phase Dependency Summary

```
Phase 0 (Infrastructure) 
  └── Phase 1 (Auth)
        └── Phase 2 (Profiles)
              ├── Phase 3 (Inventory)
              ├── Phase 4 (Scheduling)
              └── Phase 6 (Dashboard) ← requires Phase 3 + 4
Phase 5 (Sync) ← can run in parallel with Phase 3 after Phase 0
Phase 7 (Polish) ← final, requires all above
```

**Total Atomic Tasks: 23**
