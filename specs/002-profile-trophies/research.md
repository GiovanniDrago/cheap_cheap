# Phase 0 Research: Profile Trophies and Collapsible Sections

## Decision 1: Put trophy calculation in a pure service

**Decision**: Implement all trophy and ranking calculations as pure functions in
`lib/services/trophy_service.dart`, operating on `List<Expense>`, `List<Category>`, and an
explicit reference date.

**Rationale**: The constitution requires statistics to be produced by a single domain layer and
for changes to financial calculations to be tested. Pure functions are deterministic, testable
without widgets or storage, and avoid duplicating aggregation rules inside the profile widget.

**Alternatives considered**:
- Compute inline in `profile_screen.dart`: rejected because it mixes presentation with financial
  logic and is hard to unit test.
- Add methods to `AppState`: viable, but `AppState` already mixes persistence, sync, quests, and
  settings; a separate service keeps the calculation isolated and reusable by the ranking screen.

## Decision 2: Compute on demand from in-memory data

**Decision**: Calculate trophies during profile build from `AppState.expenses` and
`AppState.categories`; do not persist trophies or cache them.

**Rationale**: The transaction list is already loaded in memory, the dataset is personal-scale, and
derived values must never go stale. Recomputing avoids cache invalidation bugs after add, edit,
delete, import, or sync.

**Alternatives considered**:
- Persist trophy results: rejected because it duplicates derived state and requires invalidation on
  every transaction mutation.
- Recompute only when a transaction changes: rejected because profile build already has the data
  and the calculation is linear.

## Decision 3: Periods and reference date

**Decision**: The current month is the device-local calendar month derived from `DateTime.now()`.
All-time means every locally stored transaction, including future-dated ones. Tests pass an
explicit `now` to the service.

**Rationale**: Matches the spec and keeps tests deterministic without depending on the clock.

**Alternatives considered**:
- UTC months: rejected because the rest of the app uses local dates and the user expects the
  month shown on the home screen.

## Decision 4: Amount signs and refunds

**Decision**: Transactions store positive `amount` values and use `isIncome` to distinguish income
from expenses. Trophy values use the absolute amount. Expense trophies exclude entries with
`isRefunded == true`, consistent with the home total, current statistics, and budgets. Income
trophies consider entries with `isIncome == true` regardless of refund metadata.

**Rationale**: Reusing the existing sign convention avoids double-negation bugs. Excluding refunded
expenses matches the app's current definition of effective spending.

**Alternatives considered**:
- Include refunded expenses: rejected because it would show spending that was returned and would
  disagree with the home screen and category statistics.
- Store signed amounts: rejected because it would break existing persistence and imports.

## Decision 5: Installments and category totals

**Decision**: Category totals aggregate `ExpenseAllocation` entries returned by
`Expense.allocations()`, so split expenses contribute to the month of each installment. Single
expense and single income trophies rank the original transaction record by its full amount and use
`refundDate ?? date` as its effective date.

**Rationale**: Category totals then reconcile with the monthly statistics, while "highest single
expense" still means one transaction rather than one installment. Refunded expenses are excluded
before aggregation, so their refund date never moves spending into another month.

**Alternatives considered**:
- Rank installments as single expenses: rejected because a split payment would produce several
  smaller winners instead of the original purchase.
- Ignore installments in category totals: rejected because totals would not match the monthly
  statistics.

## Decision 6: Tie-breaking and deterministic ordering

**Decision**: Sort by value descending, then effective date ascending, then stable identifier
ascending. A trophy shows only the first element. Rankings show the first three elements.

**Rationale**: Implements "only the oldest wins" and "ties ordered by date" while remaining
deterministic when two elements share both value and date.

**Alternatives considered**:
- Alphabetical tie-break: rejected because the user explicitly requested date order.
- Show all tied winners: rejected because the user requested only the oldest.

## Decision 7: Category grouping and uncategorized entries

**Decision**: Group by `categoryId`; entries with a null or unknown category id share a synthetic
`no_category` group. The UI resolves the localized "No category" label and the category display
name; the service never handles localized strings.

**Rationale**: Keeps the service free of localization and matches how `current_stats_screen.dart`
already groups uncategorized spending.

**Alternatives considered**:
- Skip uncategorized entries: rejected because it would undercount spending and make category
  totals disagree with monthly totals.

## Decision 8: Persist section expansion in Settings

**Decision**: Add `profileQuestsExpanded` and `profileStatsExpanded` booleans to `Settings`,
defaulting to `true`, with `copyWith`, `toJson`, and `fromJson` support. Add `AppState` setters
that persist through the existing `_persist()` path.

**Rationale**: Reuses the existing settings document and persistence flow, avoids a new storage key,
and stays backward compatible because missing JSON fields fall back to the defaults.

**Alternatives considered**:
- New `SharedPreferences` key: viable but adds a second preferences mechanism for the same concern.
- Session-only state: rejected because the spec requires the state to survive a restart.

## Decision 9: Navigation for the ranking screen

**Decision**: Add `TrophyRankingScreen` and an `AppRouter.showTrophyRanking(context, trophy)`
helper that pushes a `MaterialPageRoute`, following the existing pattern used for expense details
and forms. The screen receives the already-computed trophy and its ranking entries.

**Rationale**: The ranking is a short, self-contained detail view; a full-screen route matches the
clarified UX and keeps the profile free of modal state.

**Alternatives considered**:
- Bottom sheet: rejected by the user in clarification.
- Named route: unnecessary because the argument is a domain object, not a URL-like payload.

## Decision 10: Localization and formatting

**Decision**: Add new keys to `lib/l10n/app_en.arb` and `lib/l10n/app_it.arb` for section headers,
trophy titles, ranking labels, and empty states; run `flutter gen-l10n`. Reuse
`formatCurrency` and the existing date formatters with `state.settings.currency` and
`state.locale`.

**Rationale**: Required by the constitution and `AGENTS.md`; reusing formatters keeps currency and
date presentation consistent with the rest of the app.

**Alternatives considered**:
- Hardcoded labels or symbols: rejected by the non-negotiable language and localization rules.

## Decision 11: Empty and zero states

**Decision**: A trophy is empty when it has no qualifying element with a value greater than zero.
Empty cards render a localized empty message and are not tappable. Zero-amount transactions never
become records.

**Rationale**: Prevents misleading "0" trophies and matches the spec edge cases.

**Alternatives considered**:
- Hide empty cards: rejected because the spec requires an explicit empty state so the trophy set
  stays predictable.

## Decision 12: Testing strategy

**Decision**:
- Unit tests for the service cover all five trophies, tie-breaking, refunds, installments,
  uncategorized entries, future-dated transactions, zero amounts, and empty data.
- A settings test verifies backward-compatible defaults for the new booleans.
- Widget tests verify collapsing and expanding each profile section, persistence through
  `AppState`, and the ranking screen's three-entry limit and ordering.

**Rationale**: The constitution requires tests for financial calculations and the Definition of
Done requires empty states and accessibility checks.

**Alternatives considered**:
- Golden tests: unnecessary for this behavior and more brittle than focused widget tests.
