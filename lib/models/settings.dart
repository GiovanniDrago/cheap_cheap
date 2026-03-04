import 'package:cheapcheap/models/reminder.dart';

class Settings {
  Settings({
    this.themeIndex = 0,
    this.themeMode = 'light',
    this.localeCode = 'en',
    this.currency = 'EUR',
    this.rewardImagesPerQuest = 1,
    this.hasSeenWelcome = false,
    List<Reminder>? reminders,
  }) : reminders = reminders ?? [];

  final int themeIndex;
  final String themeMode;
  final String localeCode;
  final String currency;
  final int rewardImagesPerQuest;
  final bool hasSeenWelcome;
  final List<Reminder> reminders;

  Settings copyWith({
    int? themeIndex,
    String? themeMode,
    String? localeCode,
    String? currency,
    int? rewardImagesPerQuest,
    bool? hasSeenWelcome,
    List<Reminder>? reminders,
  }) {
    return Settings(
      themeIndex: themeIndex ?? this.themeIndex,
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      currency: currency ?? this.currency,
      rewardImagesPerQuest: rewardImagesPerQuest ?? this.rewardImagesPerQuest,
      hasSeenWelcome: hasSeenWelcome ?? this.hasSeenWelcome,
      reminders: reminders ?? this.reminders,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeIndex': themeIndex,
      'themeMode': themeMode,
      'localeCode': localeCode,
      'currency': currency,
      'rewardImagesPerQuest': rewardImagesPerQuest,
      'hasSeenWelcome': hasSeenWelcome,
      'reminders': reminders.map((reminder) => reminder.toJson()).toList(),
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      themeIndex: json['themeIndex'] as int? ?? 0,
      themeMode: json['themeMode'] as String? ?? 'light',
      localeCode: json['localeCode'] as String? ?? 'en',
      currency: json['currency'] as String? ?? 'EUR',
      rewardImagesPerQuest: json['rewardImagesPerQuest'] as int? ?? 1,
      hasSeenWelcome: json['hasSeenWelcome'] as bool? ?? false,
      reminders: (json['reminders'] as List<dynamic>? ?? [])
          .map((item) => Reminder.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
