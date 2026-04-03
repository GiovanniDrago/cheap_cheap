import 'dart:io';

import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/models/expense.dart';
import 'package:cheapcheap/models/recurrence.dart';
import 'package:cheapcheap/models/reminder.dart';
import 'package:cheapcheap/services/notification_service.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final themeLabels = _themeLabels(strings);

    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            key: ValueKey('theme-${state.settings.themeIndex}'),
            initialValue: state.settings.themeIndex,
            decoration: InputDecoration(labelText: strings.theme),
            items: List.generate(
              themeLabels.length,
              (index) => DropdownMenuItem(
                value: index,
                child: Text(themeLabels[index]),
              ),
            ),
            onChanged: (value) {
              if (value == null) return;
              state.updateThemeIndex(value);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey('theme-mode-${state.settings.themeMode}'),
            initialValue: state.settings.themeMode,
            decoration: InputDecoration(labelText: strings.themeMode),
            items: [
              DropdownMenuItem(value: 'light', child: Text(strings.themeLight)),
              DropdownMenuItem(value: 'dark', child: Text(strings.themeDark)),
              DropdownMenuItem(
                value: 'system',
                child: Text(strings.themeSystem),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              state.updateThemeMode(value);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey('locale-${state.settings.localeCode}'),
            initialValue: state.settings.localeCode,
            decoration: InputDecoration(labelText: strings.language),
            items: [
              DropdownMenuItem(
                value: 'en',
                child: Text(strings.languageEnglish),
              ),
              DropdownMenuItem(
                value: 'it',
                child: Text(strings.languageItalian),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              state.updateLocale(value);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey('currency-${state.settings.currency}'),
            initialValue: state.settings.currency,
            decoration: InputDecoration(labelText: strings.currency),
            items: const [
              DropdownMenuItem(value: 'EUR', child: Text('EUR')),
              DropdownMenuItem(value: 'USD', child: Text('USD')),
              DropdownMenuItem(value: 'GBP', child: Text('GBP')),
              DropdownMenuItem(value: 'JPY', child: Text('JPY')),
            ],
            onChanged: (value) {
              if (value == null) return;
              state.updateCurrency(value);
            },
          ),
          const SizedBox(height: 24),
          Text(strings.data, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _exportCsv(context),
            icon: const Icon(Icons.download),
            label: Text(strings.exportCsv),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _importCsv(context),
            icon: const Icon(Icons.upload_file),
            label: Text(strings.importCsv),
          ),
          const SizedBox(height: 24),
          Text(
            strings.reminders,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          ...state.settings.reminders.map(
            (reminder) => Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ListTile(
                onTap: () => _openReminderDialog(context, reminder: reminder),
                title: Text(reminder.message),
                subtitle: Text(
                  '${_frequencyLabel(strings, reminder.frequency)} · ${_formatTime(reminder.hour, reminder.minute)}${_weekdayLabel(reminder, localeCode: state.settings.localeCode)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await state.removeReminder(reminder.id);
                  },
                  tooltip: strings.delete,
                ),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _openReminderDialog(context),
            icon: const Icon(Icons.add),
            label: Text(strings.addReminder),
          ),
        ],
      ),
    );
  }

  String _frequencyLabel(
    AppLocalizations strings,
    ReminderFrequency frequency,
  ) {
    switch (frequency) {
      case ReminderFrequency.daily:
        return strings.reminderDaily;
      case ReminderFrequency.weekly:
        return strings.reminderWeekly;
    }
  }

  String _formatTime(int hour, int minute) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _weekdayLabel(Reminder reminder, {required String localeCode}) {
    if (reminder.frequency != ReminderFrequency.weekly ||
        reminder.weekday == null) {
      return '';
    }
    final weekday = reminder.weekday ?? DateTime.now().weekday;
    final date = DateTime(2023, 1, weekday + 1);
    return ' · ${DateFormat('EEEE', localeCode).format(date)}';
  }

  Future<void> _openReminderDialog(
    BuildContext context, {
    Reminder? reminder,
  }) async {
    final strings = AppLocalizations.of(context)!;
    final messageController = TextEditingController(
      text: reminder?.message ?? strings.addExpense,
    );
    var frequency = reminder?.frequency ?? ReminderFrequency.daily;
    var time = TimeOfDay(
      hour: reminder?.hour ?? 9,
      minute: reminder?.minute ?? 0,
    );
    var notificationsEnabled = reminder?.notificationsEnabled ?? false;
    var weekday = reminder?.weekday ?? DateTime.now().weekday;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            reminder == null ? strings.addReminder : strings.editReminder,
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<ReminderFrequency>(
                      key: ValueKey('reminder-frequency-$frequency'),
                      initialValue: frequency,
                      decoration: InputDecoration(
                        labelText: strings.reminderFrequency,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: ReminderFrequency.daily,
                          child: Text(strings.reminderDaily),
                        ),
                        DropdownMenuItem(
                          value: ReminderFrequency.weekly,
                          child: Text(strings.reminderWeekly),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => frequency = value);
                      },
                    ),
                    if (frequency == ReminderFrequency.weekly)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: DropdownButtonFormField<int>(
                          key: ValueKey('reminder-weekday-$weekday'),
                          initialValue: weekday,
                          decoration: InputDecoration(
                            labelText: strings.weekday,
                          ),
                          items: List.generate(7, (index) => index + 1)
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    DateFormat(
                                      'EEEE',
                                      Localizations.localeOf(
                                        context,
                                      ).toString(),
                                    ).format(DateTime(2023, 1, value + 1)),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => weekday = value);
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: strings.reminderTime,
                            ),
                            child: Text(_formatTime(time.hour, time.minute)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: time,
                            );
                            if (picked != null) {
                              setState(() => time = picked);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        labelText: strings.reminderMessage,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: notificationsEnabled,
                      onChanged: (value) =>
                          setState(() => notificationsEnabled = value),
                      title: Text(strings.notificationToggle),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.save),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }
    if (!context.mounted) return;

    final reminderSetup = await _prepareReminderNotifications(
      context,
      notificationsEnabled: notificationsEnabled,
    );
    if (!context.mounted) return;

    final nextReminder = Reminder(
      id: reminder?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      frequency: frequency,
      hour: time.hour,
      minute: time.minute,
      message: messageController.text.trim().isEmpty
          ? strings.addExpense
          : messageController.text.trim(),
      notificationsEnabled: reminderSetup.notificationsEnabled,
      weekday: frequency == ReminderFrequency.weekly ? weekday : null,
    );
    final state = context.read<AppState>();
    final scheduleStatus = reminder == null
        ? await state.addReminder(nextReminder)
        : await state.updateReminder(nextReminder);
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final feedbackMessage = _notificationFeedbackMessage(
      context,
      setupMessage: reminderSetup.feedbackMessage,
      scheduleStatus: scheduleStatus,
    );
    if (feedbackMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(feedbackMessage)));
    }
  }

  Future<({bool notificationsEnabled, String? feedbackMessage})>
  _prepareReminderNotifications(
    BuildContext context, {
    required bool notificationsEnabled,
  }) async {
    if (!notificationsEnabled) {
      return (notificationsEnabled: false, feedbackMessage: null);
    }

    final strings = AppLocalizations.of(context)!;
    var notificationsAllowed =
        await NotificationService.areNotificationsEnabled();
    if (!notificationsAllowed) {
      if (!context.mounted) {
        return (notificationsEnabled: false, feedbackMessage: null);
      }
      final shouldRequestPermission = await _showPermissionPrompt(
        context,
        title: strings.notificationPermissionTitle,
        message: strings.notificationPermissionMessage,
      );
      if (shouldRequestPermission != true) {
        return (
          notificationsEnabled: false,
          feedbackMessage: strings.reminderSavedWithoutNotifications,
        );
      }

      notificationsAllowed =
          await NotificationService.requestNotificationPermission();
      if (!notificationsAllowed) {
        return (
          notificationsEnabled: false,
          feedbackMessage: strings.reminderSavedWithoutNotifications,
        );
      }
    }

    var exactAlarmAllowed = await NotificationService.canScheduleExactAlarms();
    if (!exactAlarmAllowed) {
      if (!context.mounted) {
        return (notificationsEnabled: false, feedbackMessage: null);
      }
      final shouldOpenSettings = await _showPermissionPrompt(
        context,
        title: strings.exactAlarmPermissionTitle,
        message: strings.exactAlarmPermissionMessage,
      );
      if (shouldOpenSettings != true) {
        return (
          notificationsEnabled: false,
          feedbackMessage: strings.reminderSavedWithoutExactAlarm,
        );
      }

      exactAlarmAllowed =
          await NotificationService.requestExactAlarmPermission();
      if (!exactAlarmAllowed) {
        return (
          notificationsEnabled: false,
          feedbackMessage: strings.reminderSavedWithoutExactAlarm,
        );
      }
    }

    return (notificationsEnabled: true, feedbackMessage: null);
  }

  Future<bool?> _showPermissionPrompt(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    final strings = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.ok),
            ),
          ],
        );
      },
    );
  }

  String? _notificationFeedbackMessage(
    BuildContext context, {
    required String? setupMessage,
    required NotificationScheduleStatus scheduleStatus,
  }) {
    if (setupMessage != null) {
      return setupMessage;
    }

    final strings = AppLocalizations.of(context)!;
    switch (scheduleStatus) {
      case NotificationScheduleStatus.scheduled:
      case NotificationScheduleStatus.disabled:
        return null;
      case NotificationScheduleStatus.notificationPermissionDenied:
        return strings.reminderSavedWithoutNotifications;
      case NotificationScheduleStatus.exactAlarmPermissionDenied:
        return strings.reminderSavedWithoutExactAlarm;
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final strings = AppLocalizations.of(context)!;
    final csv = _buildCsv(state);
    final directory = await _getExportDirectory();
    final file = File('${directory.path}/cheapcheap_export.csv');
    await file.writeAsString(csv);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('${strings.csvExported} ${file.path}')),
    );
  }

  Future<void> _importCsv(BuildContext context) async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final strings = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.single.path == null) {
      return;
    }
    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    final imported = _parseCsv(content, state);
    state.importExpenses(imported);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('${strings.csvImported}: ${imported.length}')),
    );
  }

  String _buildCsv(AppState state) {
    final rows = <List<String>>[
      [
        'id',
        'date',
        'name',
        'amount',
        'isIncome',
        'categoryId',
        'iconId',
        'note',
        'recurrenceType',
        'recurrenceDay',
        'recurrenceMonth',
        'reminderEnabled',
        'reminderDaysBefore',
        'reminderMessage',
        'splitPayments',
        'splitFrequency',
        'splitReminderEnabled',
        'splitReminderDaysBefore',
        'splitReminderMessage',
        'refundDate',
        'refundNote',
      ],
    ];
    for (final expense in state.expenses) {
      rows.add([
        expense.id,
        expense.date.toIso8601String(),
        expense.name,
        expense.amount.toString(),
        expense.isIncome.toString(),
        expense.categoryId ?? '',
        expense.iconId,
        expense.note,
        expense.recurrence?.type.name ?? '',
        expense.recurrence?.dayOfMonth?.toString() ?? '',
        expense.recurrence?.monthOfYear?.toString() ?? '',
        expense.recurrence?.reminderEnabled.toString() ?? '',
        expense.recurrence?.reminderDaysBefore.toString() ?? '',
        expense.recurrence?.reminderMessage ?? '',
        expense.splitPlan?.totalPayments.toString() ?? '',
        expense.splitPlan?.frequency.name ?? '',
        expense.splitPlan?.reminderEnabled.toString() ?? '',
        expense.splitPlan?.reminderDaysBefore.toString() ?? '',
        expense.splitPlan?.reminderMessage ?? '',
        expense.refundDate?.toIso8601String() ?? '',
        expense.refundNote,
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }

  List<Expense> _parseCsv(String content, AppState state) {
    final rows = const CsvToListConverter().convert(content);
    final List<Expense> imported = [];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 5) continue;
      final date = DateTime.tryParse(row[1].toString()) ?? DateTime.now();
      final amount = double.tryParse(row[3].toString()) ?? 0;
      imported.add(
        Expense(
          id: row[0].toString(),
          date: date,
          name: row[2].toString(),
          amount: amount,
          isIncome: row[4].toString() == 'true',
          categoryId: row[5].toString().isEmpty ? null : row[5].toString(),
          iconId: row[6].toString().isEmpty ? 'wallet' : row[6].toString(),
          note: row[7].toString(),
          recurrence: _parseRecurrence(row),
          splitPlan: _parseSplitPlan(row),
          refundDate: row.length > 19 && row[19].toString().isNotEmpty
              ? DateTime.tryParse(row[19].toString())
              : null,
          refundNote: row.length > 20 ? row[20].toString() : '',
        ),
      );
    }
    return imported;
  }

  Recurrence? _parseRecurrence(List<dynamic> row) {
    if (row.length < 9) return null;
    final typeRaw = row[8].toString();
    if (typeRaw.isEmpty) return null;
    final type = RecurrenceType.values.firstWhere(
      (item) => item.name == typeRaw,
      orElse: () => RecurrenceType.none,
    );
    if (type == RecurrenceType.none) return null;
    return Recurrence(
      type: type,
      dayOfMonth: int.tryParse(row[9].toString()),
      monthOfYear: int.tryParse(row[10].toString()),
      reminderEnabled: row[11].toString() == 'true',
      reminderDaysBefore: int.tryParse(row[12].toString()) ?? 1,
      reminderMessage: row.length > 13 ? row[13].toString() : '',
    );
  }

  SplitPlan? _parseSplitPlan(List<dynamic> row) {
    if (row.length < 16) return null;
    final totalPayments = int.tryParse(row[14].toString()) ?? 1;
    if (totalPayments <= 1) return null;
    final frequencyRaw = row[15].toString();
    final frequency = SplitFrequency.values.firstWhere(
      (value) => value.name == frequencyRaw,
      orElse: () => SplitFrequency.monthly,
    );
    return SplitPlan(
      totalPayments: totalPayments,
      frequency: frequency,
      reminderEnabled: row.length > 16 && row[16].toString() == 'true',
      reminderDaysBefore: row.length > 17
          ? int.tryParse(row[17].toString()) ?? 1
          : 1,
      reminderMessage: row.length > 18 ? row[18].toString() : '',
    );
  }

  Future<Directory> _getExportDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  List<String> _themeLabels(AppLocalizations strings) {
    return [
      strings.themeMandyRed,
      strings.themeDeepBlue,
      strings.themeMango,
      strings.themeHippieBlue,
      strings.themeWasabi,
    ];
  }
}
