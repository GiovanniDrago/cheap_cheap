import 'package:cheapcheap/data/icon_options.dart';
import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/models/category.dart';
import 'package:cheapcheap/models/expense.dart';
import 'package:cheapcheap/models/recurrence.dart';
import 'package:cheapcheap/navigation/app_router.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/ui/widgets/icon_picker.dart';
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
      _syncDateController();
    });
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

  void _save() {
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
    final expense = Expense(
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
    );
    context.read<AppState>().addExpense(expense);
    Navigator.of(context).pop();
  }

  String _defaultSplitMessage(String name) {
    final strings = AppLocalizations.of(context)!;
    final label = name.isEmpty ? strings.expense : name;
    return '${strings.splitMessageDefault} $label (1/$_splitPayments)';
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
