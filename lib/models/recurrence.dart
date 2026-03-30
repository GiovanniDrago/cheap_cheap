enum RecurrenceType { none, daily, monthly, yearly }

class Recurrence {
  Recurrence({
    required this.type,
    this.dayOfMonth,
    this.monthOfYear,
    this.reminderEnabled = false,
    this.reminderDaysBefore = 1,
    this.reminderMessage = '',
  });

  final RecurrenceType type;
  final int? dayOfMonth;
  final int? monthOfYear;
  final bool reminderEnabled;
  final int reminderDaysBefore;
  final String reminderMessage;

  Recurrence copyWith({
    RecurrenceType? type,
    int? dayOfMonth,
    int? monthOfYear,
    bool? reminderEnabled,
    int? reminderDaysBefore,
    String? reminderMessage,
  }) {
    return Recurrence(
      type: type ?? this.type,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      monthOfYear: monthOfYear ?? this.monthOfYear,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      reminderMessage: reminderMessage ?? this.reminderMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'dayOfMonth': dayOfMonth,
      'monthOfYear': monthOfYear,
      'reminderEnabled': reminderEnabled,
      'reminderDaysBefore': reminderDaysBefore,
      'reminderMessage': reminderMessage,
    };
  }

  factory Recurrence.fromJson(Map<String, dynamic> json) {
    return Recurrence(
      type: RecurrenceType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => RecurrenceType.none,
      ),
      dayOfMonth: json['dayOfMonth'] as int?,
      monthOfYear: json['monthOfYear'] as int?,
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
      reminderDaysBefore: json['reminderDaysBefore'] as int? ?? 1,
      reminderMessage: json['reminderMessage'] as String? ?? '',
    );
  }
}
