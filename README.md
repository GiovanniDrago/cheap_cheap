# CheapCheap

CheapCheap is an expense tracker with monthly navigation, CSV import/export, categories, and quests.

## Running the App

```bash
flutter pub get
flutter run
```

## Releasing Android APKs

```bash
./scripts/tag-release.sh vX.Y.Z
```

That command updates `pubspec.yaml`, pushes the version bump commit, creates an annotated tag, and pushes the tag. GitHub Actions then builds `build/app/outputs/flutter-apk/app-release.apk` and publishes it to the GitHub Release for that tag.
