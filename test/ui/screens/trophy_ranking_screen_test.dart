import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/models/expense.dart';
import 'package:cheapcheap/models/trophy.dart';
import 'package:cheapcheap/navigation/app_router.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Expense _expense(String id, String name, DateTime date) {
  return Expense(
    id: id,
    date: date,
    name: name,
    amount: 10,
    isIncome: false,
    iconId: 'wallet',
  );
}

Widget _buildApp(AppState state, Trophy trophy) {
  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () =>
                  AppRouter.showTrophyRanking(context, trophy: trophy),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens a full-screen ranking with at most three entries', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.create();
    state.expenses = [
      _expense('a', 'Alpha', DateTime(2026, 11, 4)),
      _expense('b', 'Beta', DateTime(2026, 11, 3)),
      _expense('c', 'Gamma', DateTime(2026, 11, 2)),
      _expense('d', 'Delta', DateTime(2026, 11, 1)),
    ];
    final trophy = Trophy(
      kind: TrophyKind.highestExpenseAllTime,
      period: TrophyPeriod.allTime,
      subjectType: TrophySubjectType.expense,
      value: 40,
      expenseId: 'a',
      date: DateTime(2026, 11, 4),
      entries: [
        TrophyRankingEntry(
          value: 40,
          date: DateTime(2026, 11, 4),
          expenseId: 'a',
        ),
        TrophyRankingEntry(
          value: 30,
          date: DateTime(2026, 11, 3),
          expenseId: 'b',
        ),
        TrophyRankingEntry(
          value: 20,
          date: DateTime(2026, 11, 2),
          expenseId: 'c',
        ),
        TrophyRankingEntry(
          value: 10,
          date: DateTime(2026, 11, 1),
          expenseId: 'd',
        ),
      ],
    );

    await tester.pumpWidget(_buildApp(state, trophy));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Highest expense of all time'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Gamma'), findsOneWidget);
    expect(find.text('Delta'), findsNothing);

    expect(
      tester.getTopLeft(find.text('Alpha')).dy,
      lessThan(tester.getTopLeft(find.text('Beta')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Beta')).dy,
      lessThan(tester.getTopLeft(find.text('Gamma')).dy),
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('orders equal values by date, oldest first', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.create();
    state.expenses = [
      _expense('old', 'Older', DateTime(2026, 1, 1)),
      _expense('new', 'Newer', DateTime(2026, 2, 1)),
    ];
    final trophy = Trophy(
      kind: TrophyKind.highestExpenseAllTime,
      period: TrophyPeriod.allTime,
      subjectType: TrophySubjectType.expense,
      value: 10,
      expenseId: 'old',
      date: DateTime(2026, 1, 1),
      entries: [
        TrophyRankingEntry(
          value: 10,
          date: DateTime(2026, 1, 1),
          expenseId: 'old',
        ),
        TrophyRankingEntry(
          value: 10,
          date: DateTime(2026, 2, 1),
          expenseId: 'new',
        ),
      ],
    );

    await tester.pumpWidget(_buildApp(state, trophy));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Older')).dy,
      lessThan(tester.getTopLeft(find.text('Newer')).dy),
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows an empty state when the trophy has no entries', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.create();
    final trophy = const Trophy(
      kind: TrophyKind.highestExpenseAllTime,
      period: TrophyPeriod.allTime,
      subjectType: TrophySubjectType.expense,
      value: 0,
    );

    await tester.pumpWidget(_buildApp(state, trophy));
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('No records yet'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
