import 'package:cheapcheap/app.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App builds', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = await AppState.create();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const CheapCheapApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('CheapCheap'), findsWidgets);
  });
}
