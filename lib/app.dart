import 'package:cheapcheap/l10n/generated/app_localizations.dart';
import 'package:cheapcheap/navigation/app_router.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/ui/main_shell.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:month_year_picker/month_year_picker.dart';
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
        final themeMode = _resolveThemeMode(state.settings.themeMode);
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
          themeMode: themeMode,
          locale: state.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            MonthYearPickerLocalizations.delegate,
          ],
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const MainShell(),
        );
      },
    );
  }

  ThemeMode _resolveThemeMode(String mode) {
    switch (mode) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }
}
