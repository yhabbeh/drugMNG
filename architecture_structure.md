# Home Pharmacy Management & Medication Reminders - Architecture Proposal

## 1. Clean Architecture Folder Structure

The app will follow a strict Clean Architecture pattern, divided into `domain`, `data`, and `presentation` layers, organized by feature.

```
lib/
│
├── core/                       # Shared across all features
│   ├── constants/              # App-wide constants (colors, strings, themes)
│   ├── error/                  # Custom exceptions and failures (e.g., ServerException, CacheFailure)
│   ├── network/                # Network info checking
│   ├── usecases/               # Base UseCase class interface
│   └── utils/                  # Helper functions (date formatting, validators)
│
├── features/
│   ├── scanner/                # Feature: Smart Scanner Module
│   │   ├── domain/
│   │   │   ├── entities/       # ScannedMedication
│   │   │   ├── repositories/   # IScannerRepository
│   │   │   └── usecases/       # ScanBarcodeUseCase, ExtractTextFromImageUseCase
│   │   ├── data/
│   │   │   ├── models/         # ScannedMedicationModel
│   │   │   ├── datasources/    # Remote API APIs (OpenFDA, etc.), Local ML Kit source
│   │   │   └── repositories/   # ScannerRepositoryImpl
│   │   └── presentation/
│   │       ├── bloc/           # ScannerBloc / ScannerCubit
│   │       ├── pages/          # ScannerPage
│   │       └── widgets/        # CameraOverlayWidget, ResultCardWidget
│   │
│   ├── inventory/              # Feature: Inventory Management
│   │   ├── domain/
│   │   │   ├── entities/       # Medication
│   │   │   ├── repositories/   # IInventoryRepository
│   │   │   └── usecases/       # AddMedication, CheckLowStock, GetMedications
│   │   ├── data/
│   │   │   ├── models/         # MedicationModel (Isar annotated)
│   │   │   ├── datasources/    # LocalIsarDataSource
│   │   │   └── repositories/   # InventoryRepositoryImpl
│   │   └── presentation/
│   │       ├── bloc/           # InventoryBloc
│   │       ├── pages/          # InventoryPage, MedicationDetailsPage
│   │       └── widgets/        # MedicationListTile, ExpiryWarningWidget
│   │
│   ├── schedule/               # Feature: Scheduling & Reminders
│   │   ├── domain/
│   │   │   ├── entities/       # Schedule, DoseLog
│   │   │   ├── repositories/   # IScheduleRepository
│   │   │   └── usecases/       # CreateSchedule, LogDose, GetUpcomingDoses
│   │   ├── data/
│   │   │   ├── models/         # ScheduleModel, DoseLogModel
│   │   │   ├── datasources/    # LocalIsarDataSource, NotificationDataSource
│   │   │   └── repositories/   # ScheduleRepositoryImpl
│   │   └── presentation/
│   │       ├── bloc/           # ScheduleBloc
│   │       ├── pages/          # CalendarPage, AddSchedulePage
│   │       └── widgets/        # TimelineWidget, ActionableDoseCard
│   │
│   └── profile/                # Feature: User Profiles (Family Members)
│       ├── domain/             # Profile entity, repository interfaces, usecases
│       ├── data/               # ProfileModel, Local datasources
│       └── presentation/       # Profile selection UI, Family management
│
├── injection_container.dart    # GetIt setup for dependency injection
└── main.dart                   # Entry point, initializes Isar, Notifications
```
