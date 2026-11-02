# Phase 1 Data Model: Fix Month-Year Picker Layout

**Feature**: 001-fix-calendar-popup-layout
**Date**: 2026-11-02

The feature persists nothing. This document describes the transient state the month-year dialog holds while it is open, so the contract and the tests share one vocabulary.

## MonthYearPickerState (in memory, per dialog instance)

| Field | Type | Source | Rules |
|---|---|---|---|
| `initialDate` | date | caller (current month of the screen) | normalized to the first day of its month before use |
| `firstDate` | date | caller (`2018-01-01`) | lower bound; must not be after `lastDate` |
| `lastDate` | date | caller (`2100-12-01`) | upper bound; must not be before `firstDate` |
| `displayedYear` | year | derived from `initialDate`, then changed by the year stepper | must stay within `firstDate.year` and `lastDate.year`; the stepper is disabled at the bounds |
| `selectedDate` | date | caller (`initialDate`), then the user's tap | always inside the bounds; returned to the caller on confirmation |
| `locale` | language | caller (English or Italian) | determines the month names and the header text |
| `columns` | integer | derived at build time (3, or 2 when width or text scale requires it) | not user-visible state; recomputed on every build |

## Invariants

- **INV-1**: `firstDate <= selectedDate <= lastDate` at all times.
- **INV-2**: the twelve month labels of `displayedYear` are always produced from `locale`, never from literal strings.
- **INV-3**: a month outside the bounds is rendered disabled and cannot be selected.
- **INV-4**: `displayedYear` changes only through the stepper, and only within the bounds.
- **INV-5**: the dialog never mutates application state; it returns `DateTime?` to the caller and lets the caller update its own selected month.

## State transitions

| From | Event | To |
|---|---|---|
| open | dialog shown | `selectedDate = initialDate`, `displayedYear = initialDate.year` |
| open | year stepper previous/next | `displayedYear` +/- 1 within bounds |
| open | month tapped | `selectedDate = <month of displayedYear>` then dialog closes returning that date |
| open | dismiss / back | closed returning `null`, caller keeps its month |

## Relationships

No relationship with persisted entities. The returned date is consumed by the existing month selection logic of `home_screen.dart` and `current_stats_screen.dart`.
