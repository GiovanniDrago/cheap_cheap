# Phase 0 — Interview and preflight

The interview is a single batch of questions, not a long back-and-forth. Ask only what
you cannot derive from the repository, and propose a default for every question.

## Contents

- Detect the local GitLab identity
- Questions
- Derive and verify
- Fork preflight
- Repository preflight
- Context file

## 1. Detect the local GitLab identity

Run these checks before asking about the fork:

```bash
command -v glab && glab auth status
glab api user 2>/dev/null | jq -r '.username // empty'
git config --global --get user.name
git config --global --get user.email
```

Rules:

- If `glab auth status` shows exactly one authenticated `gitlab.com` account, propose its
  username as the default fork namespace.
- If several hosts or accounts are authenticated, list them and ask which one to use.
- If `glab` is missing but a `GITLAB_TOKEN` is set, the token owner is the default; never
  print the token.
- If no identity is available, ask the user to authenticate. Do not create a fork with an
  unauthenticated session.

The fork is a fork of **`fdroid/fdroiddata`**, not of the app repository. The app
repository is upstream; `fdroiddata` is the metadata repository reviewed by F-Droid.

## 2. Questions

Ask the following in one message. Mark the derived values and ask the user to confirm.

| Field | Default / source |
|---|---|
| Mode | `new` or `update`; check the upstream metadata URL |
| App repository | `git remote get-url origin` in the app checkout |
| Default branch | `git symbolic-ref refs/remotes/origin/HEAD` |
| Package ID | `applicationId` in `android/app/build.gradle(.kts)` or `AndroidManifest.xml` |
| App name | `android:label`, `pubspec.yaml` `name`, or fastlane `title.txt` |
| Version name | `version:` in `pubspec.yaml`, before `+` |
| Base version code | `version:` in `pubspec.yaml`, after `+` |
| Release tag | `git describe --tags --exact-match` or the newest matching tag |
| Flavor | Gradle `productFlavors`; empty if none |
| ABIs | `armeabi-v7a`, `arm64-v8a`, `x86_64` unless the user needs fewer |
| License | `LICENSE` / `README`; must be an SPDX identifier |
| Author name | `git log` author, fastlane, or the user |
| Issue tracker | `<source>/issues` |
| Changelog | `<source>/releases` |
| Website | Optional; do not reuse `SourceCode` |
| RFP issue | `rfp#<number>` for a first submission, if one exists |
| Fork host | The authenticated GitLab host, default `https://gitlab.com` |
| Fork namespace | The authenticated username, or a group the user names |
| Fork protocol | `ssh` if `ssh -T git@<host>` works, otherwise `https` |
| Existing fork | `https://<host>/<namespace>/fdroiddata` |
| Draft MR tool | `glab` if installed and authenticated; otherwise ask permission to install it. If the user declines, stop after the push and print the MR creation URL. |
| Flutter integration | `submodule` (recommended) or `srclib` (fallback) |
| Upstream edits allowed | `true` only after the user sees the planned diff |
| Upstream push allowed | `true` only with explicit confirmation |
| Automatic fork push + draft MR | `true` only with explicit confirmation |
| MR language | `en` |

Do not ask for a keystore password. The signing certificate fingerprint is derived from
the release APK, not from the keystore.

## 3. Derive and verify

Useful commands:

```bash
# package ID and version
grep -R "applicationId" android/app/build.gradle android/app/build.gradle.kts 2>/dev/null
grep -n "^version:" pubspec.yaml

# tags and commit
git fetch --tags --force
git describe --tags --exact-match 2>/dev/null || git tag --sort=-v:refname | head -5
git rev-parse HEAD

# signing certificate from a release APK
keytool -printcert -jarfile app-release.apk \
  | sed -n 's/[[:space:]]*SHA256: //p' \
  | tr -d ':' | tr '[:upper:]' '[:lower:]'
```

If `apksigner` is available, it is equally valid:

```bash
apksigner verify --print-certs app-release.apk | grep SHA-256
```

## 4. Fork preflight

Check the fork before promising to use it:

```bash
# Encode the project path for the API.
encoded="$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$namespace/fdroiddata")"

glab api "projects/$encoded" | jq '{path_with_namespace, visibility, default_branch}'
glab api "projects/$encoded/protected_branches" | jq -r '.[].name'
```

Required:

- `visibility` is `public` (F-Droid reviewers must be able to see the fork and branch);
- `master` is not protected in the fork;
- the fork's `master` is up to date with `fdroid/fdroiddata` before branching;
- the authenticated user can push to the fork.

If the fork does not exist, create it only after the user confirms the namespace:

```bash
glab repo fork fdroid/fdroiddata --clone --name fdroiddata
```

`glab repo fork` forks into the authenticated user's namespace. For a group namespace,
use the GitLab web UI or the API and then clone the resulting URL.

## 5. Repository preflight

In the app checkout:

```bash
git status --porcelain
git remote -v
git tag --points-at HEAD
```

Stop when:

- the work tree is dirty (ask the user to commit or stash);
- there is no release tag and the user does not want to create one;
- the release APKs are missing;
- the license is missing or non-FOSS;
- the app depends on Firebase, Google Play Services, or another proprietary component
  without a free flavor.

## 6. Context file

Start from `assets/context.example.json`, replace every value, and validate:

```bash
scripts/validate_context.py --schema assets/context.schema.json fdroid-context.json
```

The context must contain:

- `mode`, `app`, `upstream`, `release`, `flutter`, `fork`, `category`, `approvals`,
  `mr`, `paths`;
- the category's `sourceSha256` from `scripts/fetch_categories.py`;
- `approvals.neverReadyWithoutUser: true`;
- no token, password, keystore path, or secret.

Show the user a short summary of the context and the planned upstream diff before
launching the subagents.
