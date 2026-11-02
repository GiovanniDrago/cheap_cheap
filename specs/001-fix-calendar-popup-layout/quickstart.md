# Quickstart: Validate the Month-Year Picker Fix

**Feature**: 001-fix-calendar-popup-layout
**Date**: 2026-11-02

This guide proves the fix end to end. Contracts and state details live in [contracts/month-year-picker-contract.md](./contracts/month-year-picker-contract.md) and [data-model.md](./data-model.md).

## Prerequisites

- Flutter stable with Dart SDK `^3.10.7`.
- Dependencies resolved: `flutter pub get`.
- A device or emulator; the defect was reported on a phone in portrait orientation.

> The Flutter SDK is not installed on the development VM. Run the gates in CI (GitHub Actions) or on a machine that has Flutter; the manual scenarios below still describe exactly what must be observed.

## Automated validation

```bash
flutter analyze
flutter test test/ui/widgets/month_year_picker_dialog_test.dart
flutter test
```

Expected outcome:

- `flutter analyze` reports no issues.
- The dialog tests pass for both languages, narrow and wide widths, default and large text scale, portrait and landscape.
- No test logs a `RenderFlex overflow` or any layout assertion.
- The full suite still passes, proving no regression in the existing app behavior.

## Manual validation — home screen

1. Launch the app on a phone in portrait orientation.
2. Tap the date label in the top-left corner of the home screen.
3. Verify the popup shows twelve complete month names, all inside the popup, none cut to one or two letters.
4. Tap a month different from the current one.
5. Verify the popup closes and the home screen shows the chosen month with its transactions, totals and category summary.
6. Reopen the popup and use the year stepper: it must move one year per tap and stop at the minimum and maximum allowed years.

Expected: the same result as before the fix for selection, with complete and contained labels.

## Manual validation — adaptive conditions

| Condition | How to reproduce | Expected |
|---|---|---|
| Small phone width | Emulator with the smallest supported screen width (e.g. 320 dp) | Twelve complete labels, grid inside the popup |
| Large text scale | System settings: largest supported font size | Labels still complete; the grid scrolls vertically instead of clipping |
| Landscape | Rotate the device with the popup open | Layout stays inside the popup, no horizontal overflow |
| Italian | Switch the app language to Italian | `settembre`, `novembre`, `dicembre` shown in full |
| English | Switch the app language to English | `September`, `November`, `December` shown in full |

## Manual validation — statistics screen

1. Open the statistics screen.
2. Tap the month selector.
3. Verify the same complete, contained month labels and the same selection behavior as the home screen.

## Accessibility spot check

1. Enable a screen reader (TalkBack).
2. Open the popup and move focus across the month cells.
3. Verify each cell is announced with its complete month name and year, that the selected month is announced as selected, and that disabled months are announced as unavailable.

## References

- Behavior requirements: [spec.md](./spec.md) (FR-001 to FR-010, SC-001 to SC-005)
- Design decisions: [research.md](./research.md) (D1 to D6)
- Implementation scope: [plan.md](./plan.md)
