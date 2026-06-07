# FUTURE_FEATURES.md
# Home Medication Manager — Backlog & Execution Plans

This document captures the nine candidate features identified in the post–inventory refactor planning session, in priority order. Each section is structured as a self-contained execution plan that can be lifted directly into `EXECUTION_PLAN.md` when prioritized.

**Notation:** `[ ]` = not started · `[~]` = in progress · `[x]` = done
**Layer rule:** Domain → Data → Presentation, always.

---

## 1. Adherence Dashboard

**Objective:** Surface an at-a-glance, visual summary of dose-taking behavior over a selectable window (week / month / 90 days). Reuse the existing `GetAdherenceReport` use case as the source of truth and add aggregate + per-day metrics.

**Dependencies (pubspec):** `fl_chart: ^0.69.0`

### Domain
- **Reuse:** `features/schedule/domain/entities/adherence_report.dart` (verify shape covers taken / skipped / missed counts and a per-day breakdown).
- **New:** `features/adherence/domain/entities/adherence_summary.dart` — aggregate with `int totalDoses, int taken, int skipped, int missed, double adherenceRate, int currentStreak`.
- **New:** `features/adherence/domain/entities/daily_adherence_point.dart` — `(DateTime day, int scheduled, int taken)`.
- **New use cases:**
  - `GetAdherenceSummary(AdherenceRange)` → returns summary + daily points.
  - `GetMissedDoses(AdherenceRange)` → returns the list of `DoseLog` for missed doses.
- `AdherenceRange` is a value object: `enum AdherenceWindow { week, month, ninetyDays }` with helper to compute `DateTimeRange`.

### Data
- None. Pure computation on top of `GetAdherenceReport` results.

### Presentation
- `features/adherence/presentation/bloc/adherence_bloc.dart` — events: `AdherenceRangeChanged(AdherenceWindow)`, `AdherenceRefreshRequested`; state: `AdherenceLoaded(summary, dailyPoints, missedDoses)`.
- `features/adherence/presentation/pages/adherence_page.dart`:
  - SegmentedButton at top for window selection.
  - Top row: three summary cards (Adherence %, Streak, Missed Doses).
  - Bar chart (fl_chart) of daily taken vs. scheduled.
  - "Missed doses" section with the most recent 10 missed.
- `features/adherence/presentation/widgets/`:
  - `summary_card.dart`, `adherence_bar_chart.dart`, `missed_dose_tile.dart`.
- **Dashboard wiring:** add a 4th "Adherence" stat card (next to active/total/expiring) on `dashboard_page.dart` navigating to `/adherence`.

### Routing
- New route: `AppRoutes.adherence = '/adherence'` inside the `ShellRoute` so the bottom nav remains visible.
- Route guard: requires `AuthAuthenticated` (already inherited).

### Tests
- `test/features/adherence/domain/usecases/get_adherence_summary_test.dart` — verifies calculation from a fixture `AdherenceReport`.
- `test/features/adherence/presentation/bloc/adherence_bloc_test.dart` — `AdherenceRangeChanged` re-fetches.

### Definition of Done
- Adherence page reachable from dashboard.
- Window selector updates chart and summary without page rebuild.
- Empty state when no doses are logged.
- `flutter analyze` clean, `flutter test test/features/adherence` green.

**Complexity:** Medium · **Risks:** None significant. Pure presentational work on top of existing data.

---

## 2. Barcode Scanning for Medication Entry

**Objective:** Tap a barcode icon on the medication form, scan the package, auto-fill name / drug form / manufacturer.

**Dependencies (pubspec):**
- `mobile_scanner: ^5.2.3` (camera + ML Kit barcode reader; modern fork of qr_code_scanner)
- `permission_handler: ^11.3.1` (camera permission prompts)

**External API (online tier only):** openFDA `https://api.fda.gov/drug/ndc.json?search=product_ndc:"<barcode>"` (no key required, rate-limited but sufficient for app). RxNorm (`https://rxnav.nlm.nih.gov/REST/rxcui.json?idtype=ndc&id=...`) as fallback.

### Domain
- **New:** `features/inventory/domain/entities/scanned_drug.dart` — `(String barcode, String? name, String? manufacturer, String? dosageForm, String? activeIngredient)`.
- **New use case:** `LookupDrugByBarcode(String barcode)` → returns `ScannedDrug` (may be partial — nulls for fields the API didn't return).

### Data
- `features/inventory/data/datasources/drug_lookup_remote_datasource.dart` — wraps openFDA + RxNorm; cache last 100 lookups in-memory.
- `features/inventory/data/repositories/drug_lookup_repository_impl.dart` — single method, returns `Either<Failure, ScannedDrug>`.

### Presentation
- `features/inventory/presentation/pages/barcode_scanner_page.dart` — full-screen `MobileScanner` widget with overlay reticle, torch toggle, close button. Emits the first valid barcode then pops with it.
- `features/inventory/presentation/widgets/barcode_field.dart` — inline scanner trigger that opens the scanner page and exposes a callback `(String barcode)`.
- **Form wiring:** add a "Scan" IconButton next to the Name field in `medication_form_page.dart`; on result call `LookupDrugByBarcode`, then pre-fill the controllers with non-null fields and show a SnackBar "Prefilled from barcode" (or "No match found, please enter manually").

### Routing
- New route: `AppRoutes.barcodeScanner = '/inventory/scan'`.

### Tests
- Unit test the lookup datasource with `http_mock_adapter` or a tiny custom mock client.
- Widget test for the form: scanning a known barcode prefills fields; unknown barcode shows a SnackBar.

### Definition of Done
- Scan button visible on the medication form.
- Tapping opens camera, asks for permission, scans, and closes.
- Successful scan prefills at least the `name`.
- Permission denial shows an in-app settings deep-link.

**Complexity:** Medium-High · **Risks:** iOS `NSCameraUsageDescription` and Android `CAMERA` permission must be added to platform manifests; on iOS Simulator the camera is unavailable, gate the button with `defaultTargetPlatform`.

---

## 3. Refill Reminders

**Objective:** Predict when each medication will run out based on schedule consumption, and notify the user (and surface a banner) when refill is needed within a configurable window.

**Dependencies:** None new. Reuses `NotificationScheduler`.

### Domain
- **New:** `features/inventory/domain/services/refill_calculator.dart` (pure) — `Duration estimateDaysUntilEmpty(Medication med, List<DoseSchedule> activeSchedules)`:
  - For each active schedule referencing this med, count doses per day from its recurrence rule (e.g. daily 3× = 3, weekly 2× Mon/Wed = 2/7, PRN = 0).
  - If 0 doses/day, fall back to "0" (never refilled via this model).
  - Return `currentStock / dosesPerDay` as a Duration.
- **New entity:** `features/inventory/domain/entities/refill_alert.dart` — `(Medication medication, int daysUntilEmpty, DateTime predictedEmptyDate)`.
- **New use case:** `GetRefillAlerts({int windowDays = 7})` → returns all meds whose `predictedEmptyDate <= now + windowDays`.
- **New use case:** `ScheduleRefillReminders(windowDays)` — for each alert, calls `NotificationScheduler.scheduleRefillAlert(...)`.

### Data
- None new. Reads through `InventoryRepository.getMedications()` + `ScheduleRepository.getSchedulesForProfile()` (or `watchSchedulesForProfile`).

### Presentation
- `features/inventory/presentation/cubit/refill_alert_cubit.dart` — emits `RefillAlertState` (loaded list). Refreshed on `MedicationsStarted`, on dose logs, and when settings `expirationWarningDays` changes.
- Dashboard `dashboard_page.dart`: add a yellow/orange banner above the expiry banner if any refill alerts exist.
- Inventory `inventory_list_page.dart`: show a small "Refill soon" pill on cards that are in the alert set.

### Notifications
- Extend `lib/core/notifications/notification_scheduler.dart` and impl with:
  - `Future<void> scheduleRefillAlert({required String medicationId, required String medicationName, required DateTime triggerAt})`
  - Reuse the existing dose_reminders channel (different notification id scheme: `medicationId.hashCode.abs() * 1000 + 9000 + occurrenceIndex`).

### Settings
- Add a tile: "Refill alert window" (3 / 5 / 7 / 14 days), default 7, stored in `SettingsCubit` (`refillAlertDays`).
- Add a "Reschedule refill reminders" button below it (calls `ScheduleRefillReminders`).

### Tests
- `refill_calculator_test.dart` — pure unit tests covering daily, weekly (Mon/Wed), and PRN cases.
- `refill_alert_cubit_test.dart` — emits correct alerts given fixture inventory + schedules.

### Definition of Done
- Refill banner appears on dashboard when a med will run out within the window.
- OS notification fires at 9 AM on the day stock is predicted to hit zero.
- Settings tile persists and re-runs the calculator.

**Complexity:** Medium · **Risks:** Estimating PRN consumption is impossible; those meds should be excluded from the calculation with a "Set refill threshold manually" hint.

---

## 4. Search / Filter / Sort on Inventory

**Objective:** Add a search bar, filter chips, and a sort menu to `InventoryListPage`.

**Dependencies:** None.

### Implementation (all local state, no bloc needed)
- Convert `_InventoryListPageState` to track:
  - `String _query` (debounced 250 ms via `Timer`).
  - `Set<DrugForm> _formFilter`.
  - `bool _lowStockOnly`, `bool _expiringSoonOnly`.
  - `enum InventorySort { nameAsc, nameDesc, expirationAsc, stockAsc, recentlyAdded } _sort`.
- Derived list: filter then sort in pure functions, kept in a `List<Medication>? _filtered` recomputed in `didUpdateWidget` / on filter changes.

### UI
- New `SearchBar` widget pinned below the AppBar.
- `Wrap` of `FilterChip`s for each `DrugForm` + "Low stock" + "Expiring soon" toggle chips.
- `PopupMenuButton` in AppBar `actions` for sort selection.
- Active filter summary ("Showing 4 of 12") shown when filters are non-default.
- Clear-all button when any filter is active.

### Files
- New: `features/inventory/presentation/widgets/inventory_search_bar.dart`, `inventory_filter_chips.dart`, `inventory_sort_menu.dart`.
- New: `features/inventory/domain/services/inventory_filter.dart` (pure filter+sort functions, easily testable).
- Modify: `inventory_list_page.dart`.

### Tests
- `inventory_filter_test.dart` — pure-function tests for each filter and sort key.
- Widget test: typing in the search box filters the list; clearing restores it.

### Definition of Done
- Search, filters, and sort are reactive and persistent within a page session.
- Empty-state message changes to "No matches for 'X'" when filters yield nothing.
- Performance: filter completes in <16 ms for 500 meds (verifiable via `flutter run --profile`).

**Complexity:** Low · **Risks:** None.

---

## 5. Calendar View of Scheduled Doses

**Objective:** Toggle between list and month calendar on the schedule page. Each day shows a dot per scheduled dose; tap a day to see the dose list for that day.

**Dependencies (pubspec):** `table_calendar: ^3.1.2`

### Implementation
- `ScheduleListPage` wraps its body in a `SegmentedButton` (List / Calendar) and toggles between the existing list and the new calendar.
- New `ScheduleCalendarPage` (or `ScheduleCalendarView` widget if we want to keep one scaffold):
  - Uses `TableCalendar` with `eventLoader: (day) => _doseCountFor(day)`.
  - `selectedDayPredicate` + `onDaySelected` to drive a `ListView` of doses for that day.
  - Markers colored by status: taken (green), skipped (orange), pending (gray), missed (red). To compute missed we need: a scheduled dose whose time is in the past and no matching `DoseLog`.
- New helper service `lib/features/schedule/domain/services/schedule_calendar_builder.dart` — pure function: given schedules + logs + a date, return a list of `CalendarDose {scheduledAt, status, medicationName}`. Status is computed against `DateTime.now()`.

### Files
- New: `features/schedule/presentation/pages/schedule_calendar_view.dart`, `features/schedule/presentation/widgets/calendar_dose_tile.dart`.
- New: `features/schedule/domain/services/schedule_calendar_builder.dart` + entity `calendar_dose.dart`.
- Modify: `schedule_list_page.dart` to add the toggle.

### Tests
- `schedule_calendar_builder_test.dart` — covers taken/skipped/pending/missed classifications.
- Widget test: tapping a day in the calendar updates the detail list.

### Definition of Done
- List ↔ Calendar toggle is instant and preserves selected day.
- Status colors match the existing dose action page.
- `flutter test test/features/schedule` green.

**Complexity:** Low-Medium · **Risks:** Time-zone handling around day boundaries; ensure all date math uses local time, not UTC.

---

## 6. Side-Effects & Symptom Diary

**Objective:** When logging a dose taken, optionally note side effects. A separate symptom diary lets the user log symptoms independently (vitals / general feelings) with severity. A timeline view shows the last 30 days.

**Dependencies (pubspec):** None new.

### Domain
- **New entity:** `features/symptoms/domain/entities/symptom_entry.dart` — `(String id, DateTime occurredAt, String label, SymptomSeverity severity, String? notes, String? relatedMedicationId)`.
- **New value object:** `SymptomSeverity { mild, moderate, severe }`.
- **New use cases:** `LogSymptom`, `GetSymptomsForDateRange(DateTimeRange)`, `WatchSymptoms`, `DeleteSymptom`.

### Data
- **New Hive box:** `symptoms_box` (add to `HiveBoxNames`).
- `SymptomLocalDataSourceImpl` (cache + watch pattern, mirrors `InventoryLocalDataSourceImpl`).
- `SymptomRepositoryImpl`.
- **DoseLog model extension:** add optional `sideEffect: String?` field. Hive reads must default missing key to null for backward compatibility.

### Presentation
- `features/symptoms/presentation/bloc/symptom_bloc.dart` — list + filter by date.
- `features/symptoms/presentation/pages/symptom_diary_page.dart` — chronological timeline grouped by date.
- `features/symptoms/presentation/pages/log_symptom_page.dart` — form with label, severity chips, optional note, optional link to a medication (searchable dropdown from inventory).
- **Dose-action integration:** in `dose_action_page.dart`, add a "Note side effects" expandable section that opens `log_symptom_page` pre-filled with `relatedMedicationId`.
- **Routing:** add `/symptoms` to the `ShellRoute` as a new nav destination? **Decision needed:** bottom nav now has 5 entries; adding a 6th exceeds Material 3 `NavigationBar`'s recommended max. Options: (a) replace `Settings` with `More` and move Settings under it; (b) put Symptoms under the `Profiles` page as a tab; (c) make Symptoms a sub-page only, no nav entry.

### Tests
- Bloc + use-case tests.
- Hive round-trip test for `symptoms_box` and the extended `DoseLog` model.

### Definition of Done
- Logging a symptom persists across restarts.
- Dose-action "side effects" expansion pre-fills the medication.
- Timeline shows at least 30 days of entries with correct grouping.

**Complexity:** Medium-High · **Risks:** Bottom-nav design decision (see above). Hive `DoseLog` schema migration is needed if the box is already populated.

---

## 7. Cloud Sync (Multi-Device)

**Objective:** Move from local-only storage to a real backend so the same data is available across devices, and so caregivers can hand off to each other. Largest single feature in scope.

**Dependencies (pubspec):**
- `firebase_core: ^3.6.0`
- `cloud_firestore: ^5.4.4`
- `firebase_auth: ^5.3.1` (or reuse existing `google_sign_in` flow and feed the ID token to Firestore)

**Note:** A `remove_firebase.py` script exists in the repo root, suggesting Firebase was previously removed. Confirm intent before reintroducing. Alternative: a self-hosted REST backend with `dio` (already in pubspec) and the existing `syncQueue` box. The Firebase path is recommended for time-to-market.

### Architecture
- Keep the local Hive cache as the source of truth for the UI (offline-first).
- Each feature's `RepositoryImpl` gains a `RemoteSyncService` dependency that mirrors writes to Firestore and pulls remote updates on connectivity change.
- One root collection per entity: `users/{uid}/medications`, `users/{uid}/schedules`, `users/{uid}/dose_logs`, `users/{uid}/profiles`, `users/{uid}/symptoms` (after feature 6).
- Document id = local UUID. Last-write-wins on `updatedAt`.

### Data
- `lib/core/sync/firestore_sync_service.dart` — generic `push<T>(collection, model)` and `watch<T>(collection)`.
- `lib/core/sync/sync_queue.dart` — persisted queue of pending writes for offline scenarios (the existing `syncQueue` Hive box is repurposed).
- Update each feature's `RepositoryImpl` to call `syncService` after local writes.

### Presentation
- `lib/core/sync/sync_status_cubit.dart` — exposes `idle | syncing | error` and last-synced timestamp.
- Settings page: "Last synced: 2 min ago" + "Sync now" button.
- App-wide `ConnectivityBanner` shows when offline and there's a pending queue.

### Security
- Firestore rules: `request.auth.uid == userId`.
- All writes go through the user's own subcollection; no cross-user reads.

### Tests
- `firestore_sync_service_test.dart` with `firebase_auth_mocks` and `cloud_firestore_mocks`.
- Integration test using Firebase Emulator Suite (manual setup).

### Definition of Done
- Add a medication on device A → within 30 s, the same medication is visible on device B (after pulling to refresh or auto-sync).
- Killing the app mid-write and reopening: the queued write is replayed.
- Disconnecting from the network: app continues to work; reconnecting triggers a sync that converges both sides.

**Complexity:** Very High · **Risks:**
- Requires a Firebase project + platform config (google-services.json, GoogleService-Info.plist).
- iOS/Android build config; Push notification setup if we want cross-device reminders.
- Cost: Firestore free tier is generous but watch document reads.
- Migration: existing local-only data needs a one-time upload flow on first run.

---

## 8. Drug Interaction Warnings

**Objective:** When a medication is added or edited, check it against the user's other active medications for known interactions and show a non-blocking warning before save.

**Dependencies:** None new at the Dart level. External API: **RxNav** `https://rxnav.nlm.nih.gov/InteractionAPIs.html` (no key, free for low-volume use). openFDA is a backup.

### Domain
- **New entity:** `DrugInteraction { String drugA, String drugB, String severity, String description }`.
- **New service:** `features/inventory/domain/services/interaction_checker.dart` — pure function: given a list of `Medication` and a candidate, return `List<DrugInteraction>`.
- **New use case:** `CheckInteractions(Medication candidate, List<Medication> existing)`.

### Data
- `features/inventory/data/datasources/drug_interaction_remote_datasource.dart`:
  - `getInteractionsForRxCui(String rxcui)` → calls `https://rxnav.nlm.nih.gov/REST/interaction/interaction.json?rxcui=...`.
- Resolve `name → rxcui` via `https://rxnav.nlm.nih.gov/REST/rxcui.json?name=...` (approximate match).
- Cache resolved rxcuis and interaction results in-memory for the session.

### Presentation
- `features/inventory/presentation/widgets/interaction_warning_card.dart` — collapsible card showing each interaction with severity-colored border.
- Wire into `MedicationFormPage._submit`:
  1. Build candidate `Medication`.
  2. Run `CheckInteractions` against existing meds.
  3. If non-empty, show a modal with the list + "Save anyway" / "Edit medication" buttons.
  4. Otherwise proceed to dispatch the bloc event.

### Tests
- `interaction_checker_test.dart` with a fake `DrugInteractionRemoteDataSource` returning canned responses.
- Widget test: form shows the warning modal when interactions are found.

### Definition of Done
- Adding a med with a known interaction surfaces a warning before save.
- User can override the warning.
- All API calls fail soft (no warning) if the network is unavailable — we never block save on this.

**Complexity:** Medium-High · **Risks:** RxNav returns interactions by RxCUI; we need to resolve brand/generic names to RxCUI, which is approximate. Edge cases: combination drugs with multiple active ingredients.

---

## 9. Home-Screen Widget (Next-Dose Glanceable)

**Objective:** A native home-screen widget that shows the next-up dose (medication name + time) and the time until it. Tapping the widget opens the app to the dose action page.

**Dependencies (pubspec):** `home_widget: ^0.7.0`

### Dart side
- `lib/core/widget/medication_widget_service.dart` — wraps `HomeWidget.saveWidgetData` and exposes:
  - `Future<void> updateNextDose({String? medicationName, DateTime? scheduledAt, String? subtitle})`
  - Called from `ScheduleBloc` on schedule changes and on dose logs.
- `WidgetPreviewService` computes the next-up dose for the active profile (mirrors logic already in `DashboardPage._todaysDoses`).

### Android
- `android/app/src/main/res/layout/widget_dose.xml` — minimal layout: 1× TextView for name, 1× TextView for time-until.
- `android/app/src/main/kotlin/.../HomeWidgetProvider.kt` — `AppWidgetProvider` that reads from `HomeWidget.widgetData` on `onUpdate`.
- Register the provider in `AndroidManifest.xml`.

### iOS
- `ios/Runner/MedicationWidget/` Swift widget extension files (WidgetKit, timeline provider, entry view).
- Configure App Group `group.com.drug.medmanager` in Xcode.
- `HomeWidget.widgetData` reads from the shared group.

### Background updates
- Use `workmanager` (already in pubspec) to schedule a daily refresh of the widget data — runs once per day to recompute "next dose" so the widget is correct even if the user never opens the app.

### Tests
- Unit test `MedicationWidgetService` with a `HomeWidget` mock (the package exposes a setter for testing).
- Widget UI test: golden image of the Android layout.

### Definition of Done
- Long-press home screen → add widget → shows "Next: Lisinopril 5 mg in 1 h 20 m".
- Tapping widget opens app to the dose action page for that schedule.
- Logging the dose updates the widget within 10 s.

**Complexity:** High (native iOS + Android work) · **Risks:** App Group provisioning profile on iOS is the usual gotcha; Android `AppWidgetProvider` callbacks are rate-limited, so the in-Dart refresh on every schedule change is essential.

---

## Cross-Cutting Concerns

- **Pubspec changes** must be made in a single PR per feature group to keep reviewable.
- **Build runner:** any new `@injectable` class triggers a `dart run build_runner build --delete-conflicting-outputs` step.
- **Hive migration:** any box with a schema change (features 6, possibly 8) needs a version bump and a migration routine in `HiveRegistrar.init()`.
- **Telemetry / analytics:** if we add any (e.g. Firebase Analytics), gate it behind a Settings consent toggle.
- **Accessibility:** all new screens must meet WCAG AA contrast, support dynamic font scaling, and provide `Semantics` labels for icons.

## Recommended Sequencing

1. **Adherence Dashboard** — pure additive, low risk, high visibility. Unblocks the "did the user actually take the meds?" question.
2. **Search / Filter / Sort** — small but unlocks inventory at scale.
3. **Refill Reminders** — reuses notifications infrastructure, addresses a real failure mode.
4. **Calendar View** — pairs with the adherence dashboard, same data sources.
5. **Side-Effects & Symptom Diary** — new feature, isolated blast radius.
6. **Drug Interaction Warnings** — high value, requires a stable inventory model (1–4 make the data cleaner first).
7. **Barcode Scanning** — convenience, more native integration work.
8. **Cloud Sync** — biggest, do last so the data model is stable.
9. **Home-Screen Widget** — finishes the cross-platform story.
