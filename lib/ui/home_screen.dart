import 'package:cheapcheap/data/icon_options.dart';
import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/models/expense.dart';
import 'package:cheapcheap/navigation/app_router.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/utils/date_utils.dart';
import 'package:cheapcheap/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_year_picker/month_year_picker.dart';
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
    AppRouter.showExpenseForm(context, initialMonth: month);
  }

  void _openExpenseDetails(Expense expense, {bool openSplit = false}) {
    AppRouter.showExpenseDetails(
      context,
      expense: expense,
      initialSplitExpanded: openSplit,
    );
  }

  Future<void> _confirmDelete(Expense expense) async {
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
      context.read<AppState>().removeExpense(expense.id);
    }
  }

  Future<void> _openRefundDialog(Expense expense) async {
    final strings = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    var date = expense.refundDate ?? DateTime.now();
    final noteController = TextEditingController(text: expense.refundNote);
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
                            child: Text(formatDateShort(date, locale)),
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
    if (result == true && mounted) {
      final updated = expense.copyWith(
        refundDate: date,
        refundNote: noteController.text.trim(),
      );
      context.read<AppState>().updateExpense(updated);
    }
  }

  Future<void> _openExpenseMenu(Expense expense) async {
    final strings = AppLocalizations.of(context)!;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: Text(strings.details),
                onTap: () => Navigator.of(context).pop('details'),
              ),
              ListTile(
                leading: const Icon(Icons.call_split),
                title: Text(strings.split),
                onTap: () => Navigator.of(context).pop('split'),
              ),
              ListTile(
                leading: const Icon(Icons.undo),
                title: Text(strings.refund),
                onTap: () => Navigator.of(context).pop('refund'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(strings.delete),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    switch (action) {
      case 'details':
        _openExpenseDetails(expense);
        break;
      case 'split':
        _openExpenseDetails(expense, openSplit: true);
        break;
      case 'refund':
        await _openRefundDialog(expense);
        break;
      case 'delete':
        await _confirmDelete(expense);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final locale = state.locale.toString();
    final monthLabel = formatMonthYear(_currentMonth, locale);
    final currentAllocations = state.expenseAllocationsForMonth(_currentMonth);
    final monthTotal = currentAllocations
        .where((allocation) => !allocation.expense.isRefunded)
        .fold<double>(
          0,
          (sum, allocation) =>
              sum + allocation.amount * (allocation.expense.isIncome ? 1 : -1),
        );

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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    monthLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    formatCurrency(
                                      monthTotal,
                                      state.settings.currency,
                                      locale,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: monthTotal >= 0
                                              ? Colors.green[700]
                                              : Colors.red[700],
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.keyboard_arrow_down),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'monthly_stats') {
                        AppRouter.showMonthlyStats(context);
                      }
                      if (value == 'current_stats') {
                        AppRouter.showCurrentStats(context);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'monthly_stats',
                        child: Text(strings.monthlyStats),
                      ),
                      PopupMenuItem(
                        value: 'current_stats',
                        child: Text(strings.currentStats),
                      ),
                    ],
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
                  final allocations = state.expenseAllocationsForMonth(month);
                  return _ExpenseMonthView(
                    month: month,
                    allocations: allocations,
                    currency: state.settings.currency,
                    locale: locale,
                    onExpenseTap: _openExpenseDetails,
                    onExpenseLongPress: _openExpenseMenu,
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
}

class _ExpenseMonthView extends StatelessWidget {
  const _ExpenseMonthView({
    required this.month,
    required this.allocations,
    required this.currency,
    required this.locale,
    required this.onExpenseTap,
    required this.onExpenseLongPress,
  });

  final DateTime month;
  final List<ExpenseAllocation> allocations;
  final String currency;
  final String locale;
  final void Function(Expense expense) onExpenseTap;
  final void Function(Expense expense) onExpenseLongPress;

  @override
  Widget build(BuildContext context) {
    if (allocations.isEmpty) {
      final strings = AppLocalizations.of(context)!;
      return Center(
        child: Text(
          strings.noExpenses,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final grouped = <DateTime, List<ExpenseAllocation>>{};
    for (final allocation in allocations) {
      final day = dateOnly(allocation.date);
      grouped.putIfAbsent(day, () => []).add(allocation);
    }
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final dayAllocations = grouped[day] ?? [];
        return _ExpenseDaySection(
          date: day,
          allocations: dayAllocations,
          currency: currency,
          locale: locale,
          onExpenseTap: onExpenseTap,
          onExpenseLongPress: onExpenseLongPress,
        );
      },
    );
  }
}

class _ExpenseDaySection extends StatelessWidget {
  const _ExpenseDaySection({
    required this.date,
    required this.allocations,
    required this.currency,
    required this.locale,
    required this.onExpenseTap,
    required this.onExpenseLongPress,
  });

  final DateTime date;
  final List<ExpenseAllocation> allocations;
  final String currency;
  final String locale;
  final void Function(Expense expense) onExpenseTap;
  final void Function(Expense expense) onExpenseLongPress;

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
          ...allocations.map((allocation) {
            final expense = allocation.expense;
            final option = iconOptionById(expense.iconId);
            final isRefunded = expense.isRefunded;
            return Card(
              elevation: 0,
              color: isRefunded
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ListTile(
                onTap: () => onExpenseTap(expense),
                onLongPress: () => onExpenseLongPress(expense),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  child: Icon(option.icon, color: option.color),
                ),
                title: Text(expense.name),
                subtitle: expense.note.isEmpty ? null : Text(expense.note),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency(
                        allocation.amount * (expense.isIncome ? 1 : -1),
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
                    if (allocation.isSplit)
                      Text(
                        '${allocation.installmentNumber}/${allocation.totalPayments}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
