# Merge request body and draft state

F-Droid reviews merge requests, not pull requests. The official template is
`.gitlab/merge_request_templates/Default.md` in `fdroiddata`. It is written for a new app
inclusion; for updates, keep the same structure and replace the inclusion-specific text.

Use `assets/mr-new.md` or `assets/mr-update.md` as the body, fill every placeholder, and
only check a box when the MR contains the evidence for it.

## Title and labels

| Mode | Title | Label |
|---|---|---|
| `new` | `New app: <AppName>` | `New App` |
| `update` | `Update <AppName> to <version>` | none, unless the user asks for an existing label |

Create the MR with `--draft`. GitLab adds the draft marker itself; do not also prefix the
title with `Draft:` or the title becomes `Draft: Draft: ...`.

For a first submission that closes an RFP issue, keep `Closes rfp#<number>` in the body.
Do not invent an issue number.

## Required body sections

1. **Summary table**: app name, package ID, version/versionCode, commit, category,
   license, source, issue tracker, fork, ABIs, signing fingerprint, reproducible build,
   fastlane metadata.
2. **What the app does**: one short paragraph, taken from the upstream description.
3. **Why this app**: the unique function over similar apps, if the user provided it.
4. **Screenshots**: links to the upstream fastlane images, not uploads to `metadata/`.
5. **Build recipe notes**: Flutter integration (submodule or srclib), Flutter version,
   flavor, `PUB_CACHE`, `SOURCE_DATE_EPOCH`, ABI mapping.
6. **Validation evidence**: a table of command → result, including the pipeline status and
   the URL. `pending` is an acceptable value only while the pipeline is running.
7. **Official checklist**: the boxes from the template, each with a short evidence note.

## Checklist rules

- Do not check `The app complies with the inclusion policy` unless the user confirmed the
  license and the absence of non-free dependencies.
- Do not check `The original app author has been notified` unless the user is the author
  or provided the notification link.
- Do not check `All pipelines should pass` while a pipeline is pending or failed.
- Do not check `Enable Reproducible Builds` if `binary:` was removed; explain why instead.
- Do not check `Setup abi split` if the app intentionally ships a single ABI.
- If a requirement does not apply, leave it unchecked and add a one-line explanation.
- Never paste tokens, keystore contents, or private contact details.

## Draft lifecycle

1. Create the MR with `scripts/create_draft_mr.sh --execute`.
2. Report the URL and the pipeline status.
3. Wait for the user's confirmation before marking it ready:

   ```bash
   glab -R fdroid/fdroiddata mr update <mr-id> --ready
   ```

4. After the user marks it ready, continue to handle reviewer feedback in the same branch.
   Re-run the validation loop after every metadata change.

## Update MRs

An update MR should state:

- the previous version and the new version;
- what changed in the upstream build recipe, if anything;
- the new commit and tag;
- whether the Flutter version or ABI set changed;
- that only the latest build blocks are present;
- that descriptions, images, and changelogs remain in the upstream fastlane tree.

Do not include the new-app policy checklist verbatim if it does not apply. Keep the
metadata, pipeline, and reproducible-build checks.
