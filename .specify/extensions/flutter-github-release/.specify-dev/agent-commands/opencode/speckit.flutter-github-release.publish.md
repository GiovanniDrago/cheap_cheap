---
description: Compute the next Flutter release tag, confirm it, and publish through the existing tag-driven GitHub release flow
---


<!-- Extension: flutter-github-release -->
<!-- Config: .specify/extensions/flutter-github-release/ -->
# Publish a Flutter GitHub release

Use this command to release a Flutter Android app that already has the tag-driven GitHub release
automation created by the `flutter-github-deploy` skill. The command computes the next version tag,
asks the user to confirm or change it, then runs the project's own `.specify/extensions/flutter-github-release/scripts/tag-release.sh`.

## User Input

```text
$ARGUMENTS
```

If the input looks like a release tag (`vX.Y.Z` or `X.Y.Z`), treat it as the user's candidate tag.
Otherwise ignore it and use the computed proposal.

## Preconditions

Do not create, repair, or replace release automation from this command. The following must already
exist:

- `pubspec.yaml` with a `version:` field
- executable `.specify/extensions/flutter-github-release/scripts/tag-release.sh`
- a `.github/workflows/*.yml` workflow triggered by `v*` tags that publishes a GitHub Release

If either the script or the workflow is missing, this command must stop and recommend the
`flutter-github-deploy` skill. It must not implement the release setup itself.

## Steps

1. From the repository root, run the planning script:

   ```bash
   .specify/extensions/flutter-github-release/scripts/plan-release.sh
   ```

   The script prints `KEY=VALUE` lines on stdout and warnings on stderr. It does not modify files.

   - Exit code `10`: release automation is incomplete. Report exactly which pieces are missing,
     tell the user to install/apply the `flutter-github-deploy` skill first, and stop. Do not make
     any other change.
   - Any other non-zero exit code: report the error and stop.

2. Parse the output and show a compact summary to the user:

   - current version from `pubspec.yaml`
   - latest release tag
   - proposed bump (`major`, `minor`, or `patch`) and its reason
   - proposed tag
   - build number
   - all warnings from the planning script

3. Ask the user to confirm the proposed tag or provide a different one. Prefer the question tool
   when it is available; otherwise ask in plain text and wait for the answer. The user must be able
   to accept the proposal, type another tag, or cancel. If the user cancels, stop without changing
   anything.

4. If the user provides a different tag, validate it from the repository root:

   ```bash
   .specify/extensions/flutter-github-release/scripts/validate-tag.sh <tag> "<LATEST_VERSION>"
   ```

   The script normalizes `vX.Y.Z` / `X.Y.Z`, rejects invalid versions, rejects tags that are not
   greater than the latest release, and rejects tags that already exist locally or on `origin`.
   If it fails, explain the reason and ask again. Use the normalized tag printed on success.

5. Run the project release script from the repository root:

   ```bash
   .specify/extensions/flutter-github-release/scripts/tag-release.sh <tag>
   ```

   Do not edit `pubspec.yaml`, create commits, create tags, or push manually. The project script owns
   the version bump, commit, push, annotated tag, and tag push.

6. If `GH_AVAILABLE=true`, monitor the triggered workflow:

   - Find the newest run for `WORKFLOW_FILE` whose `headSha` matches the tagged commit. If no run
     appears immediately, wait a few seconds and retry a few times.
   - Wait for it with `gh run watch <run-id> --exit-status`.
   - If it fails, report the run URL and stop. Do not retry or delete the tag automatically.

   If `GH_AVAILABLE=false`, report that the branch and tag were pushed and that GitHub Actions will
   publish the release.

7. On success, report the GitHub Release URL and the asset names:

   ```bash
   gh release view <tag> --json url,assets --jq '{url: .url, assets: [.assets[].name]}'
   ```

8. If `.specify/extensions/flutter-github-release/scripts/tag-release.sh` fails partway, report exactly what was committed, pushed, and tagged.
   Do not roll back automatically; let the user decide.

## Rules

- Never run this command against a non-Flutter project.
- Never create `.specify/extensions/flutter-github-release/scripts/tag-release.sh` or the release workflow here; use `flutter-github-deploy`.
- Never bypass the confirmation step.
- Reply in the user's language.