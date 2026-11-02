# Phase 0 Research: Fix Month-Year Picker Layout

**Feature**: 001-fix-calendar-popup-layout
**Date**: 2026-11-02

## Problem statement

Tapping the date label in the top-left corner of the home screen opens the month-year calendar. On the reported device the twelve months do not all stay inside the popup: some cells are drawn slightly outside the layout and the month names are reduced to one or two letters.

## Evidence collected

Source of `month_year_picker` 0.5.0+1, `lib/src/dialogs.dart` and `lib/src/pickers.dart`:

- The dialog requests a fixed size and multiplies it by the system text scale:
  `AnimatedContainer(width: textScaler.scale(320.0), height: textScaler.scale(480.0))` in portrait, `496x344` in landscape.
- Flutter's `Dialog` wraps its child in a `ConstrainedBox` whose `maxWidth` is the screen width minus `insetPadding` (`16 + 16` here), so the requested width is silently reduced on narrow screens; the height is not reduced the same way and the dialog clips overflow (`clipBehavior: Clip.antiAlias`).
- The month grid is `GridView.count(crossAxisCount: 4)` with default square cells, and each cell is a `TextButton` whose child is a plain `Text(label)` without fitting, wrapping or overflow policy.
- The whole dialog is built from these fixed constants; the public `builder` parameter can only wrap the dialog widget, not change its internal sizes or grid structure.

Consequences that match the report:

1. On a narrow viewport, a four-column grid leaves roughly 70-80 logical pixels per cell after padding; names such as "September" and especially Italian "settembre" or "dicembre" need more than that with the default button padding, so the label is clipped and only one or two letters remain visible.
2. When the system text scale is above 1.0 the requested width grows past the screen minus insets and the requested height grows past the available height, so the dialog is clamped horizontally and cut vertically; cells then appear "slightly outside the layout".

## Decisions

### D1 — Replace the package dialog with a project-owned responsive dialog

**Decision**: Build `lib/ui/widgets/month_year_picker_dialog.dart` and call it from both screens through a single `showAppMonthYearPicker` function.

**Rationale**: The defect comes from hard-coded dialog dimensions and a fixed four-column grid inside the dependency. No public API of the package changes either. A project-owned dialog can size itself from the available viewport, choose the number of columns from the real width and text scale, and scroll when necessary — which is exactly what the acceptance scenarios require.

**Alternatives considered**:

- *Wrap the package with `builder` and clamp the text scale* (e.g. `MediaQuery(textScaler: TextScaler.linear(0.85))`): rejected. It suppresses the user's accessibility setting inside the dialog (principle "Definition of Done" and FR-005) and does not fix the four-column truncation at the default scale on narrow screens.
- *Vendor a patched copy of the package into the repository*: rejected. It adds roughly 1.4k lines of third-party code plus its localizations to maintain, with no upstream path for fixes, while the required surface here is only a month grid.

### D2 — Localized month names from `intl`

**Decision**: Format month names with `DateFormat.MMMM(locale)` from the already-present `intl` package, using the language selected in the app.

**Rationale**: Month names are locale data, not application copy; `intl` already backs every other date format in `lib/utils/formatters.dart`. This satisfies the constitution's rule that user-facing text is never hardcoded, and it returns full names as required by FR-002.

**Alternatives considered**:

- *Twelve new ARB keys per language*: rejected. It duplicates data the locale already provides and adds 24 strings to maintain.

### D3 — Width-first responsive layout with scroll fallback

**Decision**: The dialog computes its size from `MediaQuery` and `LayoutBuilder`:

- width = the smaller of the viewport width minus 32 and a 400 logical pixel cap;
- content column: header (selected month and year), year stepper, month grid in a scrollable region, actions;
- month grid: three columns at default text scale, two columns when the text scale is large or the available width is very small; cell aspect ratio chosen so the label never needs vertical compression;
- labels use up to two lines with `FittedBox(fit: BoxFit.scaleDown)` only as a safety net for the longest localized names;
- the grid area scrolls when the twelve cells plus header do not fit, so nothing is ever clipped.

**Rationale**: It guarantees both halves of the defect are fixed: containment (FR-003) and complete labels (FR-002), while keeping the user's text scale intact (FR-005). Choosing the column count from the measured width prevents the truncation seen at four columns.

**Alternatives considered**:

- *Fixed three-column grid with fixed sizes*: rejected. It works at one scale but breaks again at the largest supported text scale.
- *Horizontal scrolling grid*: rejected. Months must all be reachable without horizontal gesture confusion, and horizontal scroll inside a dialog conflicts with the swipe navigation on the home screen.

### D4 — One shared entry point for both screens

**Decision**: Export `Future<DateTime?> showAppMonthYearPicker({...})` and import it in `home_screen.dart` and `current_stats_screen.dart`.

**Rationale**: FR-007 requires identical behavior in both places; a single entry point makes divergence impossible and keeps the two calls as small as the current package calls.

### D5 — Remove the now-unused dependency

**Decision**: Delete `month_year_picker` from `pubspec.yaml` and `MonthYearPickerLocalizations.delegate` from `lib/app.dart`. Keep `pickerLocale` in `lib/utils/date_utils.dart` because the expense forms still use it for the day picker.

**Rationale**: The constitution asks for justified dependencies and prefers the existing stack; after the replacement the package is dead weight and its layout assumptions are what caused the bug.

### D6 — Widget-level regression tests

**Decision**: Add `test/ui/widgets/month_year_picker_dialog_test.dart` covering: all twelve labels present in English and Italian; no overflow exception at narrow width, at large text scale and in landscape; selecting a month returns the expected date; year navigation respects `firstDate`/`lastDate`.

**Rationale**: The defect is a layout regression that only a rendered widget can catch. `tester.takeException()` surfaces overflow errors that a unit test would miss, and the Italian case covers the longest labels.

## Open questions

None. All technical unknowns in the plan context are resolved; no `NEEDS CLARIFICATION` items remain.

## References

- `month_year_picker` 0.5.0+1 source: `lib/src/dialogs.dart`, `lib/src/pickers.dart`
- Flutter `Dialog` sizing: `insetPadding` and the `ConstrainedBox` max width constraint
- Existing project helpers: `lib/utils/formatters.dart` (`formatMonthYear`, `formatMonth`), `lib/utils/date_utils.dart` (`pickerLocale`, `addMonths`)
