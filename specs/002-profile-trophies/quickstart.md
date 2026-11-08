# Quickstart: Profile Trophies and Collapsible Sections

Validation guide for feature `002-profile-trophies`. See [data-model.md](./data-model.md) for
calculation rules and [contracts/trophy-ui-contract.md](./contracts/trophy-ui-contract.md) for the
UI contract.

## Prerequisites

- Flutter stable with Dart SDK `^3.10.7`
- Repository checked out on branch `002-profile-trophies`
- No network access required to run the app; dependencies must already be available or installed
  once with `flutter pub get`

## Setup

```bash
flutter pub get
flutter gen-l10n
```

`flutter gen-l10n` regenerates `lib/l10n/generated/` from the ARB files.

## Automated checks

```bash
flutter analyze
flutter test
```

Expected outcome: no analyzer errors and all tests green. The feature adds unit tests for trophy
calculation and settings compatibility, plus widget tests for the profile sections and the ranking
screen.

Focused test runs:

```bash
flutter test test/services/trophy_service_test.dart
flutter test test/models/settings_test.dart
flutter test test/ui/screens/profile_screen_test.dart
flutter test test/ui/screens/trophy_ranking_screen_test.dart
```

## Manual validation

Run the app:

```bash
flutter run
```

### 1. Collapsible sections

1. Open the profile.
2. Confirm Quests and Stats are both expanded.
3. Tap the Quests header: the quest list hides and the chevron points to the collapsed state.
4. Tap the Stats header: only the stats section collapses.
5. Restart the app and open the profile: both sections keep their previous state.
6. Expand the Quests section while the daily quest limit is reached: the reset countdown and the
   disabled overlay still work.

Expected outcome: each header toggles only its own section, and the state survives a restart.

### 2. Trophy cards

Create test data with at least:

- two categories with different totals in the current month;
- a high expense in the current month;
- a higher expense in a previous month;
- a high income entry;
- an uncategorized expense.

Then open the profile and verify:

1. The current-month top category card shows the category with the highest total.
2. The current-month highest expense card shows the highest expense dated in the current month.
3. The all-time highest income card shows the highest income entry.
4. The all-time top category card shows the category with the highest total across months.
5. The all-time highest expense card shows the highest expense overall.
6. Values match the amounts visible in the transaction list, formatted with the selected currency.

Expected outcome: five cards, each with the correct subject, value, and period.

### 3. Ties

1. Create two expenses with the same amount in the current month.
2. Open the profile: the trophy shows the older expense.
3. Open the ranking: both appear, older first.

Expected outcome: the card shows only the oldest tied element; the ranking orders ties by date.

### 4. Ranking

1. Tap a trophy card with at least three qualifying elements.
2. Verify a full-screen ranking opens with the trophy title and a back action.
3. Verify exactly three entries, highest value first.
4. Verify fewer than three entries are shown when fewer qualify.
5. Tap back and confirm the profile state is unchanged.

Expected outcome: full-screen ranking, deterministic order, back returns to the profile.

### 5. Empty states

1. Use a fresh install with no transactions.
2. Open the profile: every trophy card shows the localized empty message and is not tappable.
3. Add only income: expense trophies stay empty, the income trophy shows the record.

Expected outcome: no misleading zero values and no empty ranking screen.

### 6. Refunds, installments, uncategorized entries

1. Mark an expense as refunded and verify it does not become an expense trophy.
2. Create a split expense across months and verify category totals follow the monthly attribution.
3. Create an expense without a category and verify it appears under "No category" in category
   rankings.

Expected outcome: trophy values reconcile with the monthly statistics.

### 7. Localization and currency

1. Switch the app language between English and Italian.
2. Verify all new labels, empty states, and ranking titles are translated.
3. Change the currency in settings and verify trophy and ranking values update their formatting.

Expected outcome: no untranslated strings and no hardcoded currency symbols.

## Acceptance checklist

- [ ] Both profile sections collapse and expand independently.
- [ ] Expansion state survives an app restart.
- [ ] Five trophy cards show the correct personal records.
- [ ] Ties resolve to the oldest element.
- [ ] Rankings show at most three entries in deterministic order.
- [ ] Empty trophies show an empty state and do not open a ranking.
- [ ] Refunds, installments, and uncategorized expenses behave as documented.
- [ ] English and Italian strings are complete.
- [ ] `flutter analyze` and `flutter test` pass.
