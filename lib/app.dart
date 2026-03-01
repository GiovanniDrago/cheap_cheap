import 'package:cheapcheap/l10n/app_localizations.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/ui/main_shell.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CheapCheapApp extends StatelessWidget {
  const CheapCheapApp({super.key});

  static const List<FlexScheme> _themes = [
    FlexScheme.mandyRed,
    FlexScheme.deepBlue,
    FlexScheme.mango,
    FlexScheme.hippieBlue,
    FlexScheme.wasabi,
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final scheme = _themes[state.settings.themeIndex % _themes.length];
        final textTheme = GoogleFonts.spaceGroteskTextTheme();
        return MaterialApp(
          title: 'CheapCheap',
          theme: FlexThemeData.light(
            scheme: scheme,
            surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
            blendLevel: 12,
            textTheme: textTheme,
            useMaterial3: true,
          ),
          darkTheme: FlexThemeData.dark(
            scheme: scheme,
            surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
            blendLevel: 12,
            textTheme: textTheme,
            useMaterial3: true,
          ),
          themeMode: ThemeMode.light,
          locale: state.locale,
          supportedLocales: const [Locale('en'), Locale('it')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            MonthYearPickerLocalizations.delegate,
          ],
          home: const MainShell(),
        );
      },
    );
  }
}
