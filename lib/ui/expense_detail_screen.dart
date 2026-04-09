import 'package:cheapcheap/data/icon_options.dart';
import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/models/category.dart';
import 'package:cheapcheap/models/expense.dart';
import 'package:cheapcheap/services/notification_service.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/ui/widgets/icon_picker.dart';
import 'package:cheapcheap/utils/date_utils.dart';
import 'package:cheapcheap/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExpenseDetailScreen extends StatefulWidget {
  const ExpenseDetailScreen({
    super.key,
    required this.expense,
    this.initialSplitExpanded = false,
  });

  final Expense expense;
  final bool initialSplitExpanded;

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  late DateTime _selectedDate;
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _expenseReminderMessageController =
      TextEditingController();
  final TextEditingController _splitMessageController = TextEditingController();
  Category? _selectedCategory;
  String _iconId = 'wallet';
  bool _isIncome = false;
  bool _dirty = false;
  bool _expenseReminderEnabled = false;
  int _expenseReminderDaysBefore = 1;
  TimeOfDay _expenseReminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _splitExpanded = false;
  bool _splitEnabled = false;
  int _splitPayments = 2;
  SplitFrequency _splitFrequency = SplitFrequency.monthly;
  bool _splitReminderEnabled = false;
  int _splitReminderDaysBefore = 1;
  DateTime? _refundDate;
  String _refundNote = '';
  String? _localeCode;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _selectedDate = expense.date;
    _refundDate = expense.refundDate;
    _refundNote = expense.refundNote;
    _nameController.text = expense.name;
    _amountController.text = expense.amount.toStringAsFixed(2);
    _noteController.text = expense.note;
    _iconId = expense.iconId;
    _selectedCategory = null;
    _isIncome = expense.isIncome;
    _expenseReminderEnabled = expense.reminderEnabled;
    _expenseReminderDaysBefore = expense.reminderDaysBefore;
    _expenseReminderTime = TimeOfDay(
      hour: expense.reminderHour ?? 9,
      minute: expense.reminderMinute ?? 0,
    );
    _expenseReminderMessageController.text = expense.reminderMessage;
    _splitExpanded = widget.initialSplitExpanded;
    final splitPlan = expense.splitPlan;
    _splitEnabled = splitPlan != null && splitPlan.totalPayments > 1;
    if (splitPlan != null) {
      _splitPayments = splitPlan.totalPayments;
      _splitFrequency = splitPlan.frequency;
      _splitReminderEnabled = splitPlan.reminderEnabled;
      _splitReminderDaysBefore = splitPlan.reminderDaysBefore;
      _splitMessageController.text = splitPlan.reminderMessage;
    }
    _nameController.addListener(_markDirty);
    _amountController.addListener(_markDirty);
    _noteController.addListener(_markDirty);
    _expenseReminderMessageController.addListener(_markDirty);
    _splitMessageController.addListener(_markDirty);
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
    _splitMessageController.dispose();
    super.dispose();
  }

  void _markDirty() {
    final hasChanges = _hasChanges();
    if (hasChanges != _dirty) {
      setState(() => _dirty = hasChanges);
    }
  }

  void _syncDateController() {
    final locale = _localeCode;
    if (locale == null) return;
    _dateController.text = formatDateField(_selectedDate, locale);
  }

  bool _hasChanges() {
    final original = widget.expense;
    final updated = _buildExpense();
    final splitEqual = _splitEquals(original.splitPlan, updated.splitPlan);
    final reminderEqual = _expenseReminderEquals(original, updated);
    final refundEqual =
        original.refundDate == updated.refundDate &&
        original.refundNote == updated.refundNote;
    return original.date != updated.date ||
        original.name != updated.name ||
        original.amount != updated.amount ||
        original.isIncome != updated.isIncome ||
        original.iconId != updated.iconId ||
        original.categoryId != updated.categoryId ||
        original.note != updated.note ||
        !reminderEqual ||
        !splitEqual ||
        !refundEqual;
  }

  bool _expenseReminderEquals(Expense a, Expense b) {
    return a.reminderEnabled == b.reminderEnabled &&
        a.reminderDaysBefore == b.reminderDaysBefore &&
        a.reminderHour == b.reminderHour &&
        a.reminderMinute == b.reminderMinute &&
        a.reminderMessage == b.reminderMessage;
  }

  bool _splitEquals(SplitPlan? a, SplitPlan? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.totalPayments == b.totalPayments &&
        a.frequency == b.frequency &&
        a.reminderEnabled == b.reminderEnabled &&
        a.reminderDaysBefore == b.reminderDaysBefore &&
        a.reminderMessage == b.reminderMessage;
  }

  bool get _canScheduleExpenseReminder {
    return dateOnly(_selectedDate).isAfter(dateOnly(DateTime.now()));
  }

  bool get _shouldShowExpenseReminderSection {
    return _canScheduleExpenseReminder || _expenseReminderEnabled;
  }

  List<int> get _expenseReminderDayOptions {
    final daysUntilExpense = dateOnly(
      _selectedDate,
    ).difference(dateOnly(DateTime.now())).inDays;
    final maxDaysBefore = [
      daysUntilExpense.clamp(0, 14),
      _expenseReminderDaysBefore,
    ].reduce((a, b) => a > b ? a : b);
    return List.generate(maxDaysBefore + 1, (index) => index);
  }

  void _syncExpenseReminderAvailability() {
    final options = _expenseReminderDayOptions;
    if (!options.contains(_expenseReminderDaysBefore)) {
      _expenseReminderDaysBefore = options.last;
    }
  }

  Expense _buildExpense() {
    final amount = parseAmount(_amountController.text);
    final strings = AppLocalizations.of(context)!;
    final splitPlan = _splitEnabled
        ? SplitPlan(
            totalPayments: _splitPayments,
            frequency: _splitFrequency,
            reminderEnabled: _splitReminderEnabled,
            reminderDaysBefore: _splitReminderDaysBefore,
            reminderMessage: _splitMessageController.text.trim().isEmpty
                ? _defaultSplitMessage(_nameController.text.trim(), strings)
                : _splitMessageController.text.trim(),
          )
        : null;
    return widget.expense.copyWith(
      date: _selectedDate,
      name: _nameController.text.trim(),
      amount: amount,
      isIncome: _isIncome,
      iconId: _iconId,
      categoryId: _selectedCategory?.id,
      note: _noteController.text.trim(),
      reminderEnabled: _expenseReminderEnabled,
      reminderDaysBefore: _expenseReminderDaysBefore,
      reminderHour: _expenseReminderTime.hour,
      reminderMinute: _expenseReminderTime.minute,
      reminderMessage: _expenseReminderMessageController.text.trim().isEmpty
          ? _defaultExpenseReminderMessage(strings)
          : _expenseReminderMessageController.text.trim(),
      splitPlan: splitPlan,
      refundDate: _refundDate,
      refundNote: _refundNote,
    );
  }

  String _defaultSplitMessage(String name, AppLocalizations strings) {
    final label = name.isEmpty ? strings.expense : name;
    return '${strings.splitMessageDefault} $label (1/$_splitPayments)';
  }

  String _defaultExpenseReminderMessage(AppLocalizations strings) {
    if (_noteController.text.trim().isNotEmpty) {
      return _noteController.text.trim();
    }
    if (_nameController.text.trim().isNotEmpty) {
      return _nameController.text.trim();
    }
    return strings.addExpense;
  }

  Future<void> _pickIcon() async {
    final iconId = await showDialog<String>(
      context: context,
      builder: (_) => IconPickerDialog(selectedId: _iconId),
    );
    if (iconId == null) return;
    setState(() => _iconId = iconId);
    _markDirty();
  }

  Future<void> _pickExpenseReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _expenseReminderTime,
    );
    if (picked == null) return;
    setState(() => _expenseReminderTime = picked);
    _markDirty();
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
        _syncExpenseReminderAvailability();
        _syncDateController();
      });
      _markDirty();
    }
  }

  Future<void> _openRefundDialog() async {
    final strings = AppLocalizations.of(context)!;
    var date = _refundDate ?? DateTime.now();
    final noteController = TextEditingController(text: _refundNote);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.refund),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: strings.refundDate,
                            ),
                            child: Text(
                              formatDateShort(date, _localeCode ?? 'en'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: date,
                              firstDate: DateTime(2018, 1),
                              lastDate: DateTime(2100, 12),
                            );
                            if (picked != null) {
                              setState(() => date = picked);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: InputDecoration(
                        labelText: strings.refundNote,
                      ),
                      maxLines: 2,
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
    if (result == true) {
      setState(() {
        _refundDate = date;
        _refundNote = noteController.text.trim();
      });
      _markDirty();
    }
  }

  Future<void> _confirmDelete() async {
    final strings = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.confirmDelete),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.no),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.yes),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) {
      await context.read<AppState>().removeExpense(widget.expense.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  Future<void> _save() async {
    var updated = _buildExpense();
    String? setupMessage;
    if (updated.reminderEnabled && updated.reminderDateTime != null) {
      final reminderSetup = await _prepareReminderNotifications(
        context,
        notificationsEnabled: true,
      );
      setupMessage = reminderSetup.feedbackMessage;
      updated = updated.copyWith(
        reminderEnabled: reminderSetup.notificationsEnabled,
      );
    }

    if (!mounted) return;
    final scheduleStatus = await context.read<AppState>().updateExpense(
      updated,
    );
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
    setState(() => _dirty = false);
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
    final locale = state.locale.toString();
    final currency = state.settings.currency;
    _selectedCategory ??= state.getCategory(widget.expense.categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.details),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'split') {
                setState(() => _splitExpanded = true);
              }
              if (value == 'refund') {
                _openRefundDialog();
              }
              if (value == 'delete') {
                _confirmDelete();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'split', child: Text(strings.split)),
              PopupMenuItem(value: 'refund', child: Text(strings.refund)),
              PopupMenuItem(value: 'delete', child: Text(strings.delete)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_refundDate != null)
            Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.refund,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${strings.date}: ${formatDateShort(_refundDate!, locale)}',
                    ),
                    if (_refundNote.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('${strings.note}: $_refundNote'),
                      ),
                  ],
                ),
              ),
            ),
          if (_refundDate != null) const SizedBox(height: 16),
          TextField(
            controller: _dateController,
            readOnly: true,
            onTap: _pickDate,
            decoration: InputDecoration(
              labelText: strings.date,
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _pickDate,
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
              setState(() => _selectedCategory = value);
              _markDirty();
            },
            decoration: InputDecoration(labelText: strings.category),
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
              setState(() => _isIncome = value);
              _markDirty();
            },
            title: Text(_isIncome ? strings.income : strings.expense),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(labelText: strings.note),
            maxLines: 3,
          ),
          if (_shouldShowExpenseReminderSection) ...[
            const SizedBox(height: 12),
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
                        _markDirty();
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
                                'detail-expense-days-$_expenseReminderDaysBefore-${_selectedDate.millisecondsSinceEpoch}',
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
                                _markDirty();
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
          ],
          const SizedBox(height: 16),
          ExpansionTile(
            initiallyExpanded: _splitExpanded,
            onExpansionChanged: (expanded) {
              setState(() => _splitExpanded = expanded);
            },
            title: Text(strings.split),
            children: [
              SwitchListTile(
                value: _splitEnabled,
                onChanged: (value) {
                  setState(() => _splitEnabled = value);
                  _markDirty();
                },
                title: Text(strings.splitEnabled),
              ),
              if (_splitEnabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                          _markDirty();
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
                          _markDirty();
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: _splitReminderEnabled,
                        onChanged: (value) {
                          setState(() => _splitReminderEnabled = value);
                          _markDirty();
                        },
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
                                _markDirty();
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
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${strings.splitSchedule}: 1/$_splitPayments',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _buildSplitAmounts()
                            .map(
                              (value) => Chip(
                                label: Text(
                                  formatCurrency(
                                    value * (_isIncome ? 1 : -1),
                                    currency,
                                    locale,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: _dirty
          ? FloatingActionButton(
              onPressed: _save,
              child: const Icon(Icons.save),
            )
          : null,
    );
  }

  List<double> _buildSplitAmounts() {
    final parsed = parseAmount(_amountController.text);
    if (!_splitEnabled || _splitPayments <= 1) {
      return [parsed];
    }
    final tempExpense = widget.expense.copyWith(
      amount: parsed,
      splitPlan: SplitPlan(
        totalPayments: _splitPayments,
        frequency: _splitFrequency,
        reminderEnabled: _splitReminderEnabled,
        reminderDaysBefore: _splitReminderDaysBefore,
        reminderMessage: _splitMessageController.text,
      ),
    );
    return tempExpense.splitAmounts();
  }
}
