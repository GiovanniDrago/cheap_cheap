import 'dart:math';

import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/utils/formatters.dart';
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

    final totals = List<double>.generate(12, (index) {
      final month = DateTime(year, index + 1, 1);
      final expenses = state.expensesForMonth(month);
      return expenses
          .where((expense) => !expense.isRefunded)
          .fold<double>(
            0,
            (sum, expense) =>
                sum + expense.amount * (expense.isIncome ? 1 : -1),
          );
    });
    final maxAbs = totals.isEmpty
        ? 1.0
        : totals
              .map((value) => value.abs())
              .reduce(max)
              .clamp(1, double.infinity)
              .toDouble();

    final currentIndex = DateTime.now().month - 1;

    return Scaffold(
      appBar: AppBar(title: Text(strings.monthlyStats)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final chartHeight = constraints.maxWidth >= 800 ? 280.0 : 220.0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.yearOverview,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: chartHeight,
                  child: CustomPaint(
                    painter: _MonthlyBarChartPainter(
                      totals: totals,
                      maxAbs: maxAbs,
                      positiveColor: Colors.green[600]!,
                      negativeColor: Colors.red[600]!,
                      axisColor: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(12, (index) {
                    final month = DateTime(year, index + 1, 1);
                    return Expanded(
                      child: Text(
                        DateFormat.MMM(locale).format(month),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
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
                Text(
                  '${strings.total}: ${formatCurrency(totals[currentIndex], currency, locale)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MonthlyBarChartPainter extends CustomPainter {
  _MonthlyBarChartPainter({
    required this.totals,
    required this.maxAbs,
    required this.positiveColor,
    required this.negativeColor,
    required this.axisColor,
  });

  final List<double> totals;
  final double maxAbs;
  final Color positiveColor;
  final Color negativeColor;
  final Color axisColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;

    final zeroY = size.height / 2;
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), axisPaint);

    final barWidth = size.width / (totals.length * 1.4);
    final spacing = barWidth * 0.4;
    var x = spacing;
    for (final total in totals) {
      final height = (total.abs() / maxAbs) * (size.height / 2 - 8);
      paint.color = total >= 0 ? positiveColor : negativeColor;
      final rect = total >= 0
          ? Rect.fromLTWH(x, zeroY - height, barWidth, height)
          : Rect.fromLTWH(x, zeroY, barWidth, height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        paint,
      );
      x += barWidth + spacing;
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyBarChartPainter oldDelegate) {
    return oldDelegate.totals != totals || oldDelegate.maxAbs != maxAbs;
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
