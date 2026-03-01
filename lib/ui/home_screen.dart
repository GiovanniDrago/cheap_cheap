import 'dart:io';

import 'package:cheapcheap/data/icon_options.dart';
import 'package:cheapcheap/l10n/app_localizations.dart';
import 'package:cheapcheap/models/expense.dart';
import 'package:cheapcheap/models/recurrence.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/ui/expense_form_screen.dart';
import 'package:cheapcheap/utils/date_utils.dart';
import 'package:cheapcheap/utils/formatters.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _initialPage = 1200;
  late final PageController _controller;
  late DateTime _baseMonth;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month, 1);
    _currentMonth = _baseMonth;
    _controller = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _monthForIndex(int index) {
    return addMonths(_baseMonth, index - _initialPage);
  }

  Future<void> _pickMonth() async {
    final picked = await showMonthYearPicker(
      context: context,
      initialDate: _currentMonth,
      firstDate: DateTime(2018, 1),
      lastDate: DateTime(2100, 12),
    );
    if (picked != null) {
      setState(() {
        _baseMonth = DateTime(picked.year, picked.month, 1);
        _currentMonth = _baseMonth;
      });
      _controller.jumpToPage(_initialPage);
    }
  }

  void _openAddExpense(DateTime month) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExpenseFormScreen(initialMonth: month)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    final locale = state.locale.toString();
    final monthLabel = DateFormat.yMMMM(locale).format(_currentMonth);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _pickMonth,
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              Text(
                                monthLabel,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.keyboard_arrow_down),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _importCsv(context),
                    icon: const Icon(Icons.upload_file),
                    tooltip: strings.text('import_csv'),
                  ),
                  IconButton(
                    onPressed: () => _exportCsv(context),
                    icon: const Icon(Icons.download),
                    tooltip: strings.text('export_csv'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() {
                    _currentMonth = _monthForIndex(index);
                  });
                },
                itemBuilder: (context, index) {
                  final month = _monthForIndex(index);
                  final expenses = state.expensesForMonth(month);
                  return _ExpenseMonthView(
                    month: month,
                    expenses: expenses,
                    currency: state.settings.currency,
                    locale: locale,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddExpense(_currentMonth),
        heroTag: 'home_fab',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final strings = AppLocalizations.of(context);
    final csv = _buildCsv(state);
    final directory = await _getExportDirectory();
    final file = File('${directory.path}/cheapcheap_export.csv');
    await file.writeAsString(csv);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('${strings.text('csv_exported')} ${file.path}')),
    );
  }

  Future<void> _importCsv(BuildContext context) async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final strings = AppLocalizations.of(context);
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
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('${strings.text('csv_imported')}: ${imported.length}'),
      ),
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

  Future<Directory> _getExportDirectory() async {
    return await getApplicationDocumentsDirectory();
  }
}

class _ExpenseMonthView extends StatelessWidget {
  const _ExpenseMonthView({
    required this.month,
    required this.expenses,
    required this.currency,
    required this.locale,
  });

  final DateTime month;
  final List<Expense> expenses;
  final String currency;
  final String locale;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      final strings = AppLocalizations.of(context);
      return Center(
        child: Text(
          strings.text('no_expenses'),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final grouped = <DateTime, List<Expense>>{};
    for (final expense in expenses) {
      final day = dateOnly(expense.date);
      grouped.putIfAbsent(day, () => []).add(expense);
    }
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final dayExpenses = grouped[day] ?? [];
        return _ExpenseDaySection(
          date: day,
          expenses: dayExpenses,
          currency: currency,
          locale: locale,
        );
      },
    );
  }
}

class _ExpenseDaySection extends StatelessWidget {
  const _ExpenseDaySection({
    required this.date,
    required this.expenses,
    required this.currency,
    required this.locale,
  });

  final DateTime date;
  final List<Expense> expenses;
  final String currency;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final dayLabel = DateFormat('EEEE', locale).format(date);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormat('d').format(date),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(dayLabel, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          ...expenses.map((expense) {
            final option = iconOptionById(expense.iconId);
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  child: Icon(option.icon, color: option.color),
                ),
                title: Text(expense.name),
                subtitle: Text(expense.note.isEmpty ? '-' : expense.note),
                trailing: Text(
                  formatCurrency(
                    expense.amount * (expense.isIncome ? 1 : -1),
                    currency,
                    locale,
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: expense.isIncome
                        ? Colors.green[700]
                        : Colors.red[700],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
