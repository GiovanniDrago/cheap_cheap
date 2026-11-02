import 'package:cheapcheap/ui/widgets/month_year_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Couples the picker dialog with the value it returns.
class PickerTestHarness {
  PickerTestHarness(this.selected);

  /// The value returned by `showAppMonthYearPicker`, null until the dialog closes.
  final ValueNotifier<DateTime?> selected;

  /// Taps the button that opens the picker and waits for the dialog.
  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('open-picker')));
    await tester.pumpAndSettle();
  }
}

/// Pumps an app exposing `showAppMonthYearPicker` through the `open-picker` button.
///
/// The viewport and text scale can be changed to exercise adaptive layouts.
Future<PickerTestHarness> pumpPicker(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  Size size = const Size(390, 844),
  double textScale = 1.0,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final selected = ValueNotifier<DateTime?>(null);
  final harness = PickerTestHarness(selected);

  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('it')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              key: const ValueKey('open-picker'),
              onPressed: () async {
                selected.value = await showAppMonthYearPicker(
                  context: context,
                  initialDate: initialDate ?? DateTime(2026, 11, 1),
                  firstDate: firstDate ?? DateTime(2018, 1, 1),
                  lastDate: lastDate ?? DateTime(2100, 12, 1),
                  locale: locale,
                );
              },
              child: const Text('Open picker'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}
