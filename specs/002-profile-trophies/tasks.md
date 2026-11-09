# Tasks: Profile Trophies and Collapsible Sections

**Input**: Design documents from `/specs/002-profile-trophies/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/trophy-ui-contract.md, quickstart.md

**Tests**: Required by the project constitution for financial calculations and statistics, and by the Definition of Done for empty states and accessibility. Test tasks are included below.

**Organization**: Tasks are grouped by user story so each story can be implemented, tested, and delivered independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Single Flutter application at the repository root: `lib/` and `test/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Confirm the baseline and add shared localization resources.

- [X] T001 Verify the baseline by running `flutter pub get`, `flutter analyze`, and `flutter test`; confirm all pass before starting.
- [X] T002 [P] Add new keys to `lib/l10n/app_en.arb` and `lib/l10n/app_it.arb` for `trophies`, `trophyTopExpenseCategoryCurrentMonth`, `trophyHighestExpenseCurrentMonth`, `trophyHighestIncomeAllTime`, `trophyTopExpenseCategoryAllTime`, `trophyHighestExpenseAllTime`, `trophyEmpty`, `trophyRanking`, `currentMonth`, and `allTime`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared data contracts required by the user stories.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 [P] Add the `ProfileSection` enum and the `profileQuestsExpanded` and `profileStatsExpanded` boolean fields to `lib/models/settings.dart`; both fields default to `true` and must be included in `copyWith`, `toJson`, and `fromJson`, with missing JSON fields falling back to `true`.
- [X] T004 [P] Add `TrophyKind` (five values), `TrophyPeriod` (`currentMonth`, `allTime`), `TrophySubjectType` (`category`, `expense`, `income`), `Trophy`, and `TrophyRankingEntry` to `lib/models/trophy.dart`; enforce `value > 0`, exactly one subject identifier, `entries.length <= 3`, and value-desc/date-asc/id-asc ordering.
- [X] T005 Add `isProfileSectionExpanded(ProfileSection section)` and `setProfileSectionExpanded(ProfileSection section, bool expanded)` to `lib/state/app_state.dart`, persisting through the existing `_persist()` flow.
- [X] T006 Run `flutter gen-l10n` and confirm `lib/l10n/generated/` regenerates without errors.

**Checkpoint**: Foundation ready - user stories can now begin.

---

## Phase 3: User Story 1 - Collapse and expand profile sections (Priority: P1) 🎯 MVP

**Goal**: Make the Quests and Stats sections independently collapsible and persist their state.

**Independent Test**: Open the profile, collapse and expand each section, restart the app, and verify each section keeps its previous state while the other is unaffected.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation.**

- [X] T007 [P] [US1] Add widget tests in `test/ui/screens/profile_screen_test.dart` for independent collapse/expand, chevron state, and persistence through `AppState` after a rebuild.
- [X] T008 [P] [US1] Add a settings compatibility test in `test/models/settings_test.dart` verifying that JSON without the new fields loads both sections as expanded.

### Implementation for User Story 1

- [X] T009 [US1] Implement a reusable collapsible section header in `lib/ui/profile_screen.dart` with the section title, a state chevron, a full-row tap target of at least 48x48 logical pixels, and expanded/collapsed accessibility semantics.
- [X] T010 [US1] Wire the Quests and Stats sections in `lib/ui/profile_screen.dart` to `Settings.profileQuestsExpanded` and `Settings.profileStatsExpanded` through `AppState`, keeping the quest availability logic, daily-limit overlay, reset countdown, and statistic progress bars unchanged when expanded.

**Checkpoint**: User Story 1 is fully functional and independently testable.

---

## Phase 4: User Story 2 - View personal trophy cards (Priority: P2)

**Goal**: Show the five personal trophy cards with correct values, subjects, periods, and empty states.

**Independent Test**: With a known transaction dataset, open the profile and verify each of the five trophy cards shows the expected record and value.

### Tests for User Story 2

- [X] T011 [P] [US2] Add unit tests in `test/services/trophy_service_test.dart` covering all five trophies, ties (oldest wins), refunded expenses excluded, installment attribution, uncategorized and unknown categories, future-dated transactions, zero amounts, and empty data.

### Implementation for User Story 2

- [X] T012 [P] [US2] Implement the pure trophy calculator in `lib/services/trophy_service.dart` with period filtering, eligibility rules, category aggregation from `ExpenseAllocation`, unknown/null categories mapped to `no_category`, the value-desc/date-asc/id-asc comparator, and at most three ranking entries.
- [X] T013 [US2] Expose computed trophies from `lib/state/app_state.dart` through a `List<Trophy> get trophies` accessor that calls `TrophyService` with the current local date and the in-memory expenses and categories.
- [X] T014 [US2] Add the trophies section with the five cards to `lib/ui/profile_screen.dart`, showing localized titles, `formatCurrency` values, subject names (resolving `no_category` to `strings.noCategory`), periods, transaction dates, and a localized empty state for trophies without entries.

**Checkpoint**: User Story 2 is fully functional and independently testable; cards are display-only until User Story 3 wires navigation.

---

## Phase 5: User Story 3 - Open trophy rankings (Priority: P3)

**Goal**: Open a full-screen top-three ranking from each trophy card with deterministic ordering.

**Independent Test**: From a trophy card, open the ranking and verify the first three elements and their order, including ties and fewer-than-three cases.

### Tests for User Story 3

- [X] T015 [P] [US3] Add widget tests in `test/ui/screens/trophy_ranking_screen_test.dart` verifying the three-entry limit, value-desc/date-asc ordering, fewer-than-three behavior, the trophy title, and the back action.

### Implementation for User Story 3

- [X] T016 [US3] Create `lib/ui/trophy_ranking_screen.dart` as a full-screen view with the localized trophy title in the app bar, up to three ranked rows showing position, subject, formatted value, and date, plus an empty guard.
- [X] T017 [US3] Add `AppRouter.showTrophyRanking(BuildContext context, {required Trophy trophy})` to `lib/navigation/app_router.dart`, pushing a `MaterialPageRoute` consistent with `showExpenseDetails`.
- [X] T018 [US3] Make trophy cards in `lib/ui/profile_screen.dart` tappable when they have at least one ranking entry and open the ranking; keep empty cards non-interactive.

**Checkpoint**: All three user stories are independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Quality gates and validation across all stories.

- [X] T019 [P] Review all new ARB entries in `lib/l10n/app_en.arb` and `lib/l10n/app_it.arb` and confirm no hardcoded user-facing text or currency symbols remain.
- [X] T020 [P] Add or complete accessibility semantics for collapsible headers, trophy cards, and ranking rows, and assert them in the existing widget tests.
- [X] T021 [P] Verify the trophy calculation is a single pass over expenses with no network calls, no persistence of derived values, and no redundant recalculation on every build; document the result in `specs/002-profile-trophies/quickstart.md` if any deviation is found.
- [X] T022 Run `flutter analyze` and `flutter test`; fix all errors and failures.
- [X] T023 Run the manual scenarios in `specs/002-profile-trophies/quickstart.md` and record the outcome.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately.
- **Foundational (Phase 2)**: Depends on Setup; blocks all user stories.
- **User Stories (Phases 3-5)**: Depend on Foundational completion.
  - US1 and US2 can run in parallel.
  - US3 depends on US2 because it wires navigation into the trophy cards.
- **Polish (Phase 6)**: Depends on all desired user stories.

### User Story Dependencies

- **User Story 1 (P1)**: No dependencies on other stories.
- **User Story 2 (P2)**: No dependencies on US1; uses the foundational `Trophy` models.
- **User Story 3 (P3)**: Depends on US2 for the trophy cards and their entries; the `Trophy` model itself is foundational.

### Within Each User Story

- Tests first and failing before implementation.
- Models before services.
- Services before UI wiring.
- Story complete and validated before moving to the next priority.

### Parallel Opportunities

- T002 can run alongside T003 and T004.
- T003 and T004 are independent files.
- T007 and T008 are independent test files.
- T011 and T012 are independent files (test vs service).
- T015 can be written while T016 and T017 are implemented.
- T019, T020, and T021 are independent polish checks.

---

## Parallel Example: User Story 2

```bash
# Launch the service test and the service implementation together:
Task: "Add unit tests in test/services/trophy_service_test.dart"
Task: "Implement the pure trophy calculator in lib/services/trophy_service.dart"
```

## Parallel Example: User Story 1

```bash
# Launch the two independent test tasks together:
Task: "Add widget tests in test/ui/screens/profile_screen_test.dart"
Task: "Add settings compatibility test in test/models/settings_test.dart"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup.
2. Complete Phase 2: Foundational.
3. Complete Phase 3: User Story 1.
4. **STOP and VALIDATE**: collapse/expand and restart behavior.
5. Deploy or demo if ready.

### Incremental Delivery

1. Setup + Foundational → foundation ready.
2. User Story 1 → validate independently (MVP).
3. User Story 2 → validate the five trophy cards (main user value).
4. User Story 3 → validate rankings.
5. Polish → run quality gates and manual scenarios.

### Parallel Team Strategy

1. Complete Setup + Foundational together.
2. Once foundational is done:
   - Developer A: User Story 1.
   - Developer B: User Story 2.
3. After User Story 2: Developer C (or B) completes User Story 3.
4. Polish together.

---

## Notes

- [P] tasks touch different files and have no incomplete dependencies.
- [Story] labels map each task to its user story for traceability.
- Every task includes an exact file path.
- Tests must fail before the corresponding implementation is written.
- Commit after each task or logical group.
- Stop at each checkpoint to validate the story independently.
