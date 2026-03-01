import 'package:cheapcheap/data/icon_options.dart';
import 'package:cheapcheap/l10n/app_localizations.dart';
import 'package:cheapcheap/models/category.dart';
import 'package:cheapcheap/models/expense.dart';
import 'package:cheapcheap/models/recurrence.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/ui/category_form_screen.dart';
import 'package:cheapcheap/ui/widgets/icon_picker.dart';
import 'package:cheapcheap/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    _syncDateController();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _reminderMessageController.dispose();
    super.dispose();
  }

  void _syncDateController() {
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
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
    final created = await Navigator.of(context).push<Category>(
      MaterialPageRoute(builder: (_) => const CategoryFormScreen()),
    );
    if (created != null) {
      setState(() {
        _selectedCategory = created;
        _applyCategoryDefaults(created);
      });
    }
  }

  void _save() {
    final parsedDate = DateTime.tryParse(_dateController.text.trim());
    if (parsedDate != null) {
      _selectedDate = parsedDate;
    }
    final amount = parseAmount(_amountController.text);
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
    );
    context.read<AppState>().addExpense(expense);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final categories = state.categories;

    return Scaffold(
      appBar: AppBar(title: Text(strings.text('add_expense'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _dateController,
            decoration: InputDecoration(
              labelText: strings.text('date'),
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
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Category?>(
            value: _selectedCategory,
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(strings.text('no_category')),
              ),
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
              labelText: strings.text('category'),
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
                  decoration: InputDecoration(labelText: strings.text('name')),
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
            decoration: InputDecoration(labelText: strings.text('amount')),
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
            title: Text(
              _isIncome ? strings.text('income') : strings.text('expense'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(labelText: strings.text('note')),
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
            title: Text(strings.text('recurrence')),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: DropdownButtonFormField<RecurrenceType>(
                  value: _recurrenceType,
                  items: [
                    DropdownMenuItem(
                      value: RecurrenceType.none,
                      child: Text(strings.text('recurrence_none')),
                    ),
                    DropdownMenuItem(
                      value: RecurrenceType.daily,
                      child: Text(strings.text('recurrence_daily')),
                    ),
                    DropdownMenuItem(
                      value: RecurrenceType.monthly,
                      child: Text(strings.text('recurrence_monthly')),
                    ),
                    DropdownMenuItem(
                      value: RecurrenceType.yearly,
                      child: Text(strings.text('recurrence_yearly')),
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
                    value: _recurrenceDay,
                    decoration: InputDecoration(
                      labelText: strings.text('day_of_month'),
                    ),
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
                          value: _recurrenceMonth,
                          decoration: InputDecoration(
                            labelText: strings.text('month'),
                          ),
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
                          value: _recurrenceDay,
                          decoration: InputDecoration(
                            labelText: strings.text('day'),
                          ),
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
                title: Text(strings.text('reminder')),
              ),
              if (_reminderEnabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    children: [
                      DropdownButtonFormField<int>(
                        value: _reminderDaysBefore,
                        decoration: InputDecoration(
                          labelText: strings.text('days_before'),
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
                        decoration: InputDecoration(
                          labelText: strings.text('message'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _save, child: Text(strings.text('save'))),
        ],
      ),
    );
  }
}
