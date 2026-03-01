enum ReminderFrequency { daily, weekly }

class Reminder {
  Reminder({
    required this.id,
    required this.frequency,
    required this.hour,
    required this.minute,
    required this.message,
  });

  final String id;
  final ReminderFrequency frequency;
  final int hour;
  final int minute;
  final String message;

  Reminder copyWith({
    String? id,
    ReminderFrequency? frequency,
    int? hour,
    int? minute,
    String? message,
  }) {
    return Reminder(
      id: id ?? this.id,
      frequency: frequency ?? this.frequency,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      message: message ?? this.message,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'frequency': frequency.name,
      'hour': hour,
      'minute': minute,
      'message': message,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      frequency: ReminderFrequency.values.firstWhere(
        (value) => value.name == json['frequency'],
        orElse: () => ReminderFrequency.daily,
      ),
      hour: json['hour'] as int? ?? 9,
      minute: json['minute'] as int? ?? 0,
      message: json['message'] as String? ?? '',
    );
  }
}
