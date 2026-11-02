# Feature Specification: Fix Month-Year Picker Layout

**Feature Branch**: `001-fix-calendar-popup-layout`

**Created**: 2026-11-02

**Status**: Draft

**Input**: User description (translated from Italian): "When I tap the date at the top-left and the calendar opens, the months do not all stay inside the popup; some are slightly outside the layout and the month names are not visible, only one or two letters of the month."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Read the full month grid inside the popup (Priority: P1)

A user taps the date shown in the top-left corner of the home screen to jump to another month. The month-year calendar opens as a popup. The user expects to see all twelve month names spelled out in full, each one visually contained inside the popup, and to be able to recognize every month at a glance before choosing one.

Today the grid does not fit: some month cells sit slightly outside the popup area and their labels are cut down to one or two letters, so the user has to guess which month is which and can mis-select a month.

**Why this priority**: This is the primary way to navigate months. When the labels are unreadable the user cannot reliably reach the desired month, which blocks the core "browse my month" flow of the app.

**Independent Test**: Open the app on a phone in portrait orientation, tap the date label in the top-left corner, and confirm that all twelve month names are fully readable and entirely inside the popup, then select a month and verify the home screen shows it.

**Acceptance Scenarios**:

1. **Given** the home screen is showing a month, **When** the user taps the date label in the top-left corner, **Then** a popup opens in which all twelve months are visible and every label is displayed in full, without letters being cut off.
2. **Given** the month-year popup is open, **When** the user looks at the grid, **Then** no month cell or label extends beyond the popup boundary and nothing is hidden behind or below its edges.
3. **Given** the month-year popup is open with all labels readable, **When** the user taps a month, **Then** the popup closes and the home screen shows the selected month with its transactions and totals.

---

### User Story 2 - Same readable calendar on any screen size and text size (Priority: P2)

A user on a small phone, on a large phone, in landscape, or with the system font size increased opens the same month-year popup. The month names must stay complete and inside the popup in every one of these conditions, and the user must still be able to reach every month.

**Why this priority**: The clipping reported in the primary device is a symptom of a layout that does not adapt. Users with accessibility settings (larger text) or smaller devices would otherwise remain blocked even after the primary phone is fixed.

**Independent Test**: Open the month-year popup on the smallest supported phone width, in landscape, and with the system font size set to the maximum supported level; confirm all month labels are complete and the grid stays inside the popup, allowing scrolling only if the content genuinely cannot fit.

**Acceptance Scenarios**:

1. **Given** a device whose screen width is the smallest supported by the app, **When** the month-year popup opens, **Then** all twelve month labels are complete and contained in the popup.
2. **Given** the system font size is increased (large accessibility text), **When** the month-year popup opens, **Then** month labels remain complete and readable, and the popup content can be scrolled vertically if it no longer fits.
3. **Given** the device is rotated to landscape, **When** the month-year popup opens, **Then** the grid still fits without clipped labels and without horizontal overflow.

---

### User Story 3 - Consistent calendar in the statistics month selector (Priority: P3)

A user opens the month selector from the statistics screen. Because it is the same kind of month-year calendar, it must show the same complete and contained month labels as the one on the home screen.

**Why this priority**: Consistency across entry points prevents the same defect from resurfacing in a second place and keeps the two month selectors indistinguishable to the user.

**Independent Test**: Open the statistics screen, tap the month selector, and confirm the same complete, contained month labels and the same selection behavior.

**Acceptance Scenarios**:

1. **Given** the user is on the statistics screen, **When** the month selector popup opens, **Then** every month label is complete and inside the popup, matching the home screen calendar.

---

### Edge Cases

- Longest month names in the supported languages (for example Italian names such as "settembre" and "dicembre") must fit, not only the shorter English ones.
- The popup must remain usable on the narrowest supported phone width, where three columns of month cells compete for very little space.
- With a screen reader active, each month must expose its complete name even if the visual label were to be constrained.
- Years outside the allowed range (before the minimum and after the maximum selectable date) must continue to be unreachable while the grid stays correctly laid out.
- An open popup must not allow the grid to be clipped by the popup's rounded corners or by its own padding.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Tapping the date label in the top-left corner of the home screen MUST open the month-year popup.
- **FR-002**: Every month in the popup MUST display its complete month name for the active language; no label may be reduced to a truncated prefix or a single letter.
- **FR-003**: Every month cell MUST be fully contained inside the popup boundaries; no cell or label may extend outside the popup layout or be visually cut by its edges.
- **FR-004**: All twelve months of the displayed year MUST be simultaneously available in the popup, reachable either by direct visibility or by vertical scrolling when the content does not fit.
- **FR-005**: The layout MUST remain correct on the narrowest supported phone width, in landscape orientation, and at the largest supported system font scale.
- **FR-006**: Month names MUST be shown in the complete form of both supported languages (English and Italian), including the longest ones.
- **FR-007**: The same popup behavior MUST apply to the month selector on the statistics screen.
- **FR-008**: Selecting a month MUST keep working exactly as today: the popup closes, the home screen shows the chosen month with its transactions, totals and category summary.
- **FR-009**: Each month MUST remain individually selectable with a tap target that is comfortable to hit.
- **FR-010**: The fix MUST NOT change the supported date range, the default month, or the current month navigation behavior.

### Key Entities

Not applicable: this feature changes presentation and layout of an existing selection control and introduces no new data.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In 100% of the tested configurations (screen widths from the narrowest supported phone to a tablet, portrait and landscape, font scale from default to the largest supported level), all twelve month labels are fully readable and none is truncated.
- **SC-002**: In the same tested configurations, zero month cells are reported as drawn outside the popup area.
- **SC-003**: A user can open the popup and select the target month in a single pass, without trial and error caused by unreadable labels.
- **SC-004**: No user report of cut or partially visible month names remains after the fix on the device where the defect was observed.
- **SC-005**: Month selection from the statistics screen behaves identically to the home screen in all tested configurations.

## Assumptions

- The defect affects the month-year calendar popup reached from the date label in the top-left corner of the home screen, and the equivalent selector on the statistics screen shares the same presentation.
- Android in portrait orientation is the primary target; landscape and larger devices are secondary but must remain usable, as required by the project constitution.
- The two supported interface languages are English and Italian; no other language must be validated for this fix.
- The supported date range, the current month default and the existing selection semantics stay unchanged.
- The popup is expected to keep its current visual identity (same grid of months, same year navigation); only its ability to fit and read content changes.
