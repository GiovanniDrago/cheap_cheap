# CheapCheap Constitution

## Core Principles

### I. Offline-First, Cloud as an Extension (NON-NEGOTIABLE)

The app MUST remain fully usable without an account and without a network connection for all
core functions: browsing the current month, creating and editing expenses and income, managing
categories, statistics, export, and import. The local data source is primary for the user
experience; authentication and synchronization with Supabase are optional and additive.
Synchronization MUST be triggered by an explicit or clearly indicated user action, MUST NOT
block the UI, and MUST NOT overwrite local data without a documented and tested deterministic
conflict resolution. Network or authentication failures MUST degrade gracefully with a visible
state, without data loss, and without preventing offline use.

**Rationale**: personal financial data must always be available; the cloud is an enhancement,
not a prerequisite.

### II. Monthly View as the Primary Path

The initial screen MUST show the current month with total expenses, total income, the list of
transactions, and a category summary. Daily actions — adding a transaction, changing month,
opening a category — MUST require at most two interactions from the home screen. Month
navigation MUST be immediate and backed by local data. New features MUST NOT add visual noise
to the monthly view: profile, quests, advanced settings, and diagnostics live on dedicated
screens. Every screen MUST define explicit loading, empty, and error states.

**Rationale**: simplicity of the monthly overview is the product's differentiator; every added
element carries a cognitive cost for the user.

### III. Derived and Consistent Statistics

Every metric MUST be computed by a single domain layer from the stored transactions; the UI
MUST only present the result. Monthly and yearly trend charts MUST share the same aggregation
rules and MUST reconcile with the displayed totals. The sum of category statistics MUST equal
the period total, with refunds, installments, and recurring transactions handled explicitly.
Currencies, number formats, and dates MUST respect the user's locale and MUST NOT be
hardcoded.

**Rationale**: inconsistent or unreconcilable numbers destroy trust in a finance app, even
when the interface looks polished.

### IV. Privacy and Security of Financial Data (NON-NEGOTIABLE)

No secret MUST be committed. `service_role` keys, tokens, and private credentials MUST live
outside the repository, in environment variables or CI secrets. Public or publishable keys
required by the Flutter client may be versioned only when they are designed for public
exposure. On Supabase, every table containing user data MUST have Row Level Security enabled
and policies that restrict reads and writes to the authenticated user's own rows. Logs,
analytics, and error messages MUST NOT contain tokens, email addresses, amounts, or other
financial data. Cloud synchronization MUST be enabled only after an explicit user action; the
user MUST be able to export and delete their data, and account deletion MUST NOT remove local
data without confirmation.

**Rationale**: a personal finance app handles sensitive information; a single leak compromises
trust and may have concrete consequences for the user.

### V. Controlled Updates and Traceable Releases

The update check MUST use GitHub releases over HTTPS, compare semantic versions, and MUST NOT
install anything automatically. Silent checks MUST run at most once per day; downloads MUST be
initiated by the user. A failed check MUST be non-blocking and MUST NOT produce repeated
notifications. Every release MUST be identified by a `vX.Y.Z` tag, MUST produce a signed
Android APK through the existing pipeline, and MUST include release notes. The version in
`pubspec.yaml` MUST be incremented consistently with the published tag.

**Rationale**: predictable, traceable updates reduce the risk of regressions and let the user
decide when to upgrade.

### VI. English as the Working Language (NON-NEGOTIABLE)

All source code, identifiers, comments, commit messages, pull request descriptions, tests,
scripts, configuration, and project documentation MUST be written in English. This includes
Spec Kit artifacts such as the constitution, specifications, plans, tasks, and checklists, and
any generated or hand-written document in the repository. User-facing text MUST NOT be
hardcoded: it MUST go through the ARB localization files and be provided in both
`lib/l10n/app_en.arb` and `lib/l10n/app_it.arb`. Other languages are permitted only inside
localized user-facing resources, never in code, comments, or documentation. Existing
non-English content MUST be migrated to English when it is next modified.

**Rationale**: a single working language keeps the codebase consistent, makes reviews and
onboarding predictable, and prevents mixed-language documentation from drifting.

## Technical Constraints and Platform

- Reference stack: Flutter and Dart stable (SDK `^3.10.7`), Material 3 via
  `flex_color_scheme`, state management with `provider`, authentication and sync with
  `supabase_flutter`, local persistence with `shared_preferences`, charts with `fl_chart`, and
  localization with ARB.
- Android is the primary release target; the UI MUST remain usable on small screens and in
  portrait orientation.
- New dependencies MUST be justified in terms of maintenance, license, size, and offline
  impact; the existing stack MUST be preferred when it solves the problem.
- Persisted models MUST remain backward compatible with existing JSON and CSV formats. Every
  schema change MUST include a migration and its tests.
- No network call MUST occur in rendering paths or in pure calculation functions.
- Every user-facing string MUST go through the ARB files and be present in both
  `lib/l10n/app_en.arb` and `lib/l10n/app_it.arb`.
- The code MUST pass `flutter analyze` without errors and comply with `flutter_lints`.

## Development Workflow and Quality

- Every feature follows the Spec-Driven Development cycle: `specify` → `plan` → `tasks` →
  `implement`. This constitution prevails over any other local practice or preference.
- Every change to financial calculations, statistics aggregation, data migrations, or
  synchronization MUST include unit or integration tests; `flutter test` MUST pass.
- Before merging: clean `flutter analyze`, passing tests, no secrets in the diff, updated
  localizations, and verified offline behavior.
- Commits follow Conventional Commits; pull requests MUST be small, reviewed, and kept
  separate from constitution changes.
- Non-obvious architectural decisions and persistence formats MUST be documented in the
  repository.
- The Definition of Done includes empty/error states, basic accessibility (tap targets,
  contrast, screen readers), and no regressions in offline functionality.

## Governance

This constitution supersedes every other practice in the project. When a request conflicts
with a constitutional principle, the principle prevails.

Amendments MUST be proposed through a pull request with a rationale, expected impact, and
migration plan; they require maintainer approval and a semantic version increment. Versioning
follows these rules: MAJOR for backward-incompatible removals or redefinitions of principles or
sections; MINOR for new principles, new sections, or material expansions of guidance; PATCH for
clarifications, wording fixes, and non-semantic refinements.

Every pull request and review MUST verify compliance with the constitution. Violations MUST be
justified, tracked, and explicitly approved; additional complexity MUST be justified.
Compliance MUST be reassessed at least on every release. The runtime reference guide is
`README.md`, together with this constitution.

**Version**: 1.1.0 | **Ratified**: 2026-10-31 | **Last Amended**: 2026-10-31
