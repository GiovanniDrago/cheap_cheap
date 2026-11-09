# Flutter GitHub Release

Project-scoped Spec Kit extension for Flutter Android apps that already use the release automation
created by the `flutter-github-deploy` skill.

It adds one command:

- `speckit.flutter-github-release.publish`

The command:

1. validates that `scripts/tag-release.sh` and a tag-triggered GitHub Actions release workflow exist;
2. computes the next semantic version from the latest `vX.Y.Z` tag and the commits since it;
3. shows the proposal and asks the user to confirm it or enter a different tag;
4. validates the chosen tag;
5. runs `./scripts/tag-release.sh <tag>`, which owns the version bump, commit, push, and tag;
6. monitors the GitHub Actions run when `gh` is available and reports the release URL and assets.

If the release script or the release workflow is missing, the command stops with exit code `10` and
recommends installing/applying the `flutter-github-deploy` skill. It does not create the release
setup itself.

## Version rules

The base version is the higher of the `pubspec.yaml` version and the latest `vX.Y.Z` tag. The bump
is derived from the commit subjects and bodies since the latest tag:

| Commit | Bump |
|---|---|
| `BREAKING CHANGE` or `!:` | `major` (`minor` when the current major is `0`) |
| `feat:` | `minor` |
| anything else | `patch` |

The build number is `major * 10000 + minor * 100 + patch`, matching `scripts/tag-release.sh`.

If the latest tag is not available locally, or the current branch is behind or diverged from it, the
command cannot reliably read the commits since that release. In that case it warns and defaults to
a patch bump; the user can still type a different tag during confirmation.

## Install

From the `opencode-skills` repository:

```bash
./install.sh --extensions flutter-github-release --project /path/to/flutter_app
```

Or directly from the target project:

```bash
specify extension add --dev /path/to/opencode-skills/speckit/flutter-github-release
```

The target must be a Spec Kit project (it must contain `.specify/`). Extensions are project-scoped;
there is no global install location.

## Usage

```text
/speckit.flutter-github-release.publish
/speckit.flutter-github-release.publish v1.4.0
```

The command still asks for confirmation when a tag is passed as an argument.

## Requirements

- `git`
- `bash` 4+ and GNU coreutils (`sort -V`)
- `gh` for automatic workflow monitoring (optional)
- the release setup produced by `flutter-github-deploy`:
  - `scripts/tag-release.sh`
  - `.github/workflows/android-release-build.yml` (or another tag-triggered workflow that publishes
    a GitHub Release)

## Notes

- `plan-release.sh` performs a best-effort `git fetch --tags origin` to see remote tags. Set
  `PLAN_RELEASE_NO_FETCH=1` to skip it.
- The command blocks on uncommitted tracked changes. Untracked files only produce a warning because
  they are not included in the release tag.
