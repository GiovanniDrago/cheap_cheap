import 'package:cheapcheap/models/reminder.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings: settings);
  }

  static Future<void> scheduleReminder(Reminder reminder) async {
    final id = _notificationId(reminder.id);
    if (!reminder.notificationsEnabled) {
      await _plugin.cancel(id: id);
      return;
    }

    final scheduledDate = reminder.frequency == ReminderFrequency.weekly
        ? _nextWeekly(reminder)
        : _nextDaily(reminder);

    await _plugin.zonedSchedule(
      id: id,
      title: 'Reminder',
      body: reminder.message,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminders_channel',
          'Reminders',
          channelDescription: 'Expense reminder notifications',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: reminder.frequency == ReminderFrequency.weekly
          ? DateTimeComponents.dayOfWeekAndTime
          : DateTimeComponents.time,
    );
  }

  static Future<void> cancelReminder(String id) async {
    await _plugin.cancel(id: _notificationId(id));
  }

  static int _notificationId(String id) {
    return id.hashCode & 0x7fffffff;
  }

  static tz.TZDateTime _nextDaily(Reminder reminder) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminder.hour,
      reminder.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static tz.TZDateTime _nextWeekly(Reminder reminder) {
    final now = tz.TZDateTime.now(tz.local);
    final weekday = reminder.weekday ?? now.weekday;
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminder.hour,
      reminder.minute,
    );
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
