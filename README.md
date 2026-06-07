# Home Medication Manager (drug)

A beautiful, premium, and performant Flutter application designed for family caregivers to manage and track medications, schedules, and adherence.

## Tech Stack & Standards

*   **State Management**: `flutter_bloc` (Bloc & Cubit)
*   **Dependency Injection**: `get_it` + `injectable` (annotations-driven container)
*   **Local Database**: `hive` (primary offline database) and `sqflite` (for background queues)
*   **Networking**: `dio` + `retrofit` (type-safe REST API client generation)
*   **Navigation**: `go_router` (declarative routing with support for deep links)
*   **Charts**: `fl_chart` (custom visualizations of adherence data)
*   **Error Handling**: `fpdart` (functional programming using `Either<Failure, T>`)

## Directory Structure

The project follows a **strict Clean Architecture** pattern grouped by feature modules:

```
lib/
├── core/
│   ├── constants/       # Global constants (Hive box names, notification channels)
│   ├── di/              # GetIt root registration and DI modules
│   ├── error/           # Base exception types and failure mappings
│   ├── network/         # Connectivity checks and network utilities
│   ├── notifications/   # Local notification scheduler facade
│   ├── router/          # GoRouter route declarations and guards
│   ├── theme/           # Premium design tokens, colors, and styling rules
│   └── utils/           # Functional typedefs and date utilities
│
└── features/
    ├── adherence/       # Adherence dashboard (Feature 1)
    ├── auth/            # Firebase/Anonymous Authentication
    ├── dashboard/       # Aggregated stats, upcoming doses, and profile switcher
    ├── inventory/       # Medication stock lists and details (with Search/Filter/Sort)
    ├── profiles/        # Multiple caregiver/family profile management
    ├── schedule/        # Medication scheduling and dose logs (taken/skipped/pending)
    └── settings/        # Centralized configurations and notification window options
```

## Guiding Principles

1.  **Strict Clean Architecture**: Presentation → Domain ← Data. 
    *   The **Domain layer** is a pure Dart library (zero Flutter, zero infrastructure imports).
    *   The **Data layer** maps entities to database/network models and implements repositories.
    *   The **Presentation layer** handles UI rendering and triggers business logic via Bloc/Cubit.
2.  **Sound Null Safety**: Compile-time safe coding with `fpdart`'s `Either` handling for errors, preventing crash failures.
3.  **Offline-First Strategy**: All data is stored locally first using `Hive` and synchronizes to GitHub and (in future) remote storage on connectivity restoral.

## Getting Started

### Prerequisites

Ensure you have the Flutter SDK installed on your system.
*   Flutter version `>=3.4.0 <4.0.0`
*   Dart version matching the SDK constraints.

### Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/yhabbeh/drugMNG.git
    cd drugMNG
    ```

2.  Fetch packages:
    ```bash
    flutter pub get
    ```

3.  Generate the code (DI container, JSON serializers, Retrofit clients, etc.):
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

### Running the App

Run the application locally on your simulator/device:
```bash
flutter run
```

To run unit and widget tests:
```bash
flutter test
```
