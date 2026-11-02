# Implementation Plan: Fix Month-Year Picker Layout

**Branch**: `001-fix-calendar-popup-layout` | **Date**: 2026-11-02 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-fix-calendar-popup-layout/spec.md`

## Summary

Replace the third-party month-year calendar popup with a project-owned, responsive month-year dialog shared by the home screen and the statistics screen. The current popup requests a fixed 320x480 logical size, multiplies it by the system text scale, and lays months out in a fixed four-column grid of buttons whose labels cannot shrink or wrap; when the screen or the text scale differs from the assumed baseline, the dialog is clamped horizontally and overflows vertically, so month names are clipped to one or two letters and some cells fall outside the visible dialog. The new dialog derives its size from the available space, keeps complete month names for the active language, scrolls when content cannot fit, and exposes accessible month labels. The `month_year_picker` dependency and its localization delegate are removed after the replacement.

**Root cause (verified in `month_year_picker` 0.5.0+1 source)**:

- `MonthYearPickerDialog` sizes itself with `AnimatedContainer(width: textScaler.scale(320), height: textScaler.scale(480))` for portrait.
- Flutter's `Dialog` clamps its child to `screenWidth - insetPadding.horizontal` (16 + 16), so the requested width is reduced on narrow screens and the request grows with the text scale.
- Months are rendered by `GridView.count(crossAxisCount: 4)` with `TextButton(child: Text(label))`; labels have no fit, wrap or ellipsis strategy and `GridView.count` defaults to a square aspect ratio, which makes cells narrow and short.
- When the text scale increases the dialog height also exceeds the available height while the dialog clips its content (`clipBehavior: Clip.antiAlias`), so rows are cut away.

## Technical Context

**Language/Version**: Dart stable, SDK `^3.10.7`; Flutter stable with Material 3 (`flex_color_scheme`)

**Primary Dependencies**: `flutter`, `intl ^0.20.2` (localized month names), `provider`; `month_year_picker ^0.5.0+1` removed by this feature

**Storage**: N/A — the picker holds transient UI state only, nothing is persisted

**Testing**: `flutter_test` widget tests; `flutter analyze` and `flutter test` are the quality gates (Flutter SDK is not installed on the development VM, so gates run in GitHub Actions CI)

**Target Platform**: Android (primary), portrait and landscape; small phone widths up to tablet widths

**Project Type**: mobile-app (single Flutter project)

**Performance Goals**: popup opens in under 300 ms; steady 60 fps while scrolling the grid; zero `RenderFlex`/`RenderConstrainedBox` overflow reports in debug builds

**Constraints**: presentation-only change (no new dependencies, no network, no persistence, no statistics changes); user-facing text stays in the ARB files while month names come from `intl` locale data; both English and Italian must show complete month names

**Scale/Scope**: 2 entry points (`home_screen.dart`, `current_stats_screen.dart`), 1 shared dialog widget, 1 shared entry function, widget tests for both languages and several viewport/text-scale combinations

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Gate | Status |
|---|---|---|
| I. Offline-First, Cloud as an Extension | Picker is pure UI, no network, works offline | PASS |
| II. Monthly View as the Primary Path | Month switching stays one tap from the home screen; no elements added to the monthly view | PASS |
| III. Derived and Consistent Statistics | Aggregation layer untouched; only the statistics month selector presentation changes | PASS |
| IV. Privacy and Security of Financial Data | No data, tokens, or logs involved | PASS |
| V. Controlled Updates and Traceable Releases | No update or release logic touched | PASS |
| VI. English as the Working Language | Code, comments, tests and documents in English; no hardcoded user-facing text; month names come from `intl` | PASS |
| Technical constraints | One dependency removed and none added; ARB files untouched; `flutter analyze` clean and `flutter test` green | PASS |
| Definition of Done | Accessible labels and tap targets; no offline regression; no new visual noise | PASS |

No violations: Complexity Tracking is empty.

**Post-design re-evaluation (after Phase 1)**: still PASS. The design adds presentation code only, keeps the existing date range and selection semantics, and does not alter localization files or stored data.

## Project Structure

### Documentation (this feature)

```text
specs/001-fix-calendar-popup-layout/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── month-year-picker-contract.md   # Phase 1 output
└── tasks.md             # /speckit.tasks output
```

### Source Code (repository root)

```text
lib/
├── app.dart                              # drop MonthYearPickerLocalizations delegate
├── ui/
│   ├── home_screen.dart                  # use the shared month-year dialog
│   ├── current_stats_screen.dart         # use the shared month-year dialog
│   └── widgets/
│       ├── icon_picker.dart              # existing shared widget (naming precedent)
│       └── month_year_picker_dialog.dart # NEW responsive month-year dialog
├── utils/
│   ├── date_utils.dart                   # month helpers (existing pickerLocale stays)
│   └── formatters.dart                   # reuse localized month formatting
└── l10n/app_en.arb, app_it.arb            # unchanged

test/
└── ui/widgets/
    └── month_year_picker_dialog_test.dart # NEW widget tests
```

**Structure Decision**: Single Flutter project. Presentation code stays in `lib/ui/`, shared widgets in `lib/ui/widgets/` following the existing `icon_picker.dart` placement, and tests mirror the source path under `test/ui/widgets/`.

## Design Decisions Summary

Full trade-offs are recorded in [research.md](./research.md).

1. Replace the package dialog with a project-owned responsive dialog instead of wrapping the package with a clamped text scale (which would break accessibility) or vendoring a patched fork (≈1.4k lines to maintain).
2. Render month names with `intl` `DateFormat.MMMM(locale)`; no new ARB keys, no hardcoded strings.
3. Compute the grid width-first: dialog width capped at 400 logical pixels and constrained by the viewport; three columns at default text scale, two columns when the text scale is large or the width is very small; the grid area scrolls vertically when needed; each label is allowed to shrink inside its cell as a last-resort safety net rather than being clipped.
4. Expose one entry function (`showAppMonthYearPicker`) used by both screens so home and statistics cannot drift apart.
5. Remove `month_year_picker` from `pubspec.yaml` and its localization delegate from `app.dart`; keep `pickerLocale` because the expense forms still use it for the day picker.
6. Cover the widget with tests for both languages, narrow/wide viewports, and default/large text scale, asserting no overflow and complete labels.

## Complexity Tracking

> No constitution violations. No complexity to justify.
