import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'picker_test_harness.dart';

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

void main() {
  group('month-year picker adaptive layout', () {
    /// Asserts that every month cell shows its complete label.
    Future<void> expectAllMonthsComplete(
      WidgetTester tester, {
      List<String> names = _englishMonths,
    }) async {
      for (var month = 1; month <= 12; month++) {
        final cell = find.byKey(ValueKey('month-cell-$month'));
        expect(cell, findsOneWidget);
        expect(
          find.descendant(of: cell, matching: find.text(names[month - 1])),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    }

    testWidgets('fits on a narrow phone width', (tester) async {
      final harness = await pumpPicker(tester, size: const Size(320, 640));
      await harness.open(tester);

      expect(tester.takeException(), isNull);
      await expectAllMonthsComplete(tester);
    });

    testWidgets('fits with a large system text scale', (tester) async {
      final harness = await pumpPicker(tester, textScale: 2.0);
      await harness.open(tester);

      expect(tester.takeException(), isNull);
      await expectAllMonthsComplete(tester);
    });

    testWidgets('fits in landscape', (tester) async {
      final harness = await pumpPicker(tester, size: const Size(844, 390));
      await harness.open(tester);

      expect(tester.takeException(), isNull);
      await expectAllMonthsComplete(tester);
    });

    testWidgets('fits with Italian labels at a large text scale', (
      tester,
    ) async {
      final harness = await pumpPicker(
        tester,
        locale: const Locale('it'),
        textScale: 2.0,
      );
      await harness.open(tester);

      expect(tester.takeException(), isNull);
      await expectAllMonthsComplete(tester, names: _italianMonths);
    });

    testWidgets('exposes complete month semantics and a comfortable tap target', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      final harness = await pumpPicker(tester);
      await harness.open(tester);

      expect(tester.takeException(), isNull);
      expect(find.bySemanticsLabel('September 2026'), findsWidgets);

      final size = tester.getSize(
        find.byKey(const ValueKey('month-cell-9')),
      );
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));

      // Dispose inside the test body: the framework verifies that every
      // semantics handle is released before teardown callbacks run.
      handle.dispose();
    });
  });
}
