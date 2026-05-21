## 3. Recommended Packages (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management (Clean Architecture Presentation Layer)
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5          # For value equality in Blocs/Entities

  # Dependency Injection
  get_it: ^7.6.4

  # Local Database (Offline-First, Relational capabilities, Fast)
  isar: ^3.1.0               # Core database
  isar_flutter_libs: ^3.1.0  # Native binaries
  path_provider: ^2.1.1      # For database directory

  # Background Services & Actionable Notifications
  awesome_notifications: ^0.8.2 # For rich, actionable, and full-screen alarm intents
  # OR alternatively: flutter_local_notifications combined with flutter_background_service

  # Networking (For initial barcode fetch, fallback to local later)
  http: ^1.1.0               # Or dio ^5.3.3
  dartz: ^0.10.1             # Functional programming (Either for error handling)

  # Smart Scanner Module
  mobile_scanner: ^3.5.2     # Fast, reliable barcode scanner
  google_mlkit_text_recognition: ^0.11.0 # OCR for fallback extraction (names, dates)
  image_picker: ^1.0.4       # To pick images for OCR if not live camera

  # General Utilities
  uuid: ^4.2.1               # For generating unique IDs
  intl: ^0.18.1              # Date and time formatting

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.6       # Code generation (Isar)
  isar_generator: ^3.1.0     # Code generation for Isar models
  mocktail: ^1.0.1           # For testing
```
