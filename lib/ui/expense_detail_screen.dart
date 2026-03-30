import 'package:cheapcheap/l10n/app_localizations.dart';
import 'package:cheapcheap/models/category.dart';
import 'package:cheapcheap/models/expense.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final TextEditingController _splitMessageController = TextEditingController();
  Category? _selectedCategory;
  bool _isIncome = false;
  bool _dirty = false;
  bool _splitExpanded = false;
  bool _splitEnabled = false;
  int _splitPayments = 2;
  SplitFrequency _splitFrequency = SplitFrequency.monthly;
  bool _splitReminderEnabled = false;
  int _splitReminderDaysBefore = 1;
  DateTime? _refundDate;
  String _refundNote = '';

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _selectedDate = expense.date;
    _refundDate = expense.refundDate;
    _refundNote = expense.refundNote;
    _dateController.text = DateFormat('yyyy-MM-dd').format(expense.date);
    _nameController.text = expense.name;
    _amountController.text = expense.amount.toStringAsFixed(2);
    _noteController.text = expense.note;
    _selectedCategory = null;
    _isIncome = expense.isIncome;
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
    _dateController.addListener(_markDirty);
    _nameController.addListener(_markDirty);
    _amountController.addListener(_markDirty);
    _noteController.addListener(_markDirty);
    _splitMessageController.addListener(_markDirty);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _splitMessageController.dispose();
    super.dispose();
  }

  void _markDirty() {
    final hasChanges = _hasChanges();
    if (hasChanges != _dirty) {
      setState(() => _dirty = hasChanges);
    }
  }

  bool _hasChanges() {
    final original = widget.expense;
    final updated = _buildExpense();
    final splitEqual = _splitEquals(original.splitPlan, updated.splitPlan);
    final refundEqual =
        original.refundDate == updated.refundDate &&
        original.refundNote == updated.refundNote;
    return original.date != updated.date ||
        original.name != updated.name ||
        original.amount != updated.amount ||
        original.isIncome != updated.isIncome ||
        original.categoryId != updated.categoryId ||
        original.note != updated.note ||
        !splitEqual ||
        !refundEqual;
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

  Expense _buildExpense() {
    final parsedDate = DateTime.tryParse(_dateController.text.trim());
    if (parsedDate != null) {
      _selectedDate = parsedDate;
    }
    final amount = parseAmount(_amountController.text);
    final strings = AppLocalizations.of(context);
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
      categoryId: _selectedCategory?.id,
      note: _noteController.text.trim(),
      splitPlan: splitPlan,
      refundDate: _refundDate,
      refundNote: _refundNote,
    );
  }

  String _defaultSplitMessage(String name, AppLocalizations strings) {
    final label = name.isEmpty ? strings.text('expense') : name;
    return '${strings.text('split_message_default')} $label (1/$_splitPayments)';
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
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
      _markDirty();
    }
  }

  Future<void> _openRefundDialog() async {
    final strings = AppLocalizations.of(context);
    var date = _refundDate ?? DateTime.now();
    final noteController = TextEditingController(text: _refundNote);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.text('refund')),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: strings.text('refund_date'),
                          ),
                          child: Text(DateFormat('yyyy-MM-dd').format(date)),
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
                      labelText: strings.text('refund_note'),
                    ),
                    maxLines: 2,
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
    if (result == true) {
      setState(() {
        _refundDate = date;
        _refundNote = noteController.text.trim();
      });
      _markDirty();
    }
  }

  Future<void> _confirmDelete() async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(strings.text('confirm_delete')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(strings.text('no')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.text('yes')),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) {
      context.read<AppState>().removeExpense(widget.expense.id);
      Navigator.of(context).pop();
    }
  }

  void _save() {
    final updated = _buildExpense();
    context.read<AppState>().updateExpense(updated);
    setState(() => _dirty = false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final categories = state.categories;
    final locale = state.locale.toString();
    final currency = state.settings.currency;
    _selectedCategory ??= state.getCategory(widget.expense.categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.text('details')),
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
              PopupMenuItem(value: 'split', child: Text(strings.text('split'))),
              PopupMenuItem(
                value: 'refund',
                child: Text(strings.text('refund')),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(strings.text('delete')),
              ),
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
                      strings.text('refund'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${strings.text('date')}: ${DateFormat('yyyy-MM-dd').format(_refundDate!)}',
                    ),
                    if (_refundNote.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('${strings.text('note')}: $_refundNote'),
                      ),
                  ],
                ),
              ),
            ),
          if (_refundDate != null) const SizedBox(height: 16),
          TextField(
            controller: _dateController,
            decoration: InputDecoration(
              labelText: strings.text('date'),
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: _pickDate,
              ),
            ),
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Category?>(
            key: ValueKey(_selectedCategory?.id),
            initialValue: _selectedCategory,
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(strings.text('no_category')),
              ),
              for (final category in categories)
                DropdownMenuItem(value: category, child: Text(category.name)),
            ],
            onChanged: (value) {
              setState(() => _selectedCategory = value);
              _markDirty();
            },
            decoration: InputDecoration(labelText: strings.text('category')),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: strings.text('name')),
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
              setState(() => _isIncome = value);
              _markDirty();
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
          const SizedBox(height: 16),
          ExpansionTile(
            initiallyExpanded: _splitExpanded,
            onExpansionChanged: (expanded) {
              setState(() => _splitExpanded = expanded);
            },
            title: Text(strings.text('split')),
            children: [
              SwitchListTile(
                value: _splitEnabled,
                onChanged: (value) {
                  setState(() => _splitEnabled = value);
                  _markDirty();
                },
                title: Text(strings.text('split_enabled')),
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
                          labelText: strings.text('split_payments'),
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
                          labelText: strings.text('split_frequency'),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: SplitFrequency.weekly,
                            child: Text(strings.text('reminder_weekly')),
                          ),
                          DropdownMenuItem(
                            value: SplitFrequency.monthly,
                            child: Text(strings.text('recurrence_monthly')),
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
                        title: Text(strings.text('reminder')),
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
                                labelText: strings.text('message'),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${strings.text('split_schedule')}: 1/$_splitPayments',
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
