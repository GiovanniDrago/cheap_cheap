import 'package:cheapcheap/models/settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults both profile sections to expanded', () {
    final settings = Settings();

    expect(settings.profileQuestsExpanded, isTrue);
    expect(settings.profileStatsExpanded, isTrue);
  });

  test('fromJson defaults missing expansion fields to true', () {
    final settings = Settings.fromJson(<String, dynamic>{});

    expect(settings.profileQuestsExpanded, isTrue);
    expect(settings.profileStatsExpanded, isTrue);
  });

  test('toJson round-trips expansion fields', () {
    final settings = Settings(
      profileQuestsExpanded: false,
      profileStatsExpanded: false,
    );

    final restored = Settings.fromJson(settings.toJson());

    expect(restored.profileQuestsExpanded, isFalse);
    expect(restored.profileStatsExpanded, isFalse);
  });
}
