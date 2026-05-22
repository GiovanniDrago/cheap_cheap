import 'dart:math' as math;

import 'package:cheapcheap/data/icon_options.dart';
import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/models/category.dart';
import 'package:cheapcheap/models/expense.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/utils/date_utils.dart';
import 'package:cheapcheap/utils/formatters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:provider/provider.dart';

class CurrentStatsScreen extends StatefulWidget {
  const CurrentStatsScreen({super.key});

  @override
  State<CurrentStatsScreen> createState() => _CurrentStatsScreenState();
}

class _CurrentStatsScreenState extends State<CurrentStatsScreen> {
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
    final state = context.read<AppState>();
    final picked = await showMonthYearPicker(
      context: context,
      initialDate: _currentMonth,
      firstDate: DateTime(2018, 1),
      lastDate: DateTime(2100, 12),
      locale: pickerLocale(state.locale, state.settings.weekStart),
    );
    if (picked != null) {
      setState(() {
        _baseMonth = DateTime(picked.year, picked.month, 1);
        _currentMonth = _baseMonth;
      });
      _controller.jumpToPage(_initialPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final locale = state.locale.toString();
    final monthLabel = formatMonthYear(_currentMonth, locale);

    return Scaffold(
      appBar: AppBar(
        title: Text('${strings.currentStats} – $monthLabel'),
      ),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
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
                  return _CurrentStatsPage(month: month);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentStatsPage extends StatefulWidget {
  const _CurrentStatsPage({required this.month});

  final DateTime month;

  @override
  State<_CurrentStatsPage> createState() => _CurrentStatsPageState();
}

class _CurrentStatsPageState extends State<_CurrentStatsPage> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final locale = state.locale.toString();
    final currency = state.settings.currency;
    final allocations = state
        .expenseAllocationsForMonth(widget.month)
        .where((allocation) => !allocation.expense.isRefunded)
        .where((allocation) => !allocation.expense.isIncome)
        .toList();

    final data = _buildCategoryStats(allocations, state.categories, strings);
    final total = data.fold<double>(0, (sum, item) => sum + item.totalAbs);
    _CategoryStat? selected;
    if (data.isNotEmpty) {
      selected = _selectedId == null
          ? data.first
          : data.firstWhere(
              (item) => item.id == _selectedId,
              orElse: () => data.first,
            );
    }
    final selectedTotal = selected?.totalAbs ?? 0;
    final selectedPercent = total == 0 ? 0 : (selectedTotal / total) * 100;
    final selectedNet = selected?.totalNet ?? 0;
    final selectedAllocations = selected?.allocations ?? [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final breakdown = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                strings.categoryBreakdown,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: isWide ? 280 : 240,
                child: _CategoryDonutChart(
                  data: data,
                  selectedId: selected?.id,
                  onSelected: (id) => setState(() => _selectedId = id),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: data
                    .map(
                      (item) => _LegendDot(
                        label: item.name,
                        color: item.color,
                        selected: item.id == selected?.id,
                        onTap: () => setState(() => _selectedId = item.id),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Text(
                    '${strings.total}: ${formatCurrency(selectedTotal, currency, locale)}',
                  ),
                  Text(
                    '${strings.percentage}: ${selectedPercent.toStringAsFixed(1)}%',
                  ),
                  Text(
                    '${strings.net}: ${formatCurrency(selectedNet, currency, locale)}',
                  ),
                ],
              ),
            ],
          );

          if (data.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.categoryBreakdown,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Center(child: Text(strings.noExpenses)),
              ],
            );
          }

          final expenseList = selected == null
              ? const SizedBox.shrink()
              : ListView.separated(
                  itemCount: selectedAllocations.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final allocation = selectedAllocations[index];
                    final expense = allocation.expense;
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: ListTile(
                        title: Text(expense.name),
                        subtitle: Text(
                          formatDateShort(allocation.date, locale),
                        ),
                        trailing: Text(
                          formatCurrency(
                            allocation.amount * -1,
                            currency,
                            locale,
                          ),
                        ),
                      ),
                    );
                  },
                );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: breakdown),
                const SizedBox(width: 16),
                Expanded(child: expenseList),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              breakdown,
              const SizedBox(height: 16),
              if (selected != null) Expanded(child: expenseList),
            ],
          );
        },
      ),
    );
  }

  List<_CategoryStat> _buildCategoryStats(
    List<ExpenseAllocation> allocations,
    List<Category> categories,
    AppLocalizations strings,
  ) {
    final Map<String, _CategoryStat> stats = {};
    for (final allocation in allocations) {
      final expense = allocation.expense;
      final categoryId = expense.categoryId ?? 'no_category';
      final category = expense.categoryId == null
          ? null
          : categories.firstWhere(
              (item) => item.id == expense.categoryId,
              orElse: () => categories.first,
            );
      final name = category?.name ?? strings.noCategory;
      final color = _categoryColor(categoryId, category);
      stats.putIfAbsent(
        categoryId,
        () => _CategoryStat(id: categoryId, name: name, color: color),
      );
      stats[categoryId]!.addAllocation(allocation);
    }
    final list = stats.values.toList()
      ..sort((a, b) => b.totalAbs.compareTo(a.totalAbs));
    return list;
  }

  Color _categoryColor(String categoryId, Category? category) {
    final iconColor = category == null
        ? null
        : iconOptionById(category.iconId).color;
    if (iconColor != null) {
      return iconColor;
    }

    final palette = <Color>[
      Colors.teal,
      Colors.indigo,
      Colors.deepOrange,
      Colors.pink,
      Colors.cyan,
      Colors.deepPurple,
      Colors.amber.shade700,
      Colors.green.shade600,
      Colors.red.shade400,
      Colors.blue.shade600,
      Colors.lime.shade700,
      Colors.brown.shade500,
    ];
    final hash = categoryId.codeUnits.fold<int>(0, (value, unit) {
      return (value * 31 + unit) & 0x7fffffff;
    });

    return palette[hash % palette.length];
  }
}

class _CategoryStat {
  _CategoryStat({required this.id, required this.name, required this.color});

  final String id;
  final String name;
  final Color color;
  final List<ExpenseAllocation> allocations = [];
  double totalAbs = 0;
  double totalNet = 0;

  void addAllocation(ExpenseAllocation allocation) {
    allocations.add(allocation);
    totalAbs += allocation.amount;
    totalNet += allocation.amount * -1;
  }
}

class _CategoryDonutChart extends StatelessWidget {
  const _CategoryDonutChart({
    required this.data,
    required this.selectedId,
    required this.onSelected,
  });

  final List<_CategoryStat> data;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final total = data.fold<double>(0, (sum, item) => sum + item.totalAbs);
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartSize = math.min(
          constraints.maxWidth >= 500 ? 220.0 : 180.0,
          constraints.maxHeight - 24,
        );

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Center(
            child: SizedBox.square(
              dimension: chartSize,
              child: PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  centerSpaceRadius: chartSize * 0.24,
                  sectionsSpace: 3,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions) return;
                      final touched = response?.touchedSection;
                      final index = touched?.touchedSectionIndex ?? -1;
                      if (index < 0 || index >= data.length) return;
                      onSelected(data[index].id);
                    },
                  ),
                  sections: data.map((item) {
                    final percent = total == 0
                        ? 0.0
                        : (item.totalAbs / total) * 100;
                    final isSelected = item.id == selectedId;
                    return PieChartSectionData(
                      value: item.totalAbs,
                      color: item.color,
                      radius: isSelected ? chartSize * 0.32 : chartSize * 0.28,
                      title: percent >= 8
                          ? '${percent.toStringAsFixed(0)}%'
                          : '',
                      titleStyle: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }).toList(),
                ),
                duration: const Duration(milliseconds: 250),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}
