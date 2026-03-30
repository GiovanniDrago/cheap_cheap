import 'package:cheapcheap/l10n/app_localizations.dart';
import 'package:cheapcheap/ui/categories_screen.dart';
import 'package:cheapcheap/ui/home_screen.dart';
import 'package:cheapcheap/ui/profile_screen.dart';
import 'package:cheapcheap/ui/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cheapcheap/state/app_state.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _lastQuestTick = 0;
  bool _welcomeInProgress = false;
  bool _snackQueued = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = context.watch<AppState>();
    if (!state.settings.hasSeenWelcome && !_welcomeInProgress) {
      _welcomeInProgress = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWelcome(context);
      });
    }

    if (state.questCompletionTick != _lastQuestTick) {
      _lastQuestTick = state.questCompletionTick;
      if (state.lastQuestCompletedName != null) {
        if (!_snackQueued) {
          _snackQueued = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final messenger = ScaffoldMessenger.maybeOf(context);
            if (messenger == null) return;
            messenger.clearSnackBars();
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  '${strings.text('quest_completed')}: ${state.lastQuestCompletedName}',
                ),
              ),
            );
            _snackQueued = false;
          });
        }
      }
    }
    final screens = [
      const HomeScreen(),
      const CategoriesScreen(),
      const ProfileScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: strings.text('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.category_outlined),
            selectedIcon: const Icon(Icons.category),
            label: strings.text('categories'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: strings.text('profile'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: strings.text('settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _showWelcome(BuildContext context) async {
    if (!mounted) return;
    final state = context.read<AppState>();
    await showDialog<void>(
      context: context,
      builder: (context) {
        final strings = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(strings.text('app_name')),
          content: Text(strings.text('welcome_intro')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.text('next')),
            ),
          ],
        );
      },
    );

    if (!context.mounted) return;
    setState(() => _index = 2);

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        final strings = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(strings.text('profile')),
          content: Text(strings.text('welcome_profile')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(strings.text('ok')),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    state.markWelcomeSeen();
    _welcomeInProgress = false;
  }
}
