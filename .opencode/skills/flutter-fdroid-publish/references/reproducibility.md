# Reproducible builds and signing

F-Droid builds the app from source and compares the result with the developer's signed
APK when `binary:` is present. A mismatch fails the build. Reproducibility is therefore a
gate, not a decoration.

## Why it matters

- The developer's signature stays on the APK, so users can switch between the developer's
  channel and F-Droid without reinstalling.
- F-Droid verifies that the published APK matches the published source.
- If reproducibility cannot be achieved, F-Droid signs with its own key and the app
  cannot switch to developer signing later without a reinstall.

## Make the upstream build reproducible

The release workflow should:

1. check out the exact tag;
2. export `SOURCE_DATE_EPOCH` from the commit timestamp:

   ```bash
   export SOURCE_DATE_EPOCH="$(git log -1 --format=%ct "$GITHUB_SHA")"
   ```

3. build from the same absolute path that the F-Droid recipe uses, for example
   `/home/vagrant/build/<package-id>`;
4. avoid embedding the current time, hostname, user name, or a random build directory;
5. commit `pubspec.lock` and use `flutter pub get --enforce-lockfile`;
6. pin Flutter and the Android toolchain;
7. build each ABI separately with `--split-per-abi` and the same `--build-name`,
   `--build-number`, `--flavor`, and `--dart-define` values used in the metadata.

The F-Droid recipe must mirror the workflow. If upstream builds in
`/home/vagrant/build/<package-id>`, the metadata must move the checkout to the same path
before running Flutter. The official Flutter template shows the `mv` / `pushd` pattern.

## Flutter specifics

- Flutter downloads engine artifacts into `.flutter/bin/cache`; add that path to
  `scanignore`.
- Dart packages go into `PUB_CACHE`; set it inside the checkout and add it to
  `scandelete`.
- The APK filename order is `app-<abi>-<flavor>-release.apk`.
- `--build-number` must be the base version code, i.e. `$$VERCODE$$ / 10`.
- The same Flutter version must be used upstream and in the recipe. With a submodule, the
  gitlink pins it. With a srclib, the workflow string is checked out explicitly.

## Verify locally

Build the same way and compare checksums:

```bash
sha256sum build/app/outputs/flutter-apk/app-*-release.apk
```

If the local checksum matches the GitHub release asset, the build is likely reproducible.
If it does not, the difference may be environmental; F-Droid CI is the final authority.
Use the build log diff to find path, timestamp, or version differences.

## Signing certificate

Derive the fingerprint from the release APK that will be referenced by `binary:`:

```bash
keytool -printcert -jarfile app-arm64-v8a-direct-release.apk \
  | sed -n 's/[[:space:]]*SHA256: //p' \
  | tr -d ':' | tr '[:upper:]' '[:lower:]'
```

or:

```bash
apksigner verify --print-certs app-arm64-v8a-direct-release.apk | grep SHA-256
```

Use the result as `AllowedAPKSigningKeys`. It is a certificate fingerprint, not the APK
checksum. Never use a debug key for a production app.

## When reproducibility is not achievable

Do not add `binary:` and do not add `AllowedAPKSigningKeys`. F-Droid will build and sign
the APK with its own key. Explain in the MR why reproducibility is not possible and what
was tried. Do not fake a `binary:` URL to make the checklist look complete.
