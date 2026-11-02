import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/ui/current_stats_screen.dart';
import 'package:cheapcheap/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens the shared month picker from the statistics screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.create();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const CurrentStatsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The screen formats the month with DateTime.now(), so the expected label
    // must be derived at runtime instead of being hardcoded.
    final now = DateTime.now();
    final monthLabel = formatMonthYear(DateTime(now.year, now.month, 1), 'en');

    await tester.tap(find.text(monthLabel));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('app-month-year-picker')),
      findsOneWidget,
    );

    final monthFormat = DateFormat.MMMM('en');
    for (var month = 1; month <= 12; month++) {
      final expected = monthFormat.format(DateTime(now.year, month, 1));
      expect(
        find.descendant(
          of: find.byKey(ValueKey('month-cell-$month')),
          matching: find.text(expected),
        ),
        findsOneWidget,
        reason: 'Month cell $month should render "$expected".',
      );
    }

    expect(tester.takeException(), isNull);
  });
}
