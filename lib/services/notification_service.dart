import 'package:cheapcheap/models/reminder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum NotificationScheduleStatus {
  scheduled,
  disabled,
  notificationPermissionDenied,
  exactAlarmPermissionDenied,
}

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    await _configureLocalTimezone();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings: settings);
  }

  static Future<bool> areNotificationsEnabled() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  static Future<bool> requestNotificationPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (macos != null) {
      return await macos.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return true;
  }

  static Future<bool> canScheduleExactAlarms() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return true;
    }
    return await android.canScheduleExactNotifications() ?? false;
  }

  static Future<bool> requestExactAlarmPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) {
      return true;
    }
    return await android.requestExactAlarmsPermission() ?? false;
  }

  static Future<NotificationScheduleStatus> scheduleReminder(
    Reminder reminder,
  ) async {
    final id = _notificationId(reminder.id);
    if (!reminder.notificationsEnabled) {
      await _plugin.cancel(id: id);
      return NotificationScheduleStatus.disabled;
    }

    if (!await areNotificationsEnabled()) {
      await _plugin.cancel(id: id);
      return NotificationScheduleStatus.notificationPermissionDenied;
    }

    if (!await canScheduleExactAlarms()) {
      await _plugin.cancel(id: id);
      return NotificationScheduleStatus.exactAlarmPermissionDenied;
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

    return NotificationScheduleStatus.scheduled;
  }

  static Future<void> cancelReminder(String id) async {
    await _plugin.cancel(id: _notificationId(id));
  }

  static int _notificationId(String id) {
    return id.hashCode & 0x7fffffff;
  }

  static Future<void> _configureLocalTimezone() async {
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (error) {
      debugPrint('Failed to configure local timezone: $error');
    }
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
