final class AppConfig {
  AppConfig._();

  // Supabase
  static const supabaseUrl = 'https://riikpjuqkgpbdarodiek.supabase.co';
  static const supabaseAnonKey = 'SUPABASE_ANON_KEY';

  // Application identity (used for Supabase app lookup and data scoping)
  static const appKey = 'cheap_cheap';
  static const packageName = 'com.takasu.cheapcheap';

  // GitHub (update checker)
  static const githubOwner = 'GiovanniDrago';
  static const githubRepo = 'cheap_cheap';

  // Storage keys (SharedPreferences)
  static const keyCategories = 'categories';
  static const keyExpenses = 'expenses';
  static const keyBudgets = 'budgets';
  static const keyProfile = 'profile';
  static const keySettings = 'settings';
  static const keyQuestProgress = 'questProgress';
  static const keyDailyExpenseCounts = 'dailyExpenseCounts';
  static const keyDailyQuestCounts = 'dailyQuestCounts';
  static const keySyncEmail = 'sync_email';
  static const keyLastSyncTime = 'sync_last_sync_time';
}
