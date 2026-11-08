# Phase 1 Data Model: Profile Trophies and Collapsible Sections

All trophy data is derived at display time and is not persisted. The only persisted change is the
profile section expansion state, added to the existing `Settings` document with backward-compatible
defaults.

## Enumerations

### `TrophyKind`

| Value | Meaning | Period |
|---|---|---|
| `topExpenseCategoryCurrentMonth` | Expense category with the highest total expense | Current month |
| `highestExpenseCurrentMonth` | Highest single expense transaction | Current month |
| `highestIncomeAllTime` | Highest single income transaction | All time |
| `topExpenseCategoryAllTime` | Expense category with the highest total expense | All time |
| `highestExpenseAllTime` | Highest single expense transaction | All time |

### `TrophyPeriod`

| Value | Meaning |
|---|---|
| `currentMonth` | Local calendar month containing the reference date |
| `allTime` | Every locally stored transaction |

### `TrophySubjectType`

| Value | Meaning |
|---|---|
| `category` | The winner is an expense category |
| `expense` | The winner is an expense transaction |
| `income` | The winner is an income transaction |

### `ProfileSection`

| Value | Meaning |
|---|---|
| `quests` | The quests section of the profile |
| `stats` | The statistics section of the profile |

## Entities

### `Trophy` (derived, not persisted)

| Field | Type | Rules |
|---|---|---|
| `kind` | `TrophyKind` | Required; determines title, period, and subject type |
| `period` | `TrophyPeriod` | Derived from `kind` |
| `subjectType` | `TrophySubjectType` | Derived from `kind` |
| `value` | `double` | Absolute amount, greater than zero for a valid trophy |
| `categoryId` | `String?` | Set for category trophies; `no_category` for uncategorized |
| `expenseId` | `String?` | Set for transaction trophies |
| `date` | `DateTime?` | Effective date of the winner, used for tie-breaking and display |
| `entries` | `List<TrophyRankingEntry>` | Up to three entries, sorted; empty means the trophy has no data |

**Validation**:
- `value > 0` for a valid trophy; otherwise `entries` is empty.
- Exactly one of `categoryId` or `expenseId` is set, matching `subjectType`.
- `entries.length <= 3`.
- `entries` is ordered by the ranking comparator below.

### `TrophyRankingEntry` (derived, not persisted)

| Field | Type | Rules |
|---|---|---|
| `value` | `double` | Absolute amount, greater than zero |
| `date` | `DateTime` | Effective date, used for tie-breaking and display |
| `categoryId` | `String?` | Set for category entries |
| `expenseId` | `String?` | Set for transaction entries |

**Validation**:
- Exactly one subject identifier is set.
- Entries with equal `value` are ordered by `date` ascending.

### `Settings` additions (persisted)

| Field | Type | Default | Rules |
|---|---|---|---|
| `profileQuestsExpanded` | `bool` | `true` | Missing in older JSON falls back to `true` |
| `profileStatsExpanded` | `bool` | `true` | Missing in older JSON falls back to `true` |

**Validation**:
- `copyWith`, `toJson`, and `fromJson` include both fields.
- Older persisted settings without the fields load with both sections expanded.

## Derived Rules

### Eligible transactions

- Expense trophies: `expense.isIncome == false` and `expense.isRefunded == false` and
  `expense.amount.abs() > 0`.
- Income trophies: `expense.isIncome == true` and `expense.amount.abs() > 0`.
- Refunded expenses are excluded from all expense trophies.
- Future-dated transactions are included in all-time trophies and excluded from current-month
  trophies.

### Current month

- `referenceDate` is passed to the calculator; production uses `DateTime.now()`.
- A transaction belongs to the current month when its effective date (`refundDate ?? date`, with
  refunded expenses already excluded) has the same year and month as `referenceDate`.
- A category allocation belongs to the current month when the allocation date has the same year and
  month as `referenceDate`.

### Category aggregation

- Aggregate `ExpenseAllocation` entries from eligible expense transactions.
- Group by `expense.categoryId`; null or unknown category ids map to `no_category`.
- Category total is the sum of absolute allocation amounts.
- Category effective date is the earliest allocation date contributing to that group within the
  trophy period.
- Unknown category ids are detected against the current category list; they are grouped with
  `no_category`.

### Transaction selection

- Single expense and income trophies select the original transaction record.
- Transaction value is `amount.abs()`.
- Transaction effective date is `refundDate ?? date`; for eligible expense trophies this equals
  `date` because refunded entries are excluded.
- Installments do not split a transaction for single-transaction trophies.

### Ranking and tie-breaking

Comparator, applied in order:
1. `value` descending.
2. `date` ascending (oldest first).
3. Subject identifier ascending (`categoryId` or `expenseId`) for determinism.

- The trophy winner is `entries.first`.
- Rankings expose at most the first three entries.
- If fewer than three entries exist, expose all of them.
- If no entries exist, the trophy is empty and the card is not interactive.

### Expansion state transitions

| Current state | Action | Next state | Persistence |
|---|---|---|---|
| Expanded | Tap section header | Collapsed | `Settings` updated and saved |
| Collapsed | Tap section header | Expanded | `Settings` updated and saved |
| Any | App restart | Same as persisted | Loaded from `Settings` |

Sections are independent: changing one never changes the other.

## Relationships

- A `Trophy` is derived from the local transaction list and the category list.
- A `TrophyRankingEntry` references either a `Category` (by id) or an `Expense` (by id).
- `ProfileSection` expansion state belongs to the single local `Profile` experience and is stored in
  `Settings`.
- No new persistent relationship or migration is introduced.
