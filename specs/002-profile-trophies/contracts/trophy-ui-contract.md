# UI Contract: Profile Trophies and Collapsible Sections

This contract describes the observable behavior the implementation must satisfy. It is
technology-agnostic where possible and references existing project conventions where the behavior
must integrate with the app.

## Profile screen

### Collapsible sections

Each of the two existing sections (Quests and Stats) exposes a header with:

- the section title (`strings.quests`, `strings.stats`);
- a chevron or equivalent icon whose direction reflects the state;
- a tappable area covering the full header row, at least 48x48 logical pixels;
- an accessibility state that reports expanded or collapsed.

Behavior:

- Tapping a header toggles only that section.
- Both sections start expanded when the persisted settings have no value.
- Collapsing hides the section content but keeps the section available for expansion.
- The existing quest availability logic, daily-limit overlay, reset countdown, and statistic
  progress bars are unchanged when expanded.
- The expansion state is read from and written to `Settings.profileQuestsExpanded` and
  `Settings.profileStatsExpanded`.

### Trophies section

The profile contains a section titled with the localized `trophies` label. It shows exactly five
cards in this fixed order:

| Order | Trophy kind | Title key |
|---|---|---|
| 1 | Top expense category, current month | `trophyTopExpenseCategoryCurrentMonth` |
| 2 | Highest single expense, current month | `trophyHighestExpenseCurrentMonth` |
| 3 | Highest single income, all time | `trophyHighestIncomeAllTime` |
| 4 | Top expense category, all time | `trophyTopExpenseCategoryAllTime` |
| 5 | Highest single expense, all time | `trophyHighestExpenseAllTime` |

Each card displays:

- the localized trophy title;
- the record value formatted with `formatCurrency(value, settings.currency, locale)`;
- the winning subject: category name, or transaction name;
- the relevant period and, for transaction trophies, the transaction date formatted with the
  existing date formatters;
- a localized empty message (`trophyEmpty`) when no qualifying element exists.

Interaction contract:

- A card with at least one ranking entry is tappable and opens the ranking screen for that trophy.
- A card with no ranking entry is not tappable and shows the empty message.
- Tapping never changes transaction data or trophy state.

## Ranking screen

A dedicated full-screen route with:

- an app bar whose title is the localized trophy title;
- a back action that returns to the profile;
- a list of at most three entries.

Each entry displays:

- its position (1, 2, 3);
- the subject name (category or transaction);
- the formatted value;
- the effective date, formatted with the existing date formatters.

Ordering contract:

1. Higher value first.
2. On equal value, older date first.
3. On equal value and date, subject identifier ascending.

When fewer than three entries exist, all available entries are shown. The screen must not be
reachable for an empty trophy.

## Navigation contract

Add a helper with this behavior:

```text
AppRouter.showTrophyRanking(
  BuildContext context, {
  required Trophy trophy,
}) -> Future<void>
```

It pushes a full-screen `MaterialPageRoute` for `TrophyRankingScreen`, consistent with the existing
`showExpenseDetails` pattern. The route receives the already-computed trophy and does not
recalculate it.

## Localization contract

All new user-facing strings must be present in both `lib/l10n/app_en.arb` and
`lib/l10n/app_it.arb`, including at least:

- `trophies`
- `trophyTopExpenseCategoryCurrentMonth`
- `trophyHighestExpenseCurrentMonth`
- `trophyHighestIncomeAllTime`
- `trophyTopExpenseCategoryAllTime`
- `trophyHighestExpenseAllTime`
- `trophyEmpty`
- `trophyRanking`
- `currentMonth`
- `allTime`

Existing keys `noCategory`, `income`, `expense`, `total`, `quests`, and `stats` are reused where
applicable. Currency and date formatting must use the user's locale and currency settings.

## Data contract

The profile and ranking screens consume `Trophy` values produced by the pure calculation service.
The screens must not duplicate aggregation, tie-breaking, or period logic.

## Accessibility contract

- Collapsible headers expose their expanded/collapsed state to assistive technologies.
- Trophy cards and ranking rows provide semantic labels that include the trophy or subject name and
  the formatted value.
- All interactive elements meet the app's minimum tap target size.
