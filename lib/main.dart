import 'package:cheapcheap/app.dart';
import 'package:cheapcheap/config.dart';
import 'package:cheapcheap/services/notification_service.dart';
import 'package:cheapcheap/services/supabase_service.dart';
import 'package:cheapcheap/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );

  await NotificationService.initialize();
  final supabaseService = SupabaseService();
  final state = await AppState.create(supabaseService: supabaseService);
  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const CheapCheapApp(),
    ),
  );
}
