import 'package:cheapcheap/models/reminder.dart';

class Settings {
  Settings({
    this.themeIndex = 0,
    this.themeMode = 'light',
    this.localeCode = 'en',
    this.currency = 'EUR',
    this.hasSeenWelcome = false,
    this.budgetSortAscending = false,
    this.dateFormat = 'dd/MM/yyyy',
    this.weekStart = 'monday',
    List<Reminder>? reminders,
  }) : reminders = reminders ?? [];

  final int themeIndex;
  final String themeMode;
  final String localeCode;
  final String currency;
  final bool hasSeenWelcome;
  final bool budgetSortAscending;
  final String dateFormat;
  final String weekStart;
  final List<Reminder> reminders;

  Settings copyWith({
    int? themeIndex,
    String? themeMode,
    String? localeCode,
    String? currency,
    bool? hasSeenWelcome,
    bool? budgetSortAscending,
    String? dateFormat,
    String? weekStart,
    List<Reminder>? reminders,
  }) {
    return Settings(
      themeIndex: themeIndex ?? this.themeIndex,
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      currency: currency ?? this.currency,
      hasSeenWelcome: hasSeenWelcome ?? this.hasSeenWelcome,
      budgetSortAscending: budgetSortAscending ?? this.budgetSortAscending,
      dateFormat: dateFormat ?? this.dateFormat,
      weekStart: weekStart ?? this.weekStart,
      reminders: reminders ?? this.reminders,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeIndex': themeIndex,
      'themeMode': themeMode,
      'localeCode': localeCode,
      'currency': currency,
      'hasSeenWelcome': hasSeenWelcome,
      'budgetSortAscending': budgetSortAscending,
      'dateFormat': dateFormat,
      'weekStart': weekStart,
      'reminders': reminders.map((reminder) => reminder.toJson()).toList(),
    };
  }

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      themeIndex: json['themeIndex'] as int? ?? 0,
      themeMode: json['themeMode'] as String? ?? 'light',
      localeCode: json['localeCode'] as String? ?? 'en',
      currency: json['currency'] as String? ?? 'EUR',
      hasSeenWelcome: json['hasSeenWelcome'] as bool? ?? false,
      budgetSortAscending: json['budgetSortAscending'] as bool? ?? false,
      dateFormat: json['dateFormat'] as String? ?? 'dd/MM/yyyy',
      weekStart: json['weekStart'] as String? ?? 'monday',
      reminders: (json['reminders'] as List<dynamic>? ?? [])
          .map((item) => Reminder.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
