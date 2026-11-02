---

description: "Task list for the month-year picker layout fix"
---

# Tasks: Fix Month-Year Picker Layout

**Input**: Design documents from `/specs/001-fix-calendar-popup-layout/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/month-year-picker-contract.md, quickstart.md

**Tests**: Included. The feature specification defines measurable outcomes (SC-001, SC-002, SC-005) and the plan records the widget-test decision (research.md, D6), so test tasks are part of the scope.

**Organization**: Tasks are grouped by user story so each story can be implemented, tested and delivered on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story the task belongs to (US1, US2, US3)
- Every task lists the exact file path it touches

## Path Conventions

Single Flutter project: application code under `lib/`, tests under `test/`, feature documents under `specs/001-fix-calendar-popup-layout/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Small shared pieces both the dialog and its tests need.

- [ ] T001 [P] Add `List<DateTime> monthsOfYear(int year)` returning the twelve first-of-month dates of `year` in `lib/utils/date_utils.dart`, documented in English and covered by the grid tests
- [ ] T002 [P] Create the widget-test harness `pumpPicker` (wraps `showAppMonthYearPicker` in a `MaterialApp` with `Localizations.override` for `en`/`it`, a configurable viewport size and text scale, and returns the tapped result) in `test/ui/widgets/picker_test_harness.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The shared dialog shell every story builds on.

**⚠️ CRITICAL**: No user story work can begin until this task is complete.

- [ ] T003 Create `Future<DateTime?> showAppMonthYearPicker({required BuildContext context, required DateTime initialDate, required DateTime firstDate, required DateTime lastDate, required Locale locale})` plus the stateful `MonthYearPickerDialog` shell in `lib/ui/widgets/month_year_picker_dialog.dart`: `Dialog` with 16 px horizontal and 24 px vertical insets, header showing the localized month and year, year stepper that stops at `firstDate.year`/`lastDate.year`, cancel action, `null` on dismissal, and the state invariants INV-1 to INV-5 from `data-model.md`

**Checkpoint**: Entry function exists and the dialog opens and closes, so all stories can proceed.

---

## Phase 3: User Story 1 - Read the full month grid inside the popup (Priority: P1) 🎯 MVP

**Goal**: Tapping the date label on the home screen opens a popup where all twelve month names are complete and inside the dialog, and selecting one switches the month.

**Independent Test**: From the home screen, tap the top-left date label; verify twelve complete month names are visible inside the popup, tap a month and confirm the home screen switches to it.

### Tests for User Story 1

- [ ] T004 [US1] Write widget tests in `test/ui/widgets/month_year_picker_labels_test.dart` asserting that the English dialog shows the twelve complete names (`January` … `December`) and that tapping a month returns the first day of that month, using the harness from T002

### Implementation for User Story 1

- [ ] T005 [US1] Implement the month grid in `lib/ui/widgets/month_year_picker_dialog.dart`: twelve cells built from `monthsOfYear`, labels from `DateFormat.MMMM(locale)` (contract C-2), out-of-range months rendered disabled (INV-3), tap returns the first day of the selected month, dialog closes on selection
- [ ] T006 [US1] Replace `showMonthYearPicker` with `showAppMonthYearPicker` in `_pickMonth` of `lib/ui/home_screen.dart`, passing `initialDate: _currentMonth`, `firstDate: DateTime(2018, 1)`, `lastDate: DateTime(2100, 12)` and the app locale

**Checkpoint**: User Story 1 is fully functional and independently testable.

---

## Phase 4: User Story 2 - Same readable calendar on any screen size and text size (Priority: P2)

**Goal**: The dialog adapts to narrow widths, landscape and large system text scales without clipping or truncating labels.

**Independent Test**: Render the dialog at 320 dp width, in landscape, and with a 2.0 text scale; confirm every label is complete, nothing overflows and the grid scrolls when needed.

### Tests for User Story 2

- [ ] T007 [US2] Write widget tests in `test/ui/widgets/month_year_picker_adaptive_test.dart` covering narrow width (320 dp), landscape, and text scale 2.0, asserting that `tester.takeException()` is `null` and that all twelve labels are complete (contract C-1, C-3, C-4)

### Implementation for User Story 2

- [ ] T008 [US2] Implement responsive sizing in `lib/ui/widgets/month_year_picker_dialog.dart` per research.md D3: width from `MediaQuery` minus 32 capped at 400, three columns at default scale, two columns when the text scale is large or the width is very small, `FittedBox(scaleDown)` as last-resort label fit, and a vertically scrollable grid region when the content cannot fit
- [ ] T009 [US2] Add accessibility to `lib/ui/widgets/month_year_picker_dialog.dart`: semantics label with the complete localized month name plus year, selected and disabled states announced, and tap targets of at least 48 x 48 logical pixels (contract accessibility section, FR-009)

**Checkpoint**: User Stories 1 and 2 both work independently.

---

## Phase 5: User Story 3 - Consistent calendar in the statistics month selector (Priority: P3)

**Goal**: The statistics screen uses the same dialog, so its month selector shows the same complete, contained labels.

**Independent Test**: Open the statistics screen, tap the month selector and confirm identical behavior to the home screen.

### Implementation for User Story 3

- [ ] T010 [US3] Replace `showMonthYearPicker` with `showAppMonthYearPicker` in `_pickMonth` of `lib/ui/current_stats_screen.dart`, keeping the same date bounds and locale

### Tests for User Story 3

- [ ] T011 [P] [US3] Write a widget test in `test/ui/screens/current_stats_month_picker_test.dart` that opens the picker from `CurrentStatsScreen` (with a `Provider` supplying `AppState` created against mocked `SharedPreferences`) and asserts the same twelve complete month labels (contract C-6)

**Checkpoint**: All three user stories are independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Remove the replaced dependency and validate the whole feature.

- [ ] T012 [P] Remove the `month_year_picker` entry from `pubspec.yaml`
- [ ] T013 [P] Remove the `MonthYearPickerLocalizations.delegate` entry and the related import from `lib/app.dart`
- [ ] T014 Confirm no residual references remain by searching `lib/` and `test/` for `month_year_picker` and `MonthYearPicker`, and confirm `pickerLocale` in `lib/utils/date_utils.dart` is still used by the day pickers in `lib/ui/expense_form_screen.dart`
- [ ] T015 Run `flutter pub get`, `flutter analyze` and `flutter test` from the repository root (`pubspec.yaml`) in CI, and fix any failure until analyze is clean and the suite is green
- [ ] T016 Execute the manual scenarios of `specs/001-fix-calendar-popup-layout/quickstart.md` on a device (portrait, 320 dp width, text scale 2.0, landscape, English, Italian, statistics screen, screen reader) and record the outcomes in the pull request description

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: no dependencies, can start immediately
- **Foundational (Phase 2)**: depends on Setup; blocks all user stories
- **User Stories (Phase 3+)**: all depend on Foundational; then proceed in priority order or in parallel
- **Polish (Phase 6)**: depends on US1, US2 and US3 being complete

### User Story Dependencies

- **US1 (P1)**: starts after Phase 2; no dependency on other stories
- **US2 (P2)**: starts after Phase 2, but its tests assume the grid from T005; it refines the same file as T005 so it must follow US1 in practice
- **US3 (P3)**: starts after Phase 2; its test assumes the dialog from T003/T005

### Within Each User Story

- Tests first, then the implementation that makes them pass
- Core dialog work before screen wiring
- Story complete and validated before moving to the next priority

### Parallel Opportunities

- T001 and T002 can run in parallel (different files)
- T012 and T013 can run in parallel (different files)
- T011 can run in parallel with T015 once screens are wired
- US1, US2 and US3 touch the same dialog file (`lib/ui/widgets/month_year_picker_dialog.dart`) in T005, T008 and T009, so those three tasks must stay sequential

---

## Parallel Example: Setup

```bash
Task: "T001 Add monthsOfYear helper in lib/utils/date_utils.dart"
Task: "T002 Create pumpPicker harness in test/ui/widgets/picker_test_harness.dart"
```

## Parallel Example: Polish

```bash
Task: "T012 Remove month_year_picker from pubspec.yaml"
Task: "T013 Remove MonthYearPickerLocalizations delegate from lib/app.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 (T001, T002) and Phase 2 (T003)
2. Complete Phase 3 (T004, T005, T006)
3. **STOP and VALIDATE**: open the popup on the reported device; the twelve month names must be complete and contained
4. Ship the MVP if the primary defect is gone

### Incremental Delivery

1. Foundation (T003) → dialog opens
2. US1 → readable grid on the home screen (MVP)
3. US2 → readable grid on any size and text scale
4. US3 → same dialog in the statistics screen
5. Polish → dependency removed, gates green, manual validation recorded

---

## Notes

- [P] tasks touch different files and have no pending dependency
- The dialog file `lib/ui/widgets/month_year_picker_dialog.dart` is touched by T003, T005, T008 and T009; never run those in parallel
- The test files `test/ui/widgets/month_year_picker_labels_test.dart` and `test/ui/widgets/month_year_picker_adaptive_test.dart` are separate so US1 and US2 tests do not collide
- Month names must come from `intl`; do not add ARB keys and do not hardcode labels
- `flutter analyze` and `flutter test` are mandatory before considering the feature done
- Commit after each logical group of tasks
