import 'dart:math' as math;

import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/models/expense.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/utils/formatters.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class MonthlyStatsScreen extends StatelessWidget {
  const MonthlyStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final state = context.watch<AppState>();
    final locale = state.locale.toString();
    final currency = state.settings.currency;
    final year = DateTime.now().year;
    final monthData = List<_MonthlyTotals>.generate(12, (index) {
      final month = DateTime(year, index + 1, 1);
      final allocations = state
          .expenseAllocationsForMonth(month)
          .where((allocation) => !allocation.expense.isRefunded)
          .toList();
      return _MonthlyTotals.fromAllocations(allocations);
    });
    final currentIndex = DateTime.now().month - 1;
    final currentMonth = monthData[currentIndex];
    final maxValue = monthData.fold<double>(0, (largest, item) {
      return math.max(largest, math.max(item.income, item.expense));
    });

    return Scaffold(
      appBar: AppBar(title: Text(strings.monthlyStats)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final chartHeight = constraints.maxWidth >= 800 ? 320.0 : 260.0;
            return ListView(
              children: [
                Text(
                  strings.yearOverview,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: chartHeight,
                  child: _MonthlyBarChart(
                    data: monthData,
                    maxValue: maxValue,
                    locale: locale,
                    currency: currency,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _LegendChip(
                      label: strings.income,
                      color: Colors.green[600]!,
                    ),
                    _LegendChip(
                      label: strings.expense,
                      color: Colors.red[600]!,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text(
                      '${strings.income}: ${formatCurrency(currentMonth.income, currency, locale)}',
                    ),
                    Text(
                      '${strings.expense}: ${formatCurrency(currentMonth.expense * -1, currency, locale)}',
                    ),
                    Text(
                      '${strings.total}: ${formatCurrency(currentMonth.net, currency, locale)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  const _MonthlyBarChart({
    required this.data,
    required this.maxValue,
    required this.locale,
    required this.currency,
  });

  final List<_MonthlyTotals> data;
  final double maxValue;
  final String locale;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chartMax = maxValue <= 0 ? 1.0 : maxValue;
    final axisFormatter = NumberFormat.compactSimpleCurrency(
      locale: locale,
      name: currency,
    );

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: chartMax * 1.2,
        alignment: BarChartAlignment.spaceAround,
        groupsSpace: 12,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: chartMax <= 4 ? 1 : chartMax / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                final month = DateTime(DateTime.now().year, index + 1, 1);
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    formatMonthShort(month, locale),
                    style: theme.textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              interval: chartMax <= 4 ? 1 : chartMax / 4,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    axisFormatter.format(value),
                    style: theme.textTheme.labelSmall,
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(enabled: false),
        barGroups: List.generate(data.length, (index) {
          final item = data[index];
          return BarChartGroupData(
            x: index,
            barsSpace: 6,
            barRods: [
              BarChartRodData(
                toY: item.income,
                width: 12,
                color: Colors.green[600],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
              BarChartRodData(
                toY: item.expense,
                width: 12,
                color: Colors.red[600],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
      duration: const Duration(milliseconds: 250),
    );
  }
}

class _MonthlyTotals {
  const _MonthlyTotals({required this.income, required this.expense});

  final double income;
  final double expense;

  double get net => income - expense;

  factory _MonthlyTotals.fromAllocations(List<ExpenseAllocation> allocations) {
    var income = 0.0;
    var expense = 0.0;

    for (final allocation in allocations) {
      if (allocation.expense.isIncome) {
        income += allocation.amount;
      } else {
        expense += allocation.amount;
      }
    }

    return _MonthlyTotals(income: income, expense: expense);
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
