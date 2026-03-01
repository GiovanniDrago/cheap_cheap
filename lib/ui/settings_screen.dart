import 'package:cheapcheap/l10n/app_localizations.dart';
import 'package:cheapcheap/models/reminder.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final themeLabels = [
      'Mandy Red',
      'Deep Blue',
      'Mango',
      'Hippie Blue',
      'Wasabi',
    ];

    return Scaffold(
      appBar: AppBar(title: Text(strings.text('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            value: state.settings.themeIndex,
            decoration: InputDecoration(labelText: strings.text('theme')),
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
            value: state.settings.localeCode,
            decoration: InputDecoration(labelText: strings.text('language')),
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'it', child: Text('Italiano')),
            ],
            onChanged: (value) {
              if (value == null) return;
              state.updateLocale(value);
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: state.settings.currency,
            decoration: InputDecoration(labelText: strings.text('currency')),
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
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            value: state.settings.rewardImagesPerQuest,
            decoration: InputDecoration(
              labelText: strings.text('reward_images'),
            ),
            items: List.generate(5, (index) => index + 1)
                .map(
                  (count) => DropdownMenuItem(
                    value: count,
                    child: Text(count.toString()),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              state.updateRewardImagesPerQuest(value);
            },
          ),
          const SizedBox(height: 24),
          Text(
            strings.text('reminders'),
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
                title: Text(reminder.message),
                subtitle: Text(
                  '${_frequencyLabel(strings, reminder.frequency)} · ${_formatTime(reminder.hour, reminder.minute)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => state.removeReminder(reminder.id),
                  tooltip: strings.text('delete'),
                ),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _openAddReminder(context),
            icon: const Icon(Icons.add),
            label: Text(strings.text('add_reminder')),
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
        return strings.text('reminder_daily');
      case ReminderFrequency.weekly:
        return strings.text('reminder_weekly');
    }
  }

  String _formatTime(int hour, int minute) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _openAddReminder(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final messageController = TextEditingController(
      text: strings.text('add_expense'),
    );
    var frequency = ReminderFrequency.daily;
    var time = const TimeOfDay(hour: 9, minute: 0);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.text('add_reminder')),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<ReminderFrequency>(
                    value: frequency,
                    decoration: InputDecoration(
                      labelText: strings.text('reminder_frequency'),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: ReminderFrequency.daily,
                        child: Text(strings.text('reminder_daily')),
                      ),
                      DropdownMenuItem(
                        value: ReminderFrequency.weekly,
                        child: Text(strings.text('reminder_weekly')),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => frequency = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: strings.text('reminder_time'),
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
                      labelText: strings.text('reminder_message'),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.text('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.text('save')),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    final reminder = Reminder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      frequency: frequency,
      hour: time.hour,
      minute: time.minute,
      message: messageController.text.trim().isEmpty
          ? strings.text('add_expense')
          : messageController.text.trim(),
    );
    if (!context.mounted) return;
    context.read<AppState>().addReminder(reminder);
  }
}
