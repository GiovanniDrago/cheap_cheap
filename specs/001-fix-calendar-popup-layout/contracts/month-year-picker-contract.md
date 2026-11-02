# UI Contract: Month-Year Picker Dialog

**Feature**: 001-fix-calendar-popup-layout
**Type**: in-app UI contract (Flutter widget + entry function)

## Entry point

```dart
Future<DateTime?> showAppMonthYearPicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  required Locale locale,
});
```

### Input rules

- `initialDate` must satisfy `firstDate <= initialDate <= lastDate`; the implementation normalizes all three to the first day of their month.
- `locale` must be one of the languages supported by the app (English or Italian); it selects the month names and the header text.
- `firstDate`/`lastDate` define the selectable range; they are the same values used today (`2018-01` and `2100-12`).

### Output rules

- Returns the first day of the selected month when the user confirms a month.
- Returns `null` when the dialog is dismissed without a selection.
- Never throws for out-of-range input; out-of-range months are rendered disabled.

## Presentation contract

- **C-1 Containment**: the dialog and every month cell are laid out inside the visible viewport minus a 16 pixel horizontal and 24 pixel vertical inset; no child exceeds the dialog bounds (requirement FR-003).
- **C-2 Complete labels**: each month is displayed with its complete localized name; truncation, ellipsis and single-letter rendering are not acceptable (FR-002).
- **C-3 Twelve months**: all twelve months of the displayed year are reachable in the same dialog, directly or through vertical scrolling (FR-004).
- **C-4 Adaptation**: the layout is valid at the narrowest supported phone width, in landscape, and at the largest supported system text scale (FR-005); the user's text scale is never overridden.
- **C-5 Languages**: English and Italian both show complete names, including the longest Italian names (`settembre`, `novembre`, `dicembre`) (FR-006).
- **C-6 Identity**: the same dialog is used by the home screen and the statistics screen (FR-007).
- **C-7 Preserved behavior**: the supported date range, the initially selected month and the closed-popup behavior are unchanged (FR-010); after selection the caller shows the chosen month with its data (FR-008).

## Interaction contract

- Tapping a month closes the dialog and returns that month.
- The year stepper moves one year per tap and is disabled at the bounds.
- Tapping outside the dialog or pressing back dismisses it and returns `null`.
- Every month cell has a tap target of at least 48 x 48 logical pixels (FR-009).

## Accessibility contract

- Each month cell exposes a semantics label equal to the complete localized month name plus the year, so assistive technology never reads a truncated label.
- The selected month is announced as selected.
- Disabled months are announced as unavailable.

## Test contract

The widget tests must assert, for each of {English, Italian} x {narrow width, wide width} x {default text scale, large text scale} x {portrait, landscape}:

1. twelve month labels are found and each equals the expected complete localized name;
2. `tester.takeException()` is `null` (no overflow or layout assertion);
3. tapping a month returns the expected date;
4. the year stepper cannot move past `firstDate.year` or `lastDate.year`.
