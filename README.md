# CheapCheap

CheapCheap is an expense tracker with monthly navigation, CSV import/export, categories, quests, and a gallery that unlocks rewards as you level up.

## Level Reward Images

Level reward images live in `assets/gallery/` and are auto-discovered from the asset manifest.

Add or replace images here:
- Path: `assets/gallery/`
- Supported formats: SVG or PNG
- Any filename is accepted; the app scans `assets/gallery/` at runtime
- Assets are already declared in `pubspec.yaml`

Example naming you can follow:
- `assets/gallery/level_01.svg`
- `assets/gallery/level_02.svg`

If there are more rewards needed than images available, the app will reuse older images at random.

## Running the App

```bash
flutter pub get
flutter run
```
