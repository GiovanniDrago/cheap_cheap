import 'package:cheapcheap/config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  bool get isSignedIn => currentUser != null;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<bool> signUp(String email, String password) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: AppConfig.emailRedirectUrl,
    );
    return response.session != null;
  }

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Map<String, dynamic>?> getApplication() async {
    return _client
        .from('applications')
        .select()
        .eq('app_key', AppConfig.appKey)
        .maybeSingle();
  }

  Future<String?> getApplicationId() async {
    final app = await getApplication();
    return app?['id'] as String?;
  }

  Future<void> registerAppLink(String applicationId) async {
    if (!isSignedIn) return;
    final userId = currentUser!.id;
    await _client.from('user_applications').upsert({
      'user_id': userId,
      'application_id': applicationId,
    });
  }

  Future<bool> hasCloudData(String applicationId) async {
    final userId = currentUser!.id;

    final prefsRow = await _client
        .from('app_preferences')
        .select('id')
        .eq('user_id', userId)
        .eq('application_id', applicationId)
        .maybeSingle();

    final dataRow = await _client
        .from('app_data')
        .select('id')
        .eq('user_id', userId)
        .eq('application_id', applicationId)
        .limit(1)
        .maybeSingle();

    return prefsRow != null || dataRow != null;
  }

  Future<void> pushPreferences(String applicationId, Map<String, dynamic> preferences) async {
    final userId = currentUser!.id;
    await _client.from('app_preferences').upsert({
      'user_id': userId,
      'application_id': applicationId,
      'preferences': preferences,
    }, onConflict: 'user_id,application_id');
  }

  Future<Map<String, dynamic>?> pullPreferences(String applicationId) async {
    final userId = currentUser!.id;
    final row = await _client
        .from('app_preferences')
        .select('preferences')
        .eq('user_id', userId)
        .eq('application_id', applicationId)
        .maybeSingle();

    if (row == null) return null;
    return Map<String, dynamic>.from(row['preferences'] as Map);
  }

  Future<void> pushAppData(
    String applicationId,
    String dataType,
    Map<String, dynamic> data,
  ) async {
    final userId = currentUser!.id;
    await _client.from('app_data').upsert({
      'user_id': userId,
      'application_id': applicationId,
      'data_type': dataType,
      'data': data,
    }, onConflict: 'user_id,application_id,data_type');
  }

  Future<Map<String, dynamic>?> pullAppData(
    String applicationId,
    String dataType,
  ) async {
    final userId = currentUser!.id;
    final row = await _client
        .from('app_data')
        .select('data')
        .eq('user_id', userId)
        .eq('application_id', applicationId)
        .eq('data_type', dataType)
        .maybeSingle();

    if (row == null) return null;
    return Map<String, dynamic>.from(row['data'] as Map);
  }
}
