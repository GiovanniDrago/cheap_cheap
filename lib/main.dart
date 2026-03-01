import 'package:cheapcheap/app.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await AppState.create();
  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const CheapCheapApp(),
    ),
  );
}
