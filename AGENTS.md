# AGENTS.md

Guidance for AI coding agents working in this repository.

## Language Policy (NON-NEGOTIABLE)

All repository content MUST be written in English, including:

- source code, identifiers, comments, and doc comments
- tests, scripts, and configuration files
- commit messages and pull request descriptions
- documentation and Spec Kit artifacts (constitution, specifications, plans, tasks,
  checklists)

User-facing strings MUST NOT be hardcoded. They MUST live in the ARB localization files and be
provided in both `lib/l10n/app_en.arb` and `lib/l10n/app_it.arb`. Languages other than English
are allowed only inside localized user-facing resources.

Existing non-English content MUST be migrated to English when it is next modified.

## Source of Truth

`.specify/memory/constitution.md` defines the project principles. Read it before planning or
implementing any change. When this file and the constitution disagree, the constitution wins.

## Spec-Driven Development

Features follow the Spec Kit workflow:

1. `/speckit.specify`
2. `/speckit.plan`
3. `/speckit.tasks`
4. `/speckit.implement`

Use `/speckit.clarify` and `/speckit.analyze` when requirements or artifacts need validation.

## Quality Gates

- `flutter analyze` MUST pass without errors.
- `flutter test` MUST pass.
- Changes to financial calculations, statistics, migrations, or sync MUST include tests.
- Never commit secrets. Public or publishable client keys are allowed; private credentials are
  not.
