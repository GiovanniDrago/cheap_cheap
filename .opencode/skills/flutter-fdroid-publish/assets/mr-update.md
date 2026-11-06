## Summary

| Field | Value |
|---|---|
| App | {{APP_NAME}} |
| Package ID | `{{PACKAGE_ID}}` |
| Previous version | `{{PREVIOUS_VERSION}}` (`{{PREVIOUS_VERSION_CODE}}`) |
| New version | `{{VERSION_NAME}}` (`{{CURRENT_VERSION_CODE}}`) |
| Commit | `{{COMMIT}}` |
| Tag | `{{TAG}}` |
| Category | {{CATEGORY}} |
| License | {{LICENSE}} |
| Source | {{SOURCE_CODE}} |
| Issue tracker | {{ISSUE_TRACKER}} |
| Fork | {{FORK_URL}} |
| Branch | `{{BRANCH}}` |
| ABIs | {{ABIS}} |
| Signing certificate SHA-256 | `{{SIGNING_KEY_SHA256}}` |
| Reproducible build | {{REPRODUCIBLE}} |

## What changed

{{UPDATE_SUMMARY}}

### Build recipe changes

- Flutter integration: {{FLUTTER_INTEGRATION}} (`{{FLUTTER_VERSION}}`)
- Flavor: {{FLAVOR}}
- ABI/version-code mapping: {{ABI_MAPPING}}
- `SOURCE_DATE_EPOCH`: {{SOURCE_DATE_EPOCH}}
- `PUB_CACHE`: {{PUB_CACHE}}
- Build path: {{BUILD_PATH}}
- Other changes: {{BUILD_NOTES}}

## Validation evidence

| Check | Result | Evidence |
|---|---|---|
| `fdroid readmeta` | {{READMETA_RESULT}} | {{READMETA_EVIDENCE}} |
| `fdroid rewritemeta` | {{REWRITEMETA_RESULT}} | {{REWRITEMETA_EVIDENCE}} |
| `fdroid lint -f` | {{LINT_RESULT}} | {{LINT_EVIDENCE}} |
| `fdroid checkupdates` | {{CHECKUPDATES_RESULT}} | {{CHECKUPDATES_EVIDENCE}} |
| Metadata checker | {{VALIDATOR_RESULT}} | {{VALIDATOR_EVIDENCE}} |
| APK URLs and checksums | {{APK_RESULT}} | {{APK_EVIDENCE}} |
| Fork pipeline | {{PIPELINE_RESULT}} | {{PIPELINE_URL}} |

## Checklist

### Metadata

* [ ] Metadata is in `metadata/<applicationId>.yml`.
* [ ] Metadata is valid YAML and uses LF line endings.
* [ ] Only the latest build blocks are present; no disabled versions.
* [ ] `commit` is the full 40-character hash.
* [ ] `CurrentVersion` and `CurrentVersionCode` match the new release.
* [ ] `VercodeOperation` has one entry per ABI build block.
* [ ] Descriptions, images, and changelogs remain in the upstream fastlane tree.
* [ ] No unrelated files are included in the MR.

### Build

* [ ] Releases are tagged and auto update is enabled.
* [ ] The ABI split still produces installable APKs for the declared ABIs.
* [ ] [Reproducible builds](https://f-droid.org/docs/Reproducible_Builds) still work, or the reason they do not is explained: {{REPRODUCIBILITY_NOTES}}
* [ ] The `binary` URLs and signing fingerprint match the new release.
* [ ] The issue tracker and author contact are still valid.

### Pipeline

* [ ] All pipelines pass.
* [ ] All warnings and errors in the Reports tab are fixed or explained.

---------------------

{{RFP_ISSUE}}
