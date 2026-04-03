import 'dart:math';

import 'package:cheapcheap/data/icon_options.dart';
import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/models/category.dart';
import 'package:cheapcheap/models/expense.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CurrentStatsScreen extends StatefulWidget {
  const CurrentStatsScreen({super.key});

  @override
  State<CurrentStatsScreen> createState() => _CurrentStatsScreenState();
}

class _CurrentStatsScreenState extends State<CurrentStatsScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final locale = state.locale.toString();
    final currency = state.settings.currency;
    final now = DateTime.now();
    final expenses = state
        .expensesForMonth(DateTime(now.year, now.month, 1))
        .where((expense) => !expense.isRefunded)
        .where((expense) => !expense.isIncome)
        .toList();

    final data = _buildCategoryStats(expenses, state.categories, strings);
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
    final selectedExpenses = selected?.expenses ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(strings.currentStats)),
      body: Padding(
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
                  child: _PieChart(
                    data: data,
                    selectedId: selected?.id,
                    onSelected: (id) => setState(() => _selectedId = id),
                  ),
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
                    itemCount: selectedExpenses.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final expense = selectedExpenses[index];
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
                          subtitle: Text(formatDateShort(expense.date, locale)),
                          trailing: Text(
                            formatCurrency(
                              expense.amount * -1,
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
      ),
    );
  }

  List<_CategoryStat> _buildCategoryStats(
    List<Expense> expenses,
    List<Category> categories,
    AppLocalizations strings,
  ) {
    final Map<String, _CategoryStat> stats = {};
    for (final expense in expenses) {
      final categoryId = expense.categoryId ?? 'no_category';
      final category = expense.categoryId == null
          ? null
          : categories.firstWhere(
              (item) => item.id == expense.categoryId,
              orElse: () => categories.first,
            );
      final name = category?.name ?? strings.noCategory;
      final color = category == null
          ? Colors.blueGrey
          : (iconOptionById(category.iconId).color ?? Colors.teal);
      stats.putIfAbsent(
        categoryId,
        () => _CategoryStat(id: categoryId, name: name, color: color),
      );
      stats[categoryId]!.addExpense(expense);
    }
    final list = stats.values.toList()
      ..sort((a, b) => b.totalAbs.compareTo(a.totalAbs));
    return list;
  }
}

class _CategoryStat {
  _CategoryStat({required this.id, required this.name, required this.color});

  final String id;
  final String name;
  final Color color;
  final List<Expense> expenses = [];
  double totalAbs = 0;
  double totalNet = 0;

  void addExpense(Expense expense) {
    expenses.add(expense);
    totalAbs += expense.amount;
    totalNet += expense.amount * -1;
  }
}

class _PieChart extends StatefulWidget {
  const _PieChart({
    required this.data,
    required this.selectedId,
    required this.onSelected,
  });

  final List<_CategoryStat> data;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  State<_PieChart> createState() => _PieChartState();
}

class _PieChartState extends State<_PieChart> {
  final List<_Slice> _slices = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Builder(
            builder: (context) {
              return GestureDetector(
                onTapDown: (details) =>
                    _handleTap(details.localPosition, context.size),
                child: CustomPaint(
                  painter: _PieChartPainter(
                    data: widget.data,
                    selectedId: widget.selectedId,
                    onSlices: (slices) {
                      _slices
                        ..clear()
                        ..addAll(slices);
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: widget.data
              .map(
                (item) => _LegendDot(
                  label: item.name,
                  color: item.color,
                  selected: item.id == widget.selectedId,
                  onTap: () => widget.onSelected(item.id),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  void _handleTap(Offset position, Size? size) {
    if (size == null) return;
    final center = Offset(size.width / 2, size.height / 2);
    final vector = position - center;
    final radius = min(size.width, size.height) / 2;
    if (vector.distance > radius) return;
    var angle = atan2(vector.dy, vector.dx) + pi / 2;
    if (angle < 0) {
      angle += 2 * pi;
    }
    final normalized = angle;
    for (final slice in _slices) {
      if (normalized >= slice.start &&
          normalized <= slice.start + slice.sweep) {
        widget.onSelected(slice.id);
        break;
      }
    }
  }
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({
    required this.data,
    required this.selectedId,
    required this.onSlices,
  });

  final List<_CategoryStat> data;
  final String? selectedId;
  final ValueChanged<List<_Slice>> onSlices;

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.fold<double>(0, (sum, item) => sum + item.totalAbs);
    if (total == 0) return;
    final radius = min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    var startAngle = -pi / 2;
    final slices = <_Slice>[];

    for (final item in data) {
      final sweep = (item.totalAbs / total) * 2 * pi;
      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;
      final isSelected = item.id == selectedId;
      final adjustedRect = isSelected
          ? Rect.fromCircle(
              center: size.center(Offset.zero),
              radius: radius * 0.92,
            )
          : rect;
      canvas.drawArc(adjustedRect, startAngle, sweep, true, paint);
      slices.add(_Slice(id: item.id, start: startAngle + pi / 2, sweep: sweep));
      startAngle += sweep;
    }
    onSlices(slices);
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.selectedId != selectedId;
  }
}

class _Slice {
  _Slice({required this.id, required this.start, required this.sweep});

  final String id;
  final double start;
  final double sweep;
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
