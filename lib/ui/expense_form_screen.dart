import 'package:cheapcheap/data/icon_options.dart';
import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/models/category.dart';
import 'package:cheapcheap/models/expense.dart';
import 'package:cheapcheap/models/recurrence.dart';
import 'package:cheapcheap/navigation/app_router.dart';
import 'package:cheapcheap/services/notification_service.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/ui/widgets/icon_picker.dart';
import 'package:cheapcheap/utils/date_utils.dart';
import 'package:cheapcheap/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, required this.initialMonth});

  final DateTime initialMonth;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  late DateTime _selectedDate;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _expenseReminderMessageController =
      TextEditingController();
  final TextEditingController _reminderMessageController =
      TextEditingController();
  final TextEditingController _splitMessageController = TextEditingController();
  Category? _selectedCategory;
  String _iconId = 'wallet';
  bool _isIncome = false;
  bool _overrideIcon = false;
  bool _overrideType = false;
  bool _recurrenceExpanded = false;
  RecurrenceType _recurrenceType = RecurrenceType.none;
  int _recurrenceDay = DateTime.now().day;
  int _recurrenceMonth = DateTime.now().month;
  bool _expenseReminderEnabled = false;
  int _expenseReminderDaysBefore = 1;
  TimeOfDay _expenseReminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _reminderEnabled = false;
  int _reminderDaysBefore = 1;
  bool _splitExpanded = false;
  bool _splitEnabled = false;
  int _splitPayments = 2;
  SplitFrequency _splitFrequency = SplitFrequency.monthly;
  bool _splitReminderEnabled = false;
  int _splitReminderDaysBefore = 1;
  String? _localeCode;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final isDifferentMonth =
        now.year != widget.initialMonth.year ||
        now.month != widget.initialMonth.month;
    _selectedDate = isDifferentMonth
        ? DateTime(widget.initialMonth.year, widget.initialMonth.month, 1)
        : DateTime(now.year, now.month, now.day);
    _recurrenceDay = _selectedDate.day;
    _recurrenceMonth = _selectedDate.month;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextLocaleCode = Localizations.localeOf(context).toString();
    if (_localeCode == nextLocaleCode) return;
    _localeCode = nextLocaleCode;
    _syncDateController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _expenseReminderMessageController.dispose();
    _reminderMessageController.dispose();
    _splitMessageController.dispose();
    super.dispose();
  }

  void _syncDateController() {
    final locale = _localeCode;
    if (locale == null) return;
    _dateController.text = formatDateField(_selectedDate, locale);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2018, 1),
      lastDate: DateTime(2100, 12),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _recurrenceDay = picked.day;
        _recurrenceMonth = picked.month;
        _syncExpenseReminderAvailability();
        _syncDateController();
      });
    }
  }

  void _resetDate() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
      _recurrenceDay = _selectedDate.day;
      _recurrenceMonth = _selectedDate.month;
      _syncExpenseReminderAvailability();
      _syncDateController();
    });
  }

  bool get _canScheduleExpenseReminder {
    return dateOnly(_selectedDate).isAfter(dateOnly(DateTime.now()));
  }

  List<int> get _expenseReminderDayOptions {
    final daysUntilExpense = dateOnly(
      _selectedDate,
    ).difference(dateOnly(DateTime.now())).inDays;
    final maxDaysBefore = daysUntilExpense.clamp(0, 14);
    return List.generate(maxDaysBefore + 1, (index) => index);
  }

  void _syncExpenseReminderAvailability() {
    if (!_canScheduleExpenseReminder) {
      _expenseReminderEnabled = false;
      _expenseReminderDaysBefore = 1;
      return;
    }

    final options = _expenseReminderDayOptions;
    if (!options.contains(_expenseReminderDaysBefore)) {
      _expenseReminderDaysBefore = options.last;
    }
  }

  Future<void> _pickExpenseReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _expenseReminderTime,
    );
    if (picked == null) return;
    setState(() => _expenseReminderTime = picked);
  }

  void _applyCategoryDefaults(Category? category) {
    if (category == null) return;
    if (!_overrideIcon) {
      _iconId = category.iconId;
    }
    if (!_overrideType) {
      _isIncome = category.isIncomeDefault;
    }
  }

  Future<void> _pickIcon() async {
    final iconId = await showDialog<String>(
      context: context,
      builder: (_) => IconPickerDialog(selectedId: _iconId),
    );
    if (iconId != null) {
      setState(() {
        _iconId = iconId;
        _overrideIcon = true;
      });
    }
  }

  Future<void> _openCategoryCreation() async {
    final created = await AppRouter.showCreateCategory(context);
    if (created != null) {
      setState(() {
        _selectedCategory = created;
        _applyCategoryDefaults(created);
      });
    }
  }

  Future<void> _save() async {
    final amount = parseAmount(_amountController.text);
    final splitPlan = _splitEnabled
        ? SplitPlan(
            totalPayments: _splitPayments,
            frequency: _splitFrequency,
            reminderEnabled: _splitReminderEnabled,
            reminderDaysBefore: _splitReminderDaysBefore,
            reminderMessage: _splitMessageController.text.trim().isEmpty
                ? _defaultSplitMessage(_nameController.text.trim())
                : _splitMessageController.text.trim(),
          )
        : null;
    var expense = Expense(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: _selectedDate,
      name: _nameController.text.trim(),
      amount: amount,
      isIncome: _isIncome,
      iconId: _iconId,
      categoryId: _selectedCategory?.id,
      note: _noteController.text.trim(),
      recurrence: _recurrenceType == RecurrenceType.none
          ? null
          : Recurrence(
              type: _recurrenceType,
              dayOfMonth: _recurrenceType == RecurrenceType.monthly
                  ? _recurrenceDay
                  : null,
              monthOfYear: _recurrenceType == RecurrenceType.yearly
                  ? _recurrenceMonth
                  : null,
              reminderEnabled: _reminderEnabled,
              reminderDaysBefore: _reminderDaysBefore,
              reminderMessage: _reminderMessageController.text.trim(),
            ),
      splitPlan: splitPlan,
      reminderEnabled: _expenseReminderEnabled && _canScheduleExpenseReminder,
      reminderDaysBefore: _expenseReminderDaysBefore,
      reminderHour: _expenseReminderTime.hour,
      reminderMinute: _expenseReminderTime.minute,
      reminderMessage: _expenseReminderMessageController.text.trim().isEmpty
          ? _defaultExpenseReminderMessage()
          : _expenseReminderMessageController.text.trim(),
    );

    String? setupMessage;
    if (expense.reminderEnabled) {
      final reminderSetup = await _prepareReminderNotifications(
        context,
        notificationsEnabled: true,
      );
      setupMessage = reminderSetup.feedbackMessage;
      expense = expense.copyWith(
        reminderEnabled: reminderSetup.notificationsEnabled,
      );
    }

    if (!mounted) return;
    final scheduleStatus = await context.read<AppState>().addExpense(expense);
    if (!mounted) return;

    final feedbackMessage = _notificationFeedbackMessage(
      context,
      setupMessage: setupMessage,
      scheduleStatus: scheduleStatus,
    );
    if (feedbackMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(feedbackMessage)));
    }
    Navigator.of(context).pop();
  }

  String _defaultSplitMessage(String name) {
    final strings = AppLocalizations.of(context)!;
    final label = name.isEmpty ? strings.expense : name;
    return '${strings.splitMessageDefault} $label (1/$_splitPayments)';
  }

  String _defaultExpenseReminderMessage() {
    final strings = AppLocalizations.of(context)!;
    if (_noteController.text.trim().isNotEmpty) {
      return _noteController.text.trim();
    }
    if (_nameController.text.trim().isNotEmpty) {
      return _nameController.text.trim();
    }
    return strings.addExpense;
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
    required NotificationScheduleStatus? scheduleStatus,
  }) {
    if (setupMessage != null) {
      return setupMessage;
    }
    if (scheduleStatus == null) {
      return null;
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

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final categories = state.categories;

    return Scaffold(
      appBar: AppBar(title: Text(strings.addExpense)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _dateController,
            readOnly: true,
            onTap: _pickDate,
            decoration: InputDecoration(
              labelText: strings.date,
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                  ),
                  IconButton(
                    onPressed: _resetDate,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Category?>(
            key: ValueKey(_selectedCategory?.id),
            initialValue: _selectedCategory,
            items: [
              DropdownMenuItem(value: null, child: Text(strings.noCategory)),
              for (final category in categories)
                DropdownMenuItem(value: category, child: Text(category.name)),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
                _applyCategoryDefaults(value);
              });
            },
            decoration: InputDecoration(
              labelText: strings.category,
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _openCategoryCreation,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: strings.name),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: _pickIcon,
                borderRadius: BorderRadius.circular(24),
                child: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  child: Icon(
                    iconOptionById(_iconId).icon,
                    color: iconOptionById(_iconId).color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            decoration: InputDecoration(labelText: strings.amount),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _isIncome,
            onChanged: (value) {
              setState(() {
                _isIncome = value;
                _overrideType = true;
              });
            },
            title: Text(_isIncome ? strings.income : strings.expense),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(labelText: strings.note),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          if (_canScheduleExpenseReminder) ...[
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _expenseReminderEnabled,
                      onChanged: (value) {
                        setState(() => _expenseReminderEnabled = value);
                      },
                      title: Text(strings.reminder),
                    ),
                    if (_expenseReminderEnabled)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(strings.reminderTime),
                              subtitle: Text(
                                _expenseReminderTime.format(context),
                              ),
                              trailing: const Icon(Icons.schedule),
                              onTap: _pickExpenseReminderTime,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int>(
                              key: ValueKey(
                                'expense-days-$_expenseReminderDaysBefore-${_selectedDate.millisecondsSinceEpoch}',
                              ),
                              initialValue: _expenseReminderDaysBefore,
                              decoration: InputDecoration(
                                labelText: strings.daysBefore,
                              ),
                              items: _expenseReminderDayOptions
                                  .map(
                                    (day) => DropdownMenuItem(
                                      value: day,
                                      child: Text(day.toString()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(
                                  () => _expenseReminderDaysBefore = value,
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _expenseReminderMessageController,
                              decoration: InputDecoration(
                                labelText: strings.reminderMessage,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          ExpansionTile(
            initiallyExpanded: _recurrenceExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _recurrenceExpanded = expanded;
                if (expanded && _recurrenceType == RecurrenceType.none) {
                  _recurrenceType = RecurrenceType.monthly;
                  _recurrenceDay = _selectedDate.day;
                }
              });
            },
            title: Text(strings.recurrence),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: DropdownButtonFormField<RecurrenceType>(
                  key: ValueKey(_recurrenceType),
                  initialValue: _recurrenceType,
                  items: [
                    DropdownMenuItem(
                      value: RecurrenceType.none,
                      child: Text(strings.recurrenceNone),
                    ),
                    DropdownMenuItem(
                      value: RecurrenceType.daily,
                      child: Text(strings.recurrenceDaily),
                    ),
                    DropdownMenuItem(
                      value: RecurrenceType.monthly,
                      child: Text(strings.recurrenceMonthly),
                    ),
                    DropdownMenuItem(
                      value: RecurrenceType.yearly,
                      child: Text(strings.recurrenceYearly),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _recurrenceType = value;
                    });
                  },
                ),
              ),
              if (_recurrenceType == RecurrenceType.monthly)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('recurrence-day-$_recurrenceDay'),
                    initialValue: _recurrenceDay,
                    decoration: InputDecoration(labelText: strings.dayOfMonth),
                    items: List.generate(31, (index) => index + 1)
                        .map(
                          (day) => DropdownMenuItem(
                            value: day,
                            child: Text(day.toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _recurrenceDay = value);
                    },
                  ),
                ),
              if (_recurrenceType == RecurrenceType.yearly)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          key: ValueKey('recurrence-month-$_recurrenceMonth'),
                          initialValue: _recurrenceMonth,
                          decoration: InputDecoration(labelText: strings.month),
                          items: List.generate(12, (index) => index + 1)
                              .map(
                                (month) => DropdownMenuItem(
                                  value: month,
                                  child: Text(month.toString()),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _recurrenceMonth = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          key: ValueKey('recurrence-day-$_recurrenceDay'),
                          initialValue: _recurrenceDay,
                          decoration: InputDecoration(labelText: strings.day),
                          items: List.generate(31, (index) => index + 1)
                              .map(
                                (day) => DropdownMenuItem(
                                  value: day,
                                  child: Text(day.toString()),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _recurrenceDay = value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              SwitchListTile(
                value: _reminderEnabled,
                onChanged: (value) => setState(() => _reminderEnabled = value),
                title: Text(strings.reminder),
              ),
              if (_reminderEnabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        key: ValueKey('reminder-days-$_reminderDaysBefore'),
                        initialValue: _reminderDaysBefore,
                        decoration: InputDecoration(
                          labelText: strings.daysBefore,
                        ),
                        items: List.generate(14, (index) => index + 1)
                            .map(
                              (day) => DropdownMenuItem(
                                value: day,
                                child: Text(day.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _reminderDaysBefore = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _reminderMessageController,
                        decoration: InputDecoration(labelText: strings.message),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            initiallyExpanded: _splitExpanded,
            onExpansionChanged: (expanded) {
              setState(() => _splitExpanded = expanded);
            },
            title: Text(strings.split),
            children: [
              SwitchListTile(
                value: _splitEnabled,
                onChanged: (value) => setState(() => _splitEnabled = value),
                title: Text(strings.splitEnabled),
              ),
              if (_splitEnabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        key: ValueKey('split-payments-$_splitPayments'),
                        initialValue: _splitPayments,
                        decoration: InputDecoration(
                          labelText: strings.splitPayments,
                        ),
                        items: List.generate(24, (index) => index + 2)
                            .map(
                              (count) => DropdownMenuItem(
                                value: count,
                                child: Text(count.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _splitPayments = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<SplitFrequency>(
                        key: ValueKey(_splitFrequency),
                        initialValue: _splitFrequency,
                        decoration: InputDecoration(
                          labelText: strings.splitFrequency,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: SplitFrequency.weekly,
                            child: Text(strings.reminderWeekly),
                          ),
                          DropdownMenuItem(
                            value: SplitFrequency.monthly,
                            child: Text(strings.recurrenceMonthly),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _splitFrequency = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: _splitReminderEnabled,
                        onChanged: (value) =>
                            setState(() => _splitReminderEnabled = value),
                        title: Text(strings.reminder),
                      ),
                      if (_splitReminderEnabled)
                        Column(
                          children: [
                            DropdownButtonFormField<int>(
                              key: ValueKey(
                                'split-days-$_splitReminderDaysBefore',
                              ),
                              initialValue: _splitReminderDaysBefore,
                              decoration: InputDecoration(
                                labelText: strings.daysBefore,
                              ),
                              items: List.generate(14, (index) => index + 1)
                                  .map(
                                    (day) => DropdownMenuItem(
                                      value: day,
                                      child: Text(day.toString()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(
                                  () => _splitReminderDaysBefore = value,
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _splitMessageController,
                              decoration: InputDecoration(
                                labelText: strings.message,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _save, child: Text(strings.save)),
        ],
      ),
    );
  }
}
