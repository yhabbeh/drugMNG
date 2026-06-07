# TECH_STACK_AND_STANDARDS.md
# Home Medication Management — Tech Stack & Coding Standards

---

## 1. Core Dependencies (`pubspec.yaml`)

### State Management & DI
```yaml
flutter_bloc: ^8.1.6        # BLoC + Cubit
get_it: ^8.0.2              # Service locator for dependency injection
injectable: ^2.4.4          # Code-gen annotations for GetIt (@injectable, @lazySingleton)
```

### Functional Programming / Error Handling
```yaml
fpdart: ^1.1.0              # Either<L, R>, Option<A>, TaskEither
equatable: ^2.0.5           # Value equality for entities and states
```

### Local Storage
```yaml
hive_flutter: ^1.1.0        # Primary local DB for structured domain data
hive: ^2.2.3
sqflite: ^2.3.3+1           # SyncQueue and relational join queries only
path_provider: ^2.1.3
```

### Networking
```yaml
dio: ^5.6.0                 # HTTP client with interceptor pipeline
retrofit: ^4.3.0            # Type-safe REST client code-gen
pretty_dio_logger: ^1.4.0   # Debug-only logging interceptor
```

### Cloud & Auth
```yaml
firebase_core: ^3.3.0
firebase_auth: ^5.1.4
cloud_firestore: ^5.2.1     # Remote sync backend
google_sign_in: ^6.2.1
```

### Notifications
```yaml
flutter_local_notifications: ^17.2.2
firebase_messaging: ^15.0.4
timezone: ^0.9.4            # Required for precise local notification scheduling
```

### Background Tasks
```yaml
workmanager: ^0.5.2         # Android background sync (periodic + one-shot)
background_fetch: ^1.2.3    # iOS BGAppRefreshTask
```

### Navigation
```yaml
go_router: ^14.2.7
```

### Utilities
```yaml
intl: ^0.19.0
uuid: ^4.4.2
logger: ^2.4.0
connectivity_plus: ^6.0.3
package_info_plus: ^8.0.2
rxdart: ^0.27.7             # Event transformers and stream composition
```

### Code Generation
```yaml
# dev_dependencies
build_runner: ^2.4.12
hive_generator: ^2.0.1
injectable_generator: ^2.6.2
retrofit_generator: ^9.1.3
json_serializable: ^6.8.0
```

### Testing
```yaml
# dev_dependencies
bloc_test: ^9.1.7
mocktail: ^1.0.4
fake_async: ^1.3.1
sqflite_common_ffi: ^2.3.3+4
```

---

## 2. Coding Standards

### 2.1 Null Safety
- Strict null safety is non-negotiable. `sound null safety` is enabled in `pubspec.yaml`.
- Prefer `final` over `var`. Prefer `const` constructors wherever possible.
- Never use the `!` (bang) operator except inside assertion blocks or after explicit `is` type checks. If you find yourself reaching for `!`, redesign using `Option<A>` from fpdart or explicit null checks.
- All parameters in entities, models, events, and states must be explicitly typed.

### 2.2 Entity Rules
```dart
// Domain entities: immutable, Equatable, const constructor
import 'package:equatable/equatable.dart';

final class Medication extends Equatable {
  const Medication({
    required this.id,
    required this.name,
    required this.drugForm,
    required this.profileId,
    required this.currentStock,
    required this.expirationDate,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final DrugForm drugForm;
  final String profileId;
  final int currentStock;
  final DateTime expirationDate;
  final DateTime updatedAt;

  Medication copyWith({...}) => ...;

  @override
  List<Object?> get props => [id, name, drugForm, profileId, currentStock, expirationDate, updatedAt];
}
```

- Entities **never** have `fromJson`/`toJson`. That belongs to models.
- Entities **never** import from the data or presentation layer.

### 2.3 Model Rules
```dart
// Data models: extend entity, add serialization
import 'package:hive/hive.dart';
import '../../domain/entities/medication.dart';

@HiveType(typeId: 1)
final class MedicationModel extends Medication {
  const MedicationModel({required super.id, ...});

  factory MedicationModel.fromJson(Map<String, dynamic> json) => ...;
  Map<String, dynamic> toJson() => {...};

  factory MedicationModel.fromLocal(MedicationHiveBox box) => ...;
  MedicationHiveBox toLocal() => ...;

  // Downcast to domain entity (for repository return values)
  Medication toEntity() => Medication(id: id, ...);
}
```

### 2.4 Use Case Rules
```dart
// Every use case implements one of two interfaces:
abstract interface class UseCase<Type, Params> {
  EitherFailure<Type> call(Params params);
}

abstract interface class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
}

// Params: use a dedicated immutable class, never raw primitives for >1 param
final class GetMedicationsParams extends Equatable {
  const GetMedicationsParams({required this.profileId});
  final String profileId;
  @override
  List<Object?> get props => [profileId];
}

// No-param use cases use NoParams
class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}
```

### 2.5 Repository Interface Rules
```dart
abstract interface class InventoryRepository {
  EitherFailure<List<Medication>> getMedications(String profileId);
  EitherFailure<Medication> getMedicationById(String id);
  EitherFailure<Unit> addMedication(Medication medication);
  EitherFailure<Unit> updateMedication(Medication medication);
  EitherFailure<Unit> deleteMedication(String id);
  StreamEitherFailure<List<Medication>> watchMedications(String profileId);
}
```

- Return `Unit` (from fpdart) for void operations that can fail.
- Use `Stream` variants for real-time features (Firestore `snapshots()`).
- Never return raw model types from a repository — always the domain entity type.

### 2.6 BLoC/Cubit Standards

**Events** (sealed classes, Dart 3):
```dart
sealed class InventoryEvent extends Equatable {}

final class LoadInventory extends InventoryEvent {
  const LoadInventory({required this.profileId});
  final String profileId;
  @override List<Object?> get props => [profileId];
}

final class AddMedication extends InventoryEvent {
  const AddMedication({required this.medication});
  final Medication medication;
  @override List<Object?> get props => [medication];
}
```

**States** (sealed classes):
```dart
sealed class InventoryState extends Equatable {}
final class InventoryInitial extends InventoryState { ... }
final class InventoryLoading extends InventoryState { ... }
final class InventoryLoaded extends InventoryState {
  const InventoryLoaded({
    required this.medications,
    this.syncStatus = SyncStatus.synced,
  });
  final List<Medication> medications;
  final SyncStatus syncStatus;
  ...
}
final class InventoryError extends InventoryState {
  const InventoryError({required this.failure});
  final Failure failure;
  ...
}
```

- States must never contain raw exceptions. Map to `Failure` subtypes.
- `InventoryLoaded` carries `syncStatus` to surface offline/pending state in UI without a separate BLoC.

### 2.7 Widget Isolation Rules
- Widgets are stateless by default. Use `StatefulWidget` only for animation controllers and focus nodes.
- No business logic inside `build()`. Extract to BLoC/Cubit.
- No direct `context.read<Bloc>()` calls inside `build()`. Use `BlocSelector` or `BlocBuilder` with precise `buildWhen:` conditions to prevent unnecessary rebuilds.
- Prefer `BlocConsumer` over separate `BlocListener` + `BlocBuilder` only when the listener and builder share state type.
- All reusable widgets go in `presentation/widgets/`. Pages are in `presentation/pages/`. Pages never contain widget logic beyond `BlocProvider` + `Scaffold`.

### 2.8 Naming Conventions

| Artifact | Convention | Example |
|---|---|---|
| Entities | `PascalCase`, noun | `DoseSchedule` |
| Use Cases | `PascalCase`, verb phrase | `LogDoseTaken` |
| Repository interface | `PascalCase` + `Repository` | `InventoryRepository` |
| Repository impl | interface name + `Impl` | `InventoryRepositoryImpl` |
| Remote datasource | feature + `RemoteDataSource` | `InventoryRemoteDataSource` |
| Local datasource | feature + `LocalDataSource` | `InventoryLocalDataSource` |
| Hive TypeIds | sequential per feature range | auth: 0–9, inventory: 10–19, schedule: 20–29, profiles: 30–39 |
| BLoC files | `feature_bloc.dart`, `feature_event.dart`, `feature_state.dart` | `inventory_bloc.dart` |
| Cubit files | `feature_cubit.dart`, `feature_state.dart` | `expiration_warning_cubit.dart` |
| Pages | `feature_page.dart` | `inventory_list_page.dart` |
| Widgets | descriptive noun + `_widget.dart` or widget type | `medication_card.dart` |

### 2.9 Async & Concurrency
- All `Future`-returning methods in datasources must have explicit timeout handling via Dio interceptors or `.timeout(Duration(...))`.
- Use `unawaited()` (from `dart:async`) for fire-and-forget side effects (e.g., sync queue enqueue after a local write).
- Never `await` inside a `build()` method. Never call `async` operations directly in `initState()` — dispatch a BLoC event instead.
- Hive box operations are not thread-safe for concurrent writes. Use `Isolate` or sequential access patterns for bulk import operations.

### 2.10 DI Registration Rules (injectable)
```dart
// Singletons: stateful services that must persist app lifetime
@singleton                  // SyncManager, NotificationService, NetworkInfo

// Lazy Singletons: created on first access
@lazySingleton              // All Repositories, All DataSources, Dio

// Factories: new instance per injection request
@injectable                 // All Use Cases, All BLoCs/Cubits
```

Every feature module must have its own `@module` abstract class in `core/di/modules/`.

---

## 3. Code Generation Workflow

After adding any new Hive type, injectable registration, or Retrofit client:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Hive type registration in `main.dart` (managed by a `HiveRegistrar` utility class, not inline).
