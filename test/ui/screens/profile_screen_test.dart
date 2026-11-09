import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/models/expense.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/ui/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildApp(AppState state) {
  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const ProfileScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('collapses quests independently and keeps stats visible', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    final state = await AppState.create();

    await tester.pumpWidget(_buildApp(state));
    await tester.pumpAndSettle();

    expect(find.text('Add a profile picture'), findsOneWidget);
    expect(find.text('Strength'), findsOneWidget);

    await tester.tap(find.text('Quests'));
    await tester.pumpAndSettle();

    expect(find.text('Add a profile picture'), findsNothing);
    expect(find.text('Strength'), findsOneWidget);
    expect(state.settings.profileQuestsExpanded, isFalse);

    await tester.pumpWidget(_buildApp(state));
    await tester.pumpAndSettle();
    expect(find.text('Add a profile picture'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('collapses stats independently and keeps quests visible', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    final state = await AppState.create();

    await tester.pumpWidget(_buildApp(state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();

    expect(find.text('Strength'), findsNothing);
    expect(find.text('Add a profile picture'), findsOneWidget);
    expect(state.settings.profileStatsExpanded, isFalse);

    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('renders trophy cards from local transactions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(800, 3000));
    final state = await AppState.create();
    final now = DateTime.now();
    state.expenses = [
      Expense(
        id: 'expense-1',
        date: now,
        name: 'Market',
        amount: 42,
        isIncome: false,
        iconId: 'wallet',
        categoryId: 'cat_groceries',
      ),
    ];

    await tester.pumpWidget(_buildApp(state));
    await tester.pumpAndSettle();

    expect(find.text('Top category this month'), findsOneWidget);
    expect(find.text('Groceries'), findsWidgets);
    expect(find.text('Highest expense this month'), findsOneWidget);
    expect(find.text('No records yet'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
}
