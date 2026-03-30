import 'package:cheapcheap/app.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:cheapcheap/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  final state = await AppState.create();
  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const CheapCheapApp(),
    ),
  );
}
