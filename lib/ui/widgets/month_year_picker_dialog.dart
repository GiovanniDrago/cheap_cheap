import 'package:cheapcheap/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Opens the app month-year picker.
///
/// Returns the first day of the selected month, or null when the dialog is
/// dismissed without a selection.
Future<DateTime?> showAppMonthYearPicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  required Locale locale,
}) {
  final initial = DateTime(initialDate.year, initialDate.month, 1);
  final first = DateTime(firstDate.year, firstDate.month, 1);
  final last = DateTime(lastDate.year, lastDate.month, 1);

  return showDialog<DateTime>(
    context: context,
    builder: (dialogContext) => Localizations.override(
      context: dialogContext,
      locale: locale,
      child: MonthYearPickerDialog(
        initialDate: initial,
        firstDate: first,
        lastDate: last,
        locale: locale,
      ),
    ),
  );
}

/// Month-year calendar dialog with complete, localized month names.
///
/// The dialog adapts to the available width and to the system text scale so
/// that month labels are never truncated and never leave the dialog bounds.
class MonthYearPickerDialog extends StatefulWidget {
  const MonthYearPickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.locale,
  });

  /// Initially selected month; only year and month are used.
  final DateTime initialDate;

  /// Lower bound of the selectable range, inclusive.
  final DateTime firstDate;

  /// Upper bound of the selectable range, inclusive.
  final DateTime lastDate;

  /// Language used for the month names and the header.
  final Locale locale;

  @override
  State<MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<MonthYearPickerDialog> {
  static const double _maxDialogWidth = 400;
  static const double _tapTargetSize = 48;
  static const EdgeInsets _insetPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 24,
  );

  late DateTime _selectedMonth;
  late int _displayedYear;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      1,
    );
    _displayedYear = _selectedMonth.year;
  }

  String get _localeName => widget.locale.toString();

  bool _isSelectable(DateTime month) {
    return !month.isBefore(widget.firstDate) &&
        !month.isAfter(widget.lastDate);
  }

  void _selectMonth(int month) {
    final date = DateTime(_displayedYear, month, 1);
    if (!_isSelectable(date)) {
      return;
    }
    Navigator.of(context).pop(date);
  }

  int _columnsFor(double width, double textScale) {
    if (textScale > 1.6 || width < 300) {
      return 1;
    }
    if (textScale > 1.15 || width < 340) {
      return 2;
    }
    return 3;
  }

  double _aspectRatioFor(int columns) {
    switch (columns) {
      case 1:
        return 3.2;
      case 2:
        return 2.4;
      default:
        return 1.9;
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final textScale = media.textScaler.scale(1);
    final availableHeight = media.size.height - _insetPadding.vertical;

    return Dialog(
      key: const ValueKey('app-month-year-picker'),
      insetPadding: _insetPadding,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: _maxDialogWidth,
          maxHeight: availableHeight > 0 ? availableHeight : 0,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : _maxDialogWidth;
            final columns = _columnsFor(width, textScale);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: _buildMonthGrid(context, columns),
                  ),
                ),
                _buildActions(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = DateFormat.MMMM(_localeName).format(
      DateTime(_displayedYear, _selectedMonth.month, 1),
    );
    final firstYear = widget.firstDate.year;
    final lastYear = widget.lastDate.year;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      color: colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              key: const ValueKey('picker-header'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          DropdownButton<int>(
            key: const ValueKey('picker-year'),
            value: _displayedYear,
            underline: const SizedBox.shrink(),
            borderRadius: BorderRadius.circular(12),
            items: [
              for (var year = firstYear; year <= lastYear; year++)
                DropdownMenuItem<int>(value: year, child: Text('$year')),
            ],
            onChanged: (year) {
              if (year == null) {
                return;
              }
              setState(() => _displayedYear = year);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(BuildContext context, int columns) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisCount: columns,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: _aspectRatioFor(columns),
      children: [
        for (final date in monthsOfYear(_displayedYear))
          _buildMonthCell(context, date),
      ],
    );
  }

  Widget _buildMonthCell(BuildContext context, DateTime date) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final label = DateFormat.MMMM(_localeName).format(date);
    final isEnabled = _isSelectable(date);
    final isSelected =
        date.year == _selectedMonth.year && date.month == _selectedMonth.month;

    return Semantics(
      label: '$label $_displayedYear',
      button: true,
      enabled: isEnabled,
      selected: isSelected,
      excludeSemantics: true,
      child: TextButton(
        key: ValueKey('month-cell-${date.month}'),
        onPressed: isEnabled ? () => _selectMonth(date.month) : null,
        style: TextButton.styleFrom(
          minimumSize: const Size(_tapTargetSize, _tapTargetSize),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          backgroundColor: isSelected ? colorScheme.secondaryContainer : null,
          foregroundColor: isSelected
              ? colorScheme.onSecondaryContainer
              : colorScheme.onSurface,
          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: theme.textTheme.labelLarge,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, textAlign: TextAlign.center, maxLines: 2),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          key: const ValueKey('picker-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ),
    );
  }
}
