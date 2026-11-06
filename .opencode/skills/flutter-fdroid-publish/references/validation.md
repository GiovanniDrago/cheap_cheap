# Validation matrix and troubleshooting

Run everything from the `fdroiddata` clone unless stated otherwise. The `fdroid` command
must come from the virtual environment created by `scripts/bootstrap.sh`.

## Contents

- Bootstrap
- Static checks
- Update-check check
- Independent metadata check
- Build test
- Fork pipeline
- Error table
- MR gate

## 1. Bootstrap

```bash
scripts/bootstrap.sh
# prints FDROID_BIN and PYTHON_BIN; export them or use the absolute paths
```

The script installs `fdroidserver` (which includes `yamllint` and PyYAML) in
`$XDG_DATA_HOME/opencode/flutter-fdroid-publish/venv`, checks `git`, `python3`,
`keytool`, `glab`, and Docker, and records the versions. It does not install `glab`
automatically because the package name differs across distributions.

## 2. Static checks

```bash
cd fdroiddata

# Syntax and field types
"$FDROID_BIN" readmeta

# Canonical formatting: this writes the file
"$FDROID_BIN" rewritemeta <package-id>
git diff -- metadata/<package-id>.yml

# Semantic checks, including the live category list and formatting
"$FDROID_BIN" lint -f <package-id>

# Whitespace and line endings
git diff --check
file metadata/<package-id>.yml
```

`fdroid lint -f` is preferred over plain `lint` because it also reports formatting
problems, which are the most common cause of a red pipeline. `rewritemeta` removes
comments and normalizes line wrapping; apply its exact output instead of guessing the
wrap points.

## 3. Update-check check

```bash
"$FDROID_BIN" checkupdates --allow-dirty <package-id>
git diff -- metadata/<package-id>.yml
```

It may fill `AutoName` or adjust `CurrentVersion`. Review the diff. If it proposes a
different version, the tag, `UpdateCheckData`, or `VercodeOperation` is wrong; fix the
metadata instead of accepting the change blindly.

## 4. Independent metadata check

From the skill directory or with an absolute path:

```bash
scripts/validate_metadata.py \
  --context fdroid-context.json \
  --handoff handoff/upstream.json \
  --metadata fdroiddata/metadata/<package-id>.yml \
  --categories-json handoff/categories.json \
  --check-urls --check-apks --check-remote --check-diff
```

It checks placeholders, required fields, category membership, version-code arithmetic,
ABI/output/binary consistency, signing fingerprint, line endings, the git diff, APK URLs,
and the local upstream commit/tag. `--check-apks` also downloads each APK and verifies its
SHA-256 and signing certificate; omit it only on a metered connection, and say so in the
MR. Treat a non-zero exit as a blocker.

## 5. Build test

A full local build is optional but strongly recommended before the MR. The fastest
reliable path is the F-Droid buildserver container:

```bash
git clone --depth=1 https://gitlab.com/fdroid/fdroidserver ~/fdroidserver
sudo docker run --rm -itu vagrant --entrypoint /bin/bash \
  -v "$PWD":/build:z \
  -v ~/fdroidserver:/home/vagrant/fdroidserver:Z \
  registry.gitlab.com/fdroid/fdroidserver:buildserver
```

Inside the container:

```bash
. /etc/profile
export PATH="$HOME/fdroidserver:$PATH" PYTHONPATH="$HOME/fdroidserver"
export JAVA_HOME=$(java -XshowSettings:properties -version 2>&1 > /dev/null \
  | grep 'java.home' | awk -F'=' '{print $2}' | tr -d ' ')
cd /build
fdroid readmeta
fdroid rewritemeta <package-id>
fdroid lint -f <package-id>
fdroid build -t -l <package-id>
```

`-t` keeps the output in `tmp/` and forces a build; `-l` builds only the latest version.
A local build needs network access, the Android SDK/NDK, and several GB of disk. If the
environment cannot support it, rely on the fork pipeline and say so in the MR.

## 6. Fork pipeline

Push the branch to the fork. GitLab CI runs the F-Droid checks automatically:

```bash
git -C fdroiddata push -u origin <package-id>
```

Watch the pipeline in the MR or with:

```bash
glab -R <namespace>/fdroiddata ci status --branch <package-id>
glab -R fdroid/fdroiddata mr view <mr-id>
```

Do not claim the pipeline is green until it is. A pending pipeline is reported as pending
in the MR body.

## 7. Error table

| Symptom | Cause | Fix |
|---|---|---|
| `rewritemeta` produces a diff | Wrong wrapping, trailing space, key order | Apply the exact `rewritemeta` output |
| `Categories 'X' is not valid` | Old or misspelled category | Re-fetch `categories.yml`, re-propose, confirm |
| `Categories are not set` | Missing list | Add one valid category |
| `CurrentVersionCode` warning | Not the highest ABI code | Set it to the last block's code |
| `binary:` URL 404 | Release asset missing or `%v` wrong | Fix the tag/asset name, upload the APK |
| APK checksum mismatch | Build not reproducible or wrong asset | Fix path/epoch/toolchain; do not fake it |
| `AllowedAPKSigningKeys` mismatch | Wrong certificate or re-signed APK | Re-derive the SHA-256 from the referenced APK |
| `Dependency metadata` scanner error | Gradle dependency metadata | Add `dependenciesInfo { includeInApk = false; includeInBundle = false }` |
| `unknown maven repo` | Non-default repository | Use a trusted repository or document the exception; do not hide non-free code |
| `NonFree` / `NonFreeDep` | Proprietary dependency | Stop; F-Droid inclusion policy is not satisfied |
| `Unused scanignore path` | Path does not exist | Remove it or correct the path |
| `Non-exist scandelete path` | Path does not exist in this checkout | Remove it or correct the path |
| `versionCode` mismatch | `+N` extraction or `VercodeOperation` wrong | Fix `UpdateCheckData` / `VercodeOperation` |
| Pipeline fails on a protected branch | Branch protection in the fork | Unprotect the branch or use another branch |

## 8. MR gate

Before creating the draft MR:

- [ ] only `metadata/<package-id>.yml` changed;
- [ ] `fdroid readmeta`, `rewritemeta`, `lint -f`, `checkupdates` pass;
- [ ] independent script exits 0;
- [ ] APK URLs and checksums match;
- [ ] signing fingerprint matches;
- [ ] fork is public and the branch is not protected;
- [ ] MR body has evidence for every checked box;
- [ ] no placeholder remains;
- [ ] title uses the official format;
- [ ] the MR is draft.

Report the pipeline as `pending` until it finishes. Reviewer feedback is the final
authority; update the metadata and re-run the loop rather than arguing with the checklist.
