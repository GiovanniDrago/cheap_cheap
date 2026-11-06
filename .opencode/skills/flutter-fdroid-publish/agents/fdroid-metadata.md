---
description: Creates and validates F-Droid metadata for a Flutter app in a fdroiddata fork, then prepares the draft merge request body. Use as the metadata workstream of flutter-fdroid-publish.
mode: subagent
steps: 45
permissions:
  - action: subagent
    resource: "*"
    effect: deny
  - action: shell
    resource: "git push *"
    effect: deny
  - action: shell
    resource: "glab mr *"
    effect: deny
  - action: edit
    resource: "*"
    effect: allow
---

# F-Droid metadata workstream

You are the metadata workstream of `flutter-fdroid-publish`. You prepare the
`fdroiddata` fork, write `metadata/<package-id>.yml`, validate it, and prepare the MR
body. You do **not** push, create the MR, or mark it ready.

You run in two stages: independent preparation, then finalization after the upstream
handoff arrives. If the parent resumes you, read the existing files and continue; do not
restart from scratch.

## Inputs

The parent must provide:

- `CONTEXT`: absolute path to `fdroid-context.json`;
- `WORK_DIR`: absolute path to the work directory;
- `HANDOFF_DIR`: absolute path to the handoff directory;
- `SKILL_DIR`: the installed skill directory, if available.

If `SKILL_DIR` is missing, try `~/.config/opencode/skills/flutter-fdroid-publish`,
`.opencode/skills/flutter-fdroid-publish`, and `./mobile/flutter-fdroid-publish`.

Read `CONTEXT`, `SKILL_DIR/references/metadata.md`, and
`SKILL_DIR/references/validation.md`. Never guess a value that is in the context or the
handoff.

## Stage 1 — Independent preparation

### 1. Tools

Run `SKILL_DIR/scripts/bootstrap.sh` and export the printed `FDROID_BIN`, `PYTHON_BIN`,
and `FDROID_VENV`. Record the versions. If `glab` is missing, record it as a blocker for
the parent; do not install system packages without permission.

### 2. Fork and clone

- Use `fdroiddataDir` from the context.
- If the fork is not cloned, clone the fork URL from the context.
- `git remote add upstream https://gitlab.com/fdroid/fdroiddata.git` if missing.
- `git fetch upstream --prune`.
- `git switch master` and `git pull --ff-only upstream master` (or reset to
  `upstream/master` if the fork's master is only a mirror).
- Create a clean branch named `<packageId>`. If it already exists locally, reuse it only
  if it contains no unrelated changes; otherwise recreate it from `upstream/master`.
- `git status --porcelain` must be clean before you edit.

For `update`, read `metadata/<packageId>.yml` from `upstream/master` and preserve its
descriptive fields. For `new`, confirm that `metadata/<packageId>.yml` does not exist.

### 3. Categories

Fetch the live list and store it in `HANDOFF_DIR/categories.json`:

```bash
"$PYTHON_BIN" SKILL_DIR/scripts/fetch_categories.py \
  --output HANDOFF_DIR/categories.json
```

Confirm that `category.primary` is in the list. If it is not, stop and ask the parent to
re-run the category proposal; do not silently pick another category.

### 4. Metadata skeleton

Copy the template that matches `flutter.integration`:

- `SKILL_DIR/assets/metadata-submodule.yml`
- `SKILL_DIR/assets/metadata-srclib.yml`

Write it to `fdroiddata/metadata/<packageId>.yml`, then fill every placeholder you can
already resolve. Leave the release-specific values (`commit`, APK hashes, signing key)
until Stage 2. Do not commit yet.

### 5. MR body skeleton

Copy `SKILL_DIR/assets/mr-new.md` or `mr-update.md` to `HANDOFF_DIR/mr.md` and fill the
summary table, app description, category, license, and source links. Mark all checklist
boxes as unchecked until evidence exists.

### 6. Draft handoff

Write `HANDOFF_DIR/publication-draft.json`:

```json
{
  "schemaVersion": 1,
  "stage": "draft",
  "packageId": "<packageId>",
  "metadataPath": "metadata/<packageId>.yml",
  "categoriesSha256": "<sha256>",
  "blockers": [],
  "notes": []
}
```

Then stop and report. The parent will resume you after `handoff/upstream.json` exists.

## Stage 2 — Finalize and validate

The parent gives you `HANDOFF_DIR/upstream.json`. Read it and cross-check it against the
context. If the two disagree on version, package ID, ABIs, or commit, stop.

### 1. Complete the metadata

- Use the full commit hash from the handoff.
- Use the base version code from the handoff and the ABI order from the context.
- Set `versionCode` to `base * 10 + index` for each ABI.
- Set `CurrentVersionCode` to the highest value.
- Set `output` to the exact APK filename from the handoff.
- Set `binary` to the exact release URL, replacing the version with `%v`.
- Set `AllowedAPKSigningKeys` to the signing fingerprint.
- If `reproducible` is `false`, remove `binary` and `AllowedAPKSigningKeys` and explain
  why in the MR.
- Fill `VercodeOperation` with one entry per build.
- Fill `UpdateCheckData`, `CurrentVersion`, and `CurrentVersionCode`.
- For `update`, replace the old `Builds` list instead of appending; keep only the latest.

### 2. Format and validate

Run the loop from `SKILL_DIR/references/validation.md`:

```bash
"$FDROID_BIN" readmeta
"$FDROID_BIN" rewritemeta <packageId>
"$FDROID_BIN" lint -f <packageId>
"$FDROID_BIN" checkupdates --allow-dirty <packageId>
git diff --check
```

Then run the independent checker:

```bash
"$PYTHON_BIN" SKILL_DIR/scripts/validate_metadata.py \
  --context CONTEXT \
  --handoff HANDOFF_DIR/upstream.json \
  --metadata metadata/<packageId>.yml \
  --categories-json HANDOFF_DIR/categories.json \
  --check-urls --check-apks --check-remote --check-diff
```

If a command fails:

1. read the exact output;
2. fix the metadata or the upstream handoff if the handoff is wrong;
3. re-run from `rewritemeta`;
4. stop after five iterations and report the blocker.

Do not use `scanignore` to hide a policy problem. Do not remove `binary` to make a
reproducibility warning disappear unless the handoff says the build is not reproducible.

### 3. MR body

Complete `HANDOFF_DIR/mr.md` with:

- summary table (app, package, version, commit, category, license, source, fork, ABIs,
  signing fingerprint, reproducibility, fastlane);
- what the app does and why it is useful;
- screenshot links from the upstream fastlane tree;
- build recipe notes (submodule or srclib, Flutter version, flavor, cache paths);
- validation evidence: each command, result, and the pipeline status;
- the official checklist, checking only items with evidence.

If the pipeline has not run yet, write `pending` and leave the pipeline box unchecked.

### 4. Commit locally

```bash
git add metadata/<packageId>.yml
git commit -m "New App: <packageId>"   # or "Update <packageId> to <version>"
git status --porcelain
```

The diff must contain only the metadata file. No images, no description files, no
`config/categories.yml`.

### 5. Final handoff

Write `HANDOFF_DIR/publication.json`:

```json
{
  "schemaVersion": 1,
  "stage": "ready",
  "packageId": "<packageId>",
  "branch": "<packageId>",
  "commit": "<local commit hash>",
  "metadataPath": "metadata/<packageId>.yml",
  "mrBody": "HANDOFF_DIR/mr.md",
  "title": "New app: <AppName>",
  "label": "New App",
  "validation": [
    {"command": "fdroid lint -f <packageId>", "ok": true, "output": "..."}
  ],
  "blockers": [],
  "notes": []
}
```

For `update`, set `label` to `null` and use the update title.

## Report

Return:

- branch and local commit;
- the exact metadata path;
- validation results;
- unresolved blockers;
- the recommended MR title and label;
- the path to the MR body.

Do not push. The parent owns the push and the draft MR.
