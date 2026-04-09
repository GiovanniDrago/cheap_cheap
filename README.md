# CheapCheap

CheapCheap is a gamified personal finance tracker built with Flutter. It helps you log expenses and income, review monthly spending patterns, manage categories, and stay engaged with lightweight RPG-style profile stats and quests.

## Features

- Monthly navigation for browsing past and future budgets from a single timeline
- Expense and income tracking with category, icon, note, and date metadata
- Recurring entries for daily, monthly, and yearly cash flows
- Split payments/installments with generated allocations across future weeks or months
- Refund support so reimbursed purchases do not distort active stats
- Monthly statistics with separate income and expense totals for each month
- Current expense statistics with category breakdowns shown in a donut chart
- Category management with default and custom categories plus cloning support
- CSV import/export for backup and migration workflows
- Reminder scheduling with local notifications for recurring finance habits
- Profile progression with quests, experience points, and stat changes tied to spending
- App personalization through theme, theme mode, language, and currency settings

## Running the App

```bash
flutter pub get
flutter run
```

## Releasing Android APKs

```bash
./scripts/tag-release.sh vX.Y.Z
```

That command updates `pubspec.yaml`, pushes the version bump commit, creates an annotated tag, and pushes the tag. GitHub Actions then builds the signed `build/app/outputs/flutter-apk/app-release.apk` and publishes it to the GitHub Release for that tag.

The release workflow expects these GitHub secrets:

- `KEYSTORE_BASE64`
- `KEYSTORE_PASSWORD`
- `KEY_PASSWORD`
- `KEY_ALIAS`
