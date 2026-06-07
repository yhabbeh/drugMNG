# PROGRESS.md
# Feature Backlog Tracker

Live status board for the nine features scoped in `FUTURE_FEATURES.md`. Update status and check off sub-tasks as work progresses.

---

## Status Legend

`[ ]` not started · `[~]` in progress · `[x]` done · `[!]` blocked · `[-]` cancelled

**Phase:** `P0` next-up · `P1` after P0 · `P2` later

---

## Quick Status

| # | Feature | Phase | Status | Owner | Started | Notes |
|---|---|---|---|---|---|---|
| 1 | Adherence Dashboard | P0 | `[x]` | opencode | 2026-06-04 | Done; 12 new tests pass |
| 2 | Search / Filter / Sort | P0 | `[x]` | opencode | 2026-06-04 | Done; 26 new tests pass |
| 3 | Refill Reminders | P0 | `[ ]` | — | — | Needs PRN edge-case decision |
| 4 | Calendar View | P1 | `[ ]` | — | — | Pairs with #1 |
| 5 | Symptoms Diary | P1 | `[ ]` | — | — | Awaiting nav-decision |
| 6 | Drug Interactions | P1 | `[ ]` | — | — | RxNav, no key required |
| 7 | Barcode Scanning | P2 | `[ ]` | — | — | Needs camera permission UX |
| 8 | Cloud Sync | P2 | `[ ]` | — | — | Awaiting backend decision |
| 9 | Home-Screen Widget | P2 | `[ ]` | — | — | Native iOS + Android |

---

## Open Decisions

- [ ] **Symptoms nav (Feature 5):** 6th bottom-nav destination vs. `More` menu vs. sub-page only? — _owner: you_
- [ ] **Cloud sync backend (Feature 8):** re-introduce Firebase (fastest) vs. self-hosted REST (more control)? — _owner: you_
- [ ] **PRN refill estimate (Feature 3):** exclude PRN schedules from auto-prediction, or add manual "expected days" field per medication? — _owner: you_

---

## 1. Adherence Dashboard — `[x]`

> Source plan: `FUTURE_FEATURES.md §1` · Phase P0

### Pubspec
- [x] Add `fl_chart: ^0.69.0`

### Domain
- [x] `features/adherence/domain/entities/adherence_summary.dart`
- [x] `features/adherence/domain/entities/daily_adherence_point.dart`
- [x] `features/adherence/domain/entities/adherence_range.dart`
- [x] `features/adherence/domain/entities/missed_dose.dart`
- [x] `features/adherence/domain/usecases/get_adherence_summary.dart`
- [x] `features/adherence/domain/usecases/get_missed_doses.dart`

### Presentation
- [x] `features/adherence/presentation/bloc/adherence_bloc.dart` (with event + state files)
- [x] `features/adherence/presentation/pages/adherence_page.dart`
- [x] `widgets/adherence_summary_card.dart`
- [x] `widgets/adherence_bar_chart.dart`
- [x] `widgets/missed_dose_tile.dart`
- [x] `widgets/range_selector.dart`

### Wiring
- [x] Add `AppRoutes.adherence = '/adherence'`
- [x] Register bloc in `MultiBlocProvider` (main.dart) and DI (use cases via `@injectable` + regen)
- [x] 4th "Adherence" stat card in `_QuickStatsRow` on `dashboard_page.dart` linking to `/adherence`

### Tests
- [x] `get_adherence_summary_test.dart` (6 cases: zero, aggregation, streak-3, streak-broken-by-missed, failure propagation, range iteration count)
- [x] `adherence_bloc_test.dart` (6 cases: initial state, start→loaded, range change, error, refresh, entity equality)
- [x] `flutter test test/features/adherence` → 12/12 pass
- [x] `flutter analyze lib/features/adherence` → 0 issues

### Done when
- [x] Page reachable, window selector updates chart, empty state present, all tests pass.

### Implementation notes
- Use cases iterate day-by-day using `GetDoseLogsForDate` (parallelized via `Future.wait`), then aggregate counts and compute a streak ending at the most recent logged day.
- `AdherenceSummary.adherencePercent` is taken / (taken+skipped+missed); `pending` is reported separately.
- "Missed dose" = explicit `DoseStatus.missed` OR a past `DoseStatus.pending` (no action taken). Sorted newest-first. Page shows the most recent 10 with a "+ N more" footer.
- 3 summary cards: Adherence %, Day Streak, Missed Doses (per plan).
- Dashboard wiring: 4-column `_QuickStatsRow` (Active / Total / Expiring / Adherence), with AdherenceBloc dispatched in `_load(profileId)`.
- `AdherenceBloc` not annotated with `@injectable`; instantiated manually in `main.dart` (matches the `SettingsCubit` pattern).
- Naming deviation from plan: enum called `AdherenceRange` (plan: `AdherenceWindow`) and event called `AdherenceRefreshed` (plan: `AdherenceRefreshRequested`); same shape, more idiomatic Dart.

---

## 2. Search / Filter / Sort — `[x]`

> Source plan: `FUTURE_FEATURES.md §4` · Phase P0

### Domain
- [x] `features/inventory/domain/services/inventory_filter.dart` — `InventoryFilters` value object + `InventoryFilter` pure service (`apply(source, filters) → filtered+sorted`)

### Presentation
- [x] `widgets/inventory_search_bar.dart` — 250 ms debounced `TextField` with `prefixIcon: search`, `suffixIcon: clear` (auto-shown when non-empty)
- [x] `widgets/inventory_filter_chips.dart` — horizontal `ListView` of `FilterChip`s: one per `DrugForm` + "Low stock" + "Expiring soon"
- [x] `widgets/inventory_sort_menu.dart` — `PopupMenuButton<InventorySort>` with 5 options (name asc/desc, expiration asc, stock asc, recently added), current item marked
- [x] Modify `inventory_list_page.dart` — `InventoryFilters _filters` local state, recompute via `_filter.apply()` each build, `Sort` action in AppBar, `Clear filters` action when any filter is active, `_FilterSummary` ("Showing N of M") line, `_NoMatchesView` with "No matches for 'X'" copy

### Tests
- [x] `inventory_filter_test.dart` — 23 cases: query (name/manufacturer/notes/case/trim), `formFilter`, `lowStockOnly` (with/without threshold), `expiringSoonOnly` (incl. past expired), combined filters, all 5 sort keys, mutation-safety, empty source
- [x] `inventory_search_bar_test.dart` — 3 widget tests: debounced onChanged, clear-button emits empty + hides icon, initialValue change updates controller
- [x] `flutter test test/features/inventory` → 84/84 pass
- [x] `flutter analyze lib/features/inventory/presentation` → 0 new issues

### Done when
- [x] Filters reactive, "Showing N of M" summary, empty-state copy reflects filters.

### Implementation notes
- All filter+sort logic in a single `InventoryFilter` service; page just calls `apply(meds, _filters)` each build — no `setState` work, no derived `List` cached.
- Search debounce lives in `InventorySearchBar` (250 ms `Timer`); state still flows through the page.
- `InventoryFilters.isDefault` gates the "Showing N of M" line and the `Clear filters` action.
- `_NoMatchesView` copy depends on whether `query` is empty (search-based) or filters-only.
- Sort key decoupled from filter chips; persisted within the page session.

---

## 3. Refill Reminders — `[ ]`

> Source plan: `FUTURE_FEATURES.md §3` · Phase P0

### Domain
- [ ] `features/inventory/domain/services/refill_calculator.dart`
- [ ] `features/inventory/domain/entities/refill_alert.dart`
- [ ] `features/inventory/domain/usecases/get_refill_alerts.dart`
- [ ] `features/inventory/domain/usecases/schedule_refill_reminders.dart`

### Notifications
- [ ] Extend `NotificationScheduler` with `scheduleRefillAlert(...)`
- [ ] Implement in `NotificationSchedulerImpl`
- [ ] Decide id-scheme offset to avoid collision with dose reminders

### Presentation
- [ ] `features/inventory/presentation/cubit/refill_alert_cubit.dart`
- [ ] Add banner on `dashboard_page.dart` when alerts exist
- [ ] Add "Refill soon" pill on `inventory_list_page.dart` cards

### Settings integration
- [ ] Add `refillAlertDays` to `SettingsState` + `SettingsCubit`
- [ ] Add "Refill alert window" tile to settings page
- [ ] Add "Reschedule refill reminders" button

### Tests
- [ ] `refill_calculator_test.dart` — daily / weekly / PRN cases
- [ ] `refill_alert_cubit_test.dart`

### Done when
- [ ] Banner appears, OS notification fires at 09:00 on predicted empty day, settings tile persists.

---

## 4. Calendar View — `[ ]`

> Source plan: `FUTURE_FEATURES.md §5` · Phase P1

### Pubspec
- [ ] Add `table_calendar: ^3.1.2`

### Domain
- [ ] `features/schedule/domain/entities/calendar_dose.dart`
- [ ] `features/schedule/domain/services/schedule_calendar_builder.dart`

### Presentation
- [ ] `features/schedule/presentation/pages/schedule_calendar_view.dart`
- [ ] `features/schedule/presentation/widgets/calendar_dose_tile.dart`
- [ ] Add List/Calendar `SegmentedButton` to `schedule_list_page.dart`

### Tests
- [ ] `schedule_calendar_builder_test.dart` — taken / skipped / pending / missed
- [ ] Widget test: day tap updates detail list

### Done when
- [ ] Toggle is instant, colors match dose action page, all date math uses local time.

---

## 5. Symptoms Diary — `[ ]`

> Source plan: `FUTURE_FEATURES.md §6` · Phase P1 · _blocked on nav decision_

### Data
- [ ] Add `symptoms_box` to `HiveBoxNames`
- [ ] `features/symptoms/data/datasources/symptom_local_datasource.dart`
- [ ] `features/symptoms/data/models/symptom_entry_model.dart`
- [ ] `features/symptoms/data/repositories/symptom_repository_impl.dart`
- [ ] Extend `DoseLog` model with optional `sideEffect: String?`
- [ ] Hive schema migration in `HiveRegistrar.init()`

### Domain
- [ ] `features/symptoms/domain/entities/symptom_entry.dart`
- [ ] `features/symptoms/domain/entities/symptom_severity.dart`
- [ ] `features/symptoms/domain/repositories/symptom_repository.dart`
- [ ] `domain/usecases/log_symptom.dart`
- [ ] `domain/usecases/get_symptoms_for_date_range.dart`
- [ ] `domain/usecases/watch_symptoms.dart`
- [ ] `domain/usecases/delete_symptom.dart`

### Presentation
- [ ] `features/symptoms/presentation/bloc/symptom_bloc.dart`
- [ ] `pages/symptom_diary_page.dart` — 30-day timeline
- [ ] `pages/log_symptom_page.dart` — form with severity chips + medication picker
- [ ] Wire "Note side effects" expansion in `dose_action_page.dart` to prefill `relatedMedicationId`

### Routing
- [ ] Decide placement (nav destination / More menu / sub-page)
- [ ] Add route(s)

### Tests
- [ ] Hive round-trip for `symptoms_box` and extended `DoseLog`
- [ ] Bloc + use case tests

### Done when
- [ ] Symptom entries persist, link to medications, group correctly in timeline.

---

## 6. Drug Interaction Warnings — `[ ]`

> Source plan: `FUTURE_FEATURES.md §8` · Phase P1

### Domain
- [ ] `features/inventory/domain/entities/drug_interaction.dart`
- [ ] `features/inventory/domain/services/interaction_checker.dart`
- [ ] `features/inventory/domain/usecases/check_interactions.dart`

### Data
- [ ] `features/inventory/data/datasources/drug_interaction_remote_datasource.dart` (RxNav + openFDA fallback)
- [ ] Session cache for rxcui resolutions and interaction lookups
- [ ] Fail-soft: never block save on lookup failure

### Presentation
- [ ] `features/inventory/presentation/widgets/interaction_warning_card.dart`
- [ ] Wire into `medication_form_page.dart` `_submit` flow: show modal before dispatching bloc event

### Tests
- [ ] `interaction_checker_test.dart` with fake datasource
- [ ] Widget test: warning modal appears when interactions found

### Done when
- [ ] Warnings surface before save, user can override, network failure does not block.

---

## 7. Barcode Scanning — `[ ]`

> Source plan: `FUTURE_FEATURES.md §2` · Phase P2

### Pubspec
- [ ] Add `mobile_scanner: ^5.2.3`
- [ ] Add `permission_handler: ^11.3.1`

### Platform config
- [ ] Android: add `CAMERA` permission to manifest
- [ ] iOS: add `NSCameraUsageDescription` to Info.plist
- [ ] Gate scan button by `defaultTargetPlatform` (hide on Simulator/desktop)

### Domain
- [ ] `features/inventory/domain/entities/scanned_drug.dart`
- [ ] `features/inventory/domain/usecases/lookup_drug_by_barcode.dart`

### Data
- [ ] `features/inventory/data/datasources/drug_lookup_remote_datasource.dart` (openFDA + RxNorm)
- [ ] `features/inventory/data/repositories/drug_lookup_repository_impl.dart`

### Presentation
- [ ] `features/inventory/presentation/pages/barcode_scanner_page.dart`
- [ ] `features/inventory/presentation/widgets/barcode_field.dart`
- [ ] Wire into `medication_form_page.dart` with prefilled controllers

### Routing
- [ ] Add `AppRoutes.barcodeScanner = '/inventory/scan'`

### Tests
- [ ] `drug_lookup_remote_datasource_test.dart` with HTTP mock
- [ ] Widget test: scan prefills form fields

### Done when
- [ ] Scan button visible, camera permission handled, successful scan prefills name.

---

## 8. Cloud Sync — `[ ]`

> Source plan: `FUTURE_FEATURES.md §7` · Phase P2 · _blocked on backend decision_

### Pubspec (Firebase path)
- [ ] Add `firebase_core: ^3.6.0`
- [ ] Add `cloud_firestore: ^5.4.4`
- [ ] Add `firebase_auth: ^5.3.1`

### Alternative (self-hosted path)
- [ ] Confirm `dio` interceptor pattern handles auth-token refresh
- [ ] Document API contract for the new endpoints

### Core sync layer
- [ ] `lib/core/sync/firestore_sync_service.dart` (or `rest_sync_service.dart`)
- [ ] `lib/core/sync/sync_queue.dart` — repurpose existing `syncQueue` Hive box
- [ ] `lib/core/sync/sync_status_cubit.dart`
- [ ] Connectivity banner widget

### Data
- [ ] Update each feature's `RepositoryImpl` to call sync after local writes
- [ ] Mirror reads (cache-aside) for inventory / schedules / logs / profiles / symptoms
- [ ] One-time upload migration for existing local-only data on first run

### Security (Firebase)
- [ ] Firestore rules: `request.auth.uid == userId`
- [ ] Confirm `google-services.json` / `GoogleService-Info.plist` provided
- [ ] App Check (optional but recommended)

### Settings
- [ ] "Last synced" timestamp
- [ ] "Sync now" button
- [ ] Pending-queue count

### Tests
- [ ] `sync_service_test.dart` with mocks
- [ ] Integration test against Firebase Emulator Suite (manual setup)
- [ ] Offline-then-online replay test

### Done when
- [ ] Multi-device convergence within 30 s, offline writes replay on reconnect, no data loss across hard kill.

---

## 9. Home-Screen Widget — `[ ]`

> Source plan: `FUTURE_FEATURES.md §9` · Phase P2

### Pubspec
- [ ] Add `home_widget: ^0.7.0`

### Dart
- [ ] `lib/core/widget/medication_widget_service.dart`
- [ ] `lib/core/widget/widget_preview_service.dart` — next-dose computation
- [ ] Trigger widget update from `ScheduleBloc` on schedule changes and dose logs

### Android
- [ ] `android/app/src/main/res/layout/widget_dose.xml`
- [ ] `android/app/src/main/kotlin/.../HomeWidgetProvider.kt`
- [ ] Register provider in `AndroidManifest.xml`
- [ ] Schedule daily refresh via `workmanager` (already in pubspec)

### iOS
- [ ] `ios/Runner/MedicationWidget/` Swift widget extension (WidgetKit + timeline provider)
- [ ] Configure App Group `group.com.drug.medmanager` in Xcode
- [ ] `HomeWidget.widgetData` reads from shared group

### Tests
- [ ] Unit test `MedicationWidgetService` with `HomeWidget` mock
- [ ] Golden image of Android layout

### Done when
- [ ] Widget shows "Next: …" with time-until, tap opens dose-action page, updates within 10 s after dose logged.

---

## Cross-Cutting Backlog

- [ ] Decide Symptoms nav placement (Feature 5)
- [ ] Decide cloud-sync backend (Feature 8)
- [ ] Decide PRN handling for refill estimate (Feature 3)
- [ ] Settings: add consent toggle before any analytics (post Feature 8)
- [ ] Accessibility audit pass on all new screens (dynamic font scaling, contrast, `Semantics`)
- [ ] Each new feature PR should run: `flutter pub get` · `dart run build_runner build --delete-conflicting-outputs` (if any new `@injectable`) · `flutter analyze` · `flutter test`

---

## Changelog

- **2026-06-04** — Initial plan created. `FUTURE_FEATURES.md` + `PROGRESS.md` added.
