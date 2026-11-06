---
description: Prepares a Flutter Android repository for F-Droid publication: reproducible ABI-split release build, signing fingerprint, fastlane metadata, tag and release assets. Use as the upstream workstream of flutter-fdroid-publish.
mode: subagent
steps: 40
permissions:
  - action: subagent
    resource: "*"
    effect: deny
  - action: shell
    resource: "git push *"
    effect: deny
  - action: shell
    resource: "glab *"
    effect: deny
  - action: edit
    resource: "*"
    effect: allow
---

# Upstream preparation for F-Droid

You are the upstream workstream of `flutter-fdroid-publish`. You prepare the app
repository and produce a machine-readable handoff. You do **not** push, create a merge
request, or mark anything ready.

## Inputs

The parent must provide:

- `CONTEXT`: absolute path to `fdroid-context.json`;
- `WORK_DIR`: absolute path to the work directory;
- `HANDOFF_DIR`: absolute path to the handoff directory;
- `SKILL_DIR`: the installed skill directory, if available.

If `SKILL_DIR` is missing, try `~/.config/opencode/skills/flutter-fdroid-publish`,
`.opencode/skills/flutter-fdroid-publish`, and `./mobile/flutter-fdroid-publish`.

Read `CONTEXT` and `SKILL_DIR/references/reproducibility.md`. Validate the context with
`SKILL_DIR/scripts/validate_context.py` if possible. Never guess a missing value.

## Work tree

1. Use `upstreamDir` from the context.
2. Require a clean work tree: `git status --porcelain` must be empty. If it is not, stop.
3. Create a branch `fdroid/<versionName>` from the current release commit unless the
   parent gave a branch. Do not commit to the default branch.
4. Keep all edits scoped to F-Droid readiness. Do not refactor the app.
5. Commit the changes on that branch with a clear message and create the release tag
   locally if it is missing. Do not push.

## Tasks

### 1. Verify the release identity

- [ ] `pubspec.yaml` version is `<versionName>+<baseVersionCode>`.
- [ ] The release tag exists and points at `HEAD`.
- [ ] `applicationId` matches `app.packageId`.
- [ ] The release APKs for every ABI in `release.abis` exist, or the GitHub Actions
      workflow can produce them.
- [ ] The signing certificate is a release certificate, not a debug certificate.

If the tag is missing, create it locally only after confirming the version. If the
release assets are missing, run the release workflow and wait. If no workflow exists,
stop and recommend the `flutter-github-deploy` skill; do not invent a release pipeline.

### 2. Gradle readiness

Add the dependency metadata suppression inside the `android { ... }` block:

```gradle
dependenciesInfo {
    includeInApk = false
    includeInBundle = false
}
```

Add ABI-specific version codes after `android { ... }` and before `flutter { ... }`:

```gradle
import com.android.build.gradle.internal.api.ApkVariantOutputImpl

def abiCodes = ['armeabi-v7a': 1, 'arm64-v8a': 2, 'x86_64': 3]

android.applicationVariants.configureEach { variant ->
    variant.outputs.each { output ->
        def abiFilter = output.filters.find { it.filterType == "ABI" }
        def abiVersionCode = abiCodes[abiFilter?.identifier]
        if (abiVersionCode != null) {
            ((ApkVariantOutputImpl) output).versionCodeOverride = variant.versionCode * 10 + abiVersionCode
        }
    }
}
```

The mapping must match `release.abis` and the order in the context. If the project uses
Kotlin DSL, adapt the same variant-output override and verify it with a real build.

Ask before removing NDK pinning. Some Flutter plugins need a specific NDK; do not remove
it blindly. If the NDK is only inherited from `flutter.ndkVersion`, the reviewer may ask
to remove it, but the build must still pass.

### 3. Flutter integration

If `flutter.integration == "submodule"`:

```bash
git submodule add https://github.com/flutter/flutter.git .flutter
git -C .flutter checkout "<flutter.version>"
git add .gitmodules .flutter
```

Use the exact Flutter version from the release workflow. The gitlink must be committed so
F-Droid can check out the same commit. Do not use a moving branch.

If `flutter.integration == "srclib"`:

- do not add a submodule;
- ensure the release workflow contains `flutter-version: 'x.y.z'`;
- the metadata agent will use `srclibs: flutter@stable`.

### 4. Reproducible release workflow

Inspect `.github/workflows/<workflowFile>` and make only the changes needed for:

- `SOURCE_DATE_EPOCH` from the release commit;
- a stable absolute build path, for example `/home/vagrant/build/<packageId>`;
- `flutter build apk --release --split-per-abi` for each ABI;
- `--build-name` and `--build-number` matching the metadata;
- upload of the three APKs to the GitHub release.

Do not duplicate the `flutter-github-deploy` skill. If the workflow already produces
signed ABI-split APKs, leave it alone apart from the reproducibility fixes.

### 5. Fastlane metadata

Ensure `fastlane/metadata/android/en-US/` contains:

- `title.txt` (app name);
- `short_description.txt` (under 80 characters, no trailing dot);
- `full_description.txt`;
- `images/icon.png` (512x512 PNG);
- `images/phoneScreenshots/` with at least two PNG/JPEG files;
- `changelogs/default.txt` (under 500 characters), and optionally per-version files.

For ABI-split builds, F-Droid matches changelog files against each build's versionCode.
Use `changelogs/default.txt` as the safe fallback, and add `changelogs/<code>.txt` copies
only if the reviewer asks for them.

Do not put images or descriptions in `fdroiddata`; they stay upstream.

### 6. Build and verify

Build the three APKs with the same commands as the workflow:

```bash
flutter pub get --enforce-lockfile
flutter build apk --release --split-per-abi --build-name "<versionName>" \
  --build-number "<baseVersionCode>" <flavor and dart-define flags>
```

Then verify:

- [ ] exactly three APKs, with the expected names;
- [ ] each APK reports the expected `versionName` and ABI-specific `versionCode`;
- [ ] each APK is signed by the release certificate;
- [ ] SHA-256 of each APK is recorded;
- [ ] the signing certificate SHA-256 is recorded.

If Flutter or the Android SDK is not available locally, use the GitHub Actions release
and download the assets. Do not fabricate checksums.

### 7. Handoff

Write `HANDOFF_DIR/upstream.json`:

```json
{
  "schemaVersion": 1,
  "appId": "<packageId>",
  "branch": "fdroid/<versionName>",
  "release": {
    "versionName": "<versionName>",
    "baseVersionCode": 20011,
    "tag": "v2.0.11",
    "commit": "<full 40-char hash>",
    "workflowFile": "android-release-build.yml",
    "flutterVersion": "3.x.y",
    "buildPath": "/home/vagrant/build/<packageId>",
    "flavor": "direct",
    "abis": [
      {
        "abi": "armeabi-v7a",
        "apk": "app-armeabi-v7a-direct-release.apk",
        "url": "https://github.com/example/notes/releases/download/v2.0.11/app-armeabi-v7a-direct-release.apk",
        "sha256": "<64 hex>"
      }
    ],
    "signingKeySha256": "<64 hex>",
    "reproducible": true
  },
  "checks": [
    {"name": "release-tag", "ok": true, "detail": "v2.0.11 -> <commit>"}
  ],
  "warnings": []
}
```

Use the exact absolute APK paths in the report, plus the diff summary and the commands you
ran. If the build is not reproducible, set `reproducible` to `false` and explain what was
tried; the metadata agent will omit `binary:` and `AllowedAPKSigningKeys`.

## Report

Return a short report:

- branch and commit;
- files changed;
- APK names, URLs, checksums;
- signing fingerprint;
- reproducibility result;
- anything the metadata agent must not guess.

Do not push. The parent owns the push.
