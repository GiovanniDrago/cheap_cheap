import 'dart:math' as math;

import 'package:cheapcheap/data/icon_options.dart';
import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/models/budget.dart';
import 'package:cheapcheap/models/category.dart';
import 'package:cheapcheap/models/expense.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/utils/formatters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BudgetStatsScreen extends StatefulWidget {
  const BudgetStatsScreen({super.key, required this.budget});

  final Budget budget;

  @override
  State<BudgetStatsScreen> createState() => _BudgetStatsScreenState();
}

class _BudgetStatsScreenState extends State<BudgetStatsScreen> {
  late bool _sortAscending;
  String? _selectedId;
  String? _drillDownCategoryId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final state = context.read<AppState>();
      _sortAscending = state.settings.budgetSortAscending;
      _initialized = true;
    }
  }

  void _toggleSort() {
    setState(() => _sortAscending = !_sortAscending);
  }

  void _selectItem(String? id) {
    if (_drillDownCategoryId != null || widget.budget.categoryIds.length == 1) {
      setState(() => _selectedId = id);
      return;
    }
    if (id != null) {
      setState(() {
        _drillDownCategoryId = id;
        _selectedId = null;
      });
    }
  }

  void _backToCategories() {
    setState(() {
      _drillDownCategoryId = null;
      _selectedId = null;
    });
  }

  bool get _isExpenseMode =>
      _drillDownCategoryId != null || widget.budget.categoryIds.length == 1;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final locale = state.locale.toString();
    final currency = state.settings.currency;

    final allocations = state.budgetAllocations(widget.budget);
    final items = _buildItems(allocations, state.categories, strings);
    final total = items.fold<double>(0, (sum, item) => sum + item.total);

    if (_sortAscending) {
      items.sort((a, b) => a.total.compareTo(b.total));
    } else {
      items.sort((a, b) => b.total.compareTo(a.total));
    }

    _ChartItem? selected;
    if (items.isNotEmpty) {
      selected = _selectedId == null
          ? items.first
          : items.firstWhere(
              (item) => item.id == _selectedId,
              orElse: () => items.first,
            );
    }

    final isDrillDown = _drillDownCategoryId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.budget.title} \u2013 ${strings.budgetStats}'),
        leading: isDrillDown
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _backToCategories,
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
            ),
            tooltip: _sortAscending ? strings.sortAscending : strings.sortDescending,
            onPressed: _toggleSort,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final chartHeight = isWide ? 280.0 : 240.0;

              final chartSection = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: chartHeight,
                    child: items.isEmpty
                        ? Center(child: Text(strings.noExpenses))
                        : _BudgetPieChart(
                            items: items,
                            selectedId: selected?.id,
                            onSelected: _selectItem,
                          ),
                  ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: items
                          .map(
                            (item) => _LegendDot(
                              label: item.name,
                              color: item.color,
                              selected: item.id == selected?.id,
                              onTap: () => _selectItem(item.id),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              );

              final listSection = items.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final percent = total == 0
                            ? 0.0
                            : (item.total / total) * 100;
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: item.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(item.name),
                            subtitle: Text(
                              '${percent.toStringAsFixed(1)}%',
                            ),
                            trailing: Text(
                              formatCurrency(item.total, currency, locale),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        );
                      },
                    );

              if (isWide && items.isNotEmpty) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: chartSection),
                    const SizedBox(width: 16),
                    Expanded(child: listSection),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  chartSection,
                  const SizedBox(height: 16),
                  if (items.isNotEmpty) Expanded(child: listSection),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<_ChartItem> _buildItems(
    List<ExpenseAllocation> allocations,
    List<Category> categories,
    AppLocalizations strings,
  ) {
    final Map<String, _ChartItem> stats = {};
    final bool expenseMode = _isExpenseMode;
    final drillDownId = _drillDownCategoryId;

    for (final allocation in allocations) {
      final expense = allocation.expense;
      if (expenseMode) {
        if (drillDownId != null && expense.categoryId != drillDownId) {
          continue;
        }
        final id = expense.id;
        final name = expense.name;
        final color = _expenseColor(id, name);
        stats.putIfAbsent(
          id,
          () => _ChartItem(id: id, name: name, color: color),
        );
        stats[id]!.add(allocation.amount);
      } else {
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
          () => _ChartItem(id: categoryId, name: name, color: color),
        );
        stats[categoryId]!.add(allocation.amount);
      }
    }

    return stats.values.toList();
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

  Color _expenseColor(String id, String name) {
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
    final hash = (id + name).codeUnits.fold<int>(0, (value, unit) {
      return (value * 31 + unit) & 0x7fffffff;
    });

    return palette[hash % palette.length];
  }
}

class _ChartItem {
  _ChartItem({required this.id, required this.name, required this.color});

  final String id;
  final String name;
  final Color color;
  double total = 0;

  void add(double amount) {
    total += amount;
  }
}

class _BudgetPieChart extends StatelessWidget {
  const _BudgetPieChart({
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  final List<_ChartItem> items;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, item) => sum + item.total);
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
                      if (index < 0 || index >= items.length) return;
                      onSelected(items[index].id);
                    },
                  ),
                  sections: items.map((item) {
                    final percent = total == 0
                        ? 0.0
                        : (item.total / total) * 100;
                    final isSelected = item.id == selectedId;
                    return PieChartSectionData(
                      value: item.total,
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
