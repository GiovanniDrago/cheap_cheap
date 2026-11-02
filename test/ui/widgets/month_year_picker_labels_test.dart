import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'picker_test_harness.dart';

/// Complete English month names, January to December.
const List<String> _englishMonths = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Complete Italian month names, January to December, as rendered by intl.
const List<String> _italianMonths = <String>[
  'gennaio',
  'febbraio',
  'marzo',
  'aprile',
  'maggio',
  'giugno',
  'luglio',
  'agosto',
  'settembre',
  'ottobre',
  'novembre',
  'dicembre',
];

/// Finds the label text rendered inside a single month cell.
///
/// The header also renders the selected month name, so the search is scoped to
/// the cell to avoid matching it as well.
Finder _cellLabel(int month, String label) {
  return find.descendant(
    of: find.byKey(ValueKey('month-cell-$month')),
    matching: find.text(label),
  );
}

void main() {
  group('Month-year picker labels', () {
    testWidgets('shows the twelve complete English month names', (
      tester,
    ) async {
      final harness = await pumpPicker(tester);
      await harness.open(tester);

      expect(
        find.byKey(const ValueKey('app-month-year-picker')),
        findsOneWidget,
      );

      for (var index = 0; index < _englishMonths.length; index++) {
        final month = index + 1;
        final label = _englishMonths[index];
        expect(
          find.byKey(ValueKey('month-cell-$month')),
          findsOneWidget,
          reason: 'month cell $month should exist',
        );
        expect(
          _cellLabel(month, label),
          findsOneWidget,
          reason: 'month cell $month should show "$label"',
        );
      }
    });

    testWidgets('shows the twelve complete Italian month names', (
      tester,
    ) async {
      final harness = await pumpPicker(tester, locale: const Locale('it'));
      await harness.open(tester);

      expect(
        find.byKey(const ValueKey('app-month-year-picker')),
        findsOneWidget,
      );

      for (var index = 0; index < _italianMonths.length; index++) {
        final month = index + 1;
        final label = _italianMonths[index];
        expect(
          find.byKey(ValueKey('month-cell-$month')),
          findsOneWidget,
          reason: 'month cell $month should exist',
        );
        expect(
          _cellLabel(month, label),
          findsOneWidget,
          reason: 'month cell $month should show "$label"',
        );
      }
    });

    testWidgets('returns the selected month', (tester) async {
      final harness = await pumpPicker(tester);
      await harness.open(tester);

      await tester.tap(find.byKey(const ValueKey('month-cell-3')));
      await tester.pumpAndSettle();

      expect(harness.selected.value, DateTime(2026, 3, 1));
      expect(
        find.byKey(const ValueKey('app-month-year-picker')),
        findsNothing,
      );
    });

    testWidgets('returns null when cancelled', (tester) async {
      final harness = await pumpPicker(tester);
      await harness.open(tester);

      await tester.tap(find.byKey(const ValueKey('picker-cancel')));
      await tester.pumpAndSettle();

      expect(harness.selected.value, isNull);
    });
  });
}
