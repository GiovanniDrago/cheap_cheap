# Implementation Plan: Profile Trophies and Collapsible Sections

**Branch**: `002-profile-trophies` | **Date**: 2026-11-08 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/002-profile-trophies/spec.md`

## Summary

Add two independently collapsible sections (Quests and Stats) to the profile, persisting their
expansion state, and add five personal trophy cards computed from local transactions: top expense
category and highest single expense for the current month, plus highest income, top expense
category, and highest single expense across all months. Each trophy card opens a dedicated
full-screen ranking of its top three elements, with ties ordered oldest first. The feature is
purely local and derived: no new dependencies, no schema migration, no network access.

## Technical Context

**Language/Version**: Dart 3 with Flutter stable, SDK `^3.10.7`

**Primary Dependencies**: `provider` (state), `shared_preferences` (persistence),
`flutter_localizations` + `intl` (localization and formatting). No new dependencies.

**Storage**: `SharedPreferences` through `StorageService`, JSON-encoded. Expansion preferences are
added as backward-compatible fields to the existing `Settings` JSON. Trophies are derived at
display time and are not persisted.

**Testing**: `flutter_test`; pure unit tests for trophy calculation and settings compatibility,
widget tests for the profile sections and the ranking screen.

**Target Platform**: Flutter mobile app, Android primary, portrait orientation, small screens.

**Project Type**: Single Flutter application.

**Performance Goals**: Compute all five trophies in one pass over the in-memory transaction list
on profile build; keep profile rendering within a normal frame budget for thousands of
transactions; no asynchronous work or network calls in the calculation path.

**Constraints**: Fully offline; no network calls in rendering or pure calculation; all user-facing
text in English and Italian ARB files; `flutter analyze` clean; `flutter test` green; existing JSON
and CSV formats remain backward compatible.

**Scale/Scope**: Single local profile, typically thousands of transactions; one profile screen
update, one new screen, one new calculation service, one settings model extension.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle / Constraint | Gate | Status |
|---|---|---|
| I. Offline-first, cloud as extension | Feature reads only local data; no sync or network dependency | PASS |
| II. Monthly view as primary path | Changes stay on the profile screen; no new elements on the monthly home | PASS |
| III. Derived and consistent statistics | One pure calculation layer produces all trophy values; results reconcile with existing monthly attribution; tests required | PASS |
| IV. Privacy and security | No secrets, no logging of amounts or personal data, no new external calls | PASS |
| V. Controlled updates and releases | No change to update checks or release flow | PASS |
| VI. English as working language | Spec, plan, code, comments, tests in English; UI strings in both ARB files | PASS |
| Technical constraints | No new dependency; backward-compatible persisted settings; ARB localization; analyze and tests required | PASS |

No violations. Complexity Tracking is not required.

**Post-design re-check (after Phase 1)**: PASS. The design keeps all calculations in a pure local
service, adds no dependency, no network call, and no schema migration; localization and tests are
part of the plan. No new gate violations were introduced.

## Project Structure

### Documentation (this feature)

```text
specs/002-profile-trophies/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/
│   └── trophy-ui-contract.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Created by /speckit.tasks, not by this command
```

### Source Code (repository root)

```text
lib/
├── models/
│   ├── settings.dart            # Add profileQuestsExpanded / profileStatsExpanded
│   ├── trophy.dart              # New: Trophy, TrophyKind, TrophyRankingEntry
│   └── ...                      # Existing models unchanged
├── services/
│   ├── trophy_service.dart      # New: pure trophy calculation
│   └── ...                      # Existing services unchanged
├── state/
│   └── app_state.dart           # Section expansion setters; expose trophy calculation
├── navigation/
│   └── app_router.dart          # Route/push helper for the ranking screen
├── ui/
│   ├── profile_screen.dart      # Collapsible sections + trophy cards
│   ├── trophy_ranking_screen.dart  # New full-screen top-three ranking
│   └── ...                      # Existing screens unchanged
├── l10n/
│   ├── app_en.arb               # New trophy/ranking/section strings
│   ├── app_it.arb               # Italian translations
│   └── generated/               # Regenerated by flutter gen-l10n
└── utils/
    └── formatters.dart          # Reused for currency and date formatting

test/
├── models/
│   └── settings_test.dart
├── services/
│   └── trophy_service_test.dart
└── ui/
    └── screens/
        ├── profile_screen_test.dart
        └── trophy_ranking_screen_test.dart
```

**Structure Decision**: Single Flutter application. Trophy calculation is a pure service so it can
be unit-tested without widgets and reused by the profile and ranking screens. Persistence is
extended through the existing `Settings` model to avoid a new storage key and keep the data
backward compatible.

## Complexity Tracking

No constitution violations; no additional complexity to justify.
