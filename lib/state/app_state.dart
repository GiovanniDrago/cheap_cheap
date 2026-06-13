import 'dart:convert';
import 'dart:math';

import 'package:cheapcheap/config.dart';
import 'package:cheapcheap/data/defaults.dart';
import 'package:cheapcheap/models/budget.dart';
import 'package:cheapcheap/models/category.dart';
import 'package:cheapcheap/models/expense.dart';
import 'package:cheapcheap/models/profile.dart';
import 'package:cheapcheap/models/quest.dart';
import 'package:cheapcheap/models/recurrence.dart';
import 'package:cheapcheap/models/reminder.dart';
import 'package:cheapcheap/models/settings.dart';
import 'package:cheapcheap/models/stat_key.dart';
import 'package:cheapcheap/services/notification_service.dart';
import 'package:cheapcheap/services/storage_service.dart';
import 'package:cheapcheap/services/supabase_service.dart';
import 'package:cheapcheap/utils/date_utils.dart';
import 'package:flutter/material.dart';

enum SyncStatus { idle, syncing, synced, error }

class AppState extends ChangeNotifier {
  AppState._(this._storage, {SupabaseService? supabaseService})
      : _supabaseService = supabaseService;

  final StorageService _storage;
  final SupabaseService? _supabaseService;

  List<Category> categories = [];
  List<Expense> expenses = [];
  List<Budget> budgets = [];
  Profile profile = Profile();
  Settings settings = Settings();
  Map<String, List<String>> questCompletions = {};
  Map<String, int> dailyExpenseCounts = {};
  Map<String, int> dailyQuestCounts = {};
  String? lastQuestCompletedId;
  String? lastQuestCompletedName;
  int questCompletionTick = 0;

  SyncStatus _syncStatus = SyncStatus.idle;
  DateTime? _lastSyncTime;
  String? _syncEmail;

  SyncStatus get syncStatus => _syncStatus;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get syncEmail => _syncEmail;
  bool get isSignedIn => _supabaseService?.isSignedIn ?? false;
  SupabaseService? get supabaseService => _supabaseService;

  static Future<AppState> create({SupabaseService? supabaseService}) async {
    final storage = await StorageService.create();
    final state = AppState._(storage, supabaseService: supabaseService);
    await state._load();
    return state;
  }

  Future<void> _load() async {
    final categoryList = _storage.readJsonList(AppConfig.keyCategories);
    categories = categoryList == null
        ? [...defaultCategories]
        : categoryList
              .map((item) => Category.fromJson(Map<String, dynamic>.from(item)))
              .toList();

    final expenseList = _storage.readJsonList(AppConfig.keyExpenses);
    expenses = expenseList == null
        ? []
        : expenseList
              .map((item) => Expense.fromJson(Map<String, dynamic>.from(item)))
              .toList();
    expenses.sort((a, b) => _expenseSortDate(b).compareTo(_expenseSortDate(a)));

    final budgetList = _storage.readJsonList(AppConfig.keyBudgets);
    budgets = budgetList == null
        ? _defaultBudgets()
        : budgetList
              .map((item) => Budget.fromJson(Map<String, dynamic>.from(item)))
              .toList();

    final profileJson = _storage.readJson(AppConfig.keyProfile);
    profile = profileJson == null ? Profile() : Profile.fromJson(profileJson);

    final settingsJson = _storage.readJson(AppConfig.keySettings);
    settings = settingsJson == null
        ? Settings()
        : Settings.fromJson(settingsJson);
    await _syncReminders();
    await _syncExpenseReminders();

    final questJson = _storage.readJson(AppConfig.keyQuestProgress);
    if (questJson != null) {
      questCompletions = Map<String, List<String>>.fromEntries(
        questJson.entries.map(
          (entry) =>
              MapEntry(entry.key, List<String>.from(entry.value as List)),
        ),
      );
    }

    final expenseCountJson = _storage.readJson(AppConfig.keyDailyExpenseCounts);
    if (expenseCountJson != null) {
      dailyExpenseCounts = expenseCountJson.map(
        (key, value) => MapEntry(key, value as int),
      );
    }

    final questCountJson = _storage.readJson(AppConfig.keyDailyQuestCounts);
    if (questCountJson != null) {
      dailyQuestCounts = questCountJson.map(
        (key, value) => MapEntry(key, value as int),
      );
    }

    _syncEmail = _storage.readString(AppConfig.keySyncEmail);
    final lastSync = _storage.readString(AppConfig.keyLastSyncTime);
    if (lastSync != null && lastSync.isNotEmpty) {
      _lastSyncTime = DateTime.tryParse(lastSync);
    }
    if (_supabaseService?.isSignedIn ?? false) {
      _syncStatus = SyncStatus.synced;
    }
  }

  Future<void> _persist() async {
    await _storage.writeJsonList(
      AppConfig.keyCategories,
      categories.map((category) => category.toJson()).toList(),
    );
    await _storage.writeJsonList(
      AppConfig.keyExpenses,
      expenses.map((expense) => expense.toJson()).toList(),
    );
    await _storage.writeJsonList(
      AppConfig.keyBudgets,
      budgets.map((budget) => budget.toJson()).toList(),
    );
    await _storage.writeJson(AppConfig.keyProfile, profile.toJson());
    await _storage.writeJson(AppConfig.keySettings, settings.toJson());
    await _storage.writeJson(AppConfig.keyQuestProgress, questCompletions);
    await _storage.writeJson(AppConfig.keyDailyExpenseCounts, dailyExpenseCounts);
    await _storage.writeJson(AppConfig.keyDailyQuestCounts, dailyQuestCounts);
  }

  Locale get locale => Locale(settings.localeCode);

  void updateThemeIndex(int index) {
    settings = settings.copyWith(themeIndex: index);
    _persist();
    notifyListeners();
  }

  void updateThemeMode(String mode) {
    settings = settings.copyWith(themeMode: mode);
    _persist();
    notifyListeners();
  }

  void updateLocale(String code) {
    settings = settings.copyWith(localeCode: code);
    _persist();
    notifyListeners();
  }

  void updateCurrency(String currency) {
    settings = settings.copyWith(currency: currency);
    _persist();
    notifyListeners();
  }

  void updateBudgetSortAscending(bool ascending) {
    settings = settings.copyWith(budgetSortAscending: ascending);
    _persist();
    notifyListeners();
  }

  void updateDateFormat(String format) {
    settings = settings.copyWith(dateFormat: format);
    _persist();
    notifyListeners();
  }

  void updateWeekStart(String start) {
    settings = settings.copyWith(weekStart: start);
    _persist();
    notifyListeners();
  }

  void markWelcomeSeen() {
    settings = settings.copyWith(hasSeenWelcome: true);
    _persist();
    notifyListeners();
  }

  Future<NotificationScheduleStatus> addReminder(Reminder reminder) async {
    settings = settings.copyWith(reminders: [...settings.reminders, reminder]);
    await _persist();
    notifyListeners();
    return NotificationService.scheduleReminder(reminder);
  }

  Future<NotificationScheduleStatus> updateReminder(Reminder reminder) async {
    settings = settings.copyWith(
      reminders: settings.reminders
          .map((item) => item.id == reminder.id ? reminder : item)
          .toList(),
    );
    await _persist();
    notifyListeners();
    return NotificationService.scheduleReminder(reminder);
  }

  Future<void> removeReminder(String id) async {
    settings = settings.copyWith(
      reminders: settings.reminders.where((item) => item.id != id).toList(),
    );
    await _persist();
    notifyListeners();
    await NotificationService.cancelReminder(id);
  }

  Future<void> _syncReminders() async {
    for (final reminder in settings.reminders) {
      await NotificationService.scheduleReminder(reminder);
    }
  }

  void setProfileName(String name) {
    profile = profile.copyWith(name: name);
    _persist();
    notifyListeners();
  }

  void setProfileImage(String path) {
    profile = profile.copyWith(imagePath: path);
    _persist();
    notifyListeners();
    _tryCompleteQuest('quest_profile_picture');
  }

  void addCategory(Category category) {
    categories = [...categories, category];
    _persist();
    notifyListeners();
    _tryCompleteQuest('quest_create_category');
  }

  void updateCategory(Category category) {
    categories = categories
        .map((existing) => existing.id == category.id ? category : existing)
        .toList();
    _persist();
    notifyListeners();
  }

  Category? getCategory(String? id) {
    if (id == null) {
      return null;
    }
    if (categories.isEmpty) {
      return null;
    }
    return categories.firstWhere(
      (category) => category.id == id,
      orElse: () => categories.first,
    );
  }

  List<Budget> _defaultBudgets() {
    return [
      Budget(
        id: 'budget_month_default',
        title: 'Month budget',
        description: '',
        amount: 0,
        isEnabled: false,
        period: BudgetPeriod.monthly,
        categoryIds: [],
        isDefault: true,
      ),
      Budget(
        id: 'budget_annual_default',
        title: 'Annual budget',
        description: '',
        amount: 0,
        isEnabled: false,
        period: BudgetPeriod.annual,
        categoryIds: [],
        isDefault: true,
      ),
    ];
  }

  void addBudget(Budget budget) {
    budgets = [...budgets, budget];
    _persist();
    notifyListeners();
  }

  void updateBudget(Budget budget) {
    budgets = budgets
        .map((existing) => existing.id == budget.id ? budget : existing)
        .toList();
    _persist();
    notifyListeners();
  }

  void removeBudget(String id) {
    budgets = budgets.where((budget) => budget.id != id).toList();
    _persist();
    notifyListeners();
  }

  void toggleBudgetEnabled(String id, bool enabled) {
    budgets = budgets.map((budget) {
      if (budget.id == id) {
        return budget.copyWith(isEnabled: enabled);
      }
      return budget;
    }).toList();
    _persist();
    notifyListeners();
  }

  double calculateBudgetSpent(Budget budget) {
    if (budget.period == BudgetPeriod.monthly) {
      final now = DateTime.now();
      final month = DateTime(now.year, now.month, 1);
      final allocations = expenseAllocationsForMonth(month)
          .where((a) => !a.expense.isRefunded)
          .where((a) => !a.expense.isIncome);
      return _sumAllocations(allocations, budget.categoryIds);
    } else {
      final now = DateTime.now();
      var total = 0.0;
      for (var m = 1; m <= 12; m++) {
        final month = DateTime(now.year, m, 1);
        final allocations = expenseAllocationsForMonth(month)
            .where((a) => !a.expense.isRefunded)
            .where((a) => !a.expense.isIncome);
        total += _sumAllocations(allocations, budget.categoryIds);
      }
      return total;
    }
  }

  List<ExpenseAllocation> budgetAllocations(Budget budget) {
    if (budget.period == BudgetPeriod.monthly) {
      final now = DateTime.now();
      final month = DateTime(now.year, now.month, 1);
      final allocations = expenseAllocationsForMonth(month)
          .where((a) => !a.expense.isRefunded)
          .where((a) => !a.expense.isIncome);
      return _filterAllocations(allocations, budget.categoryIds).toList();
    } else {
      final now = DateTime.now();
      final List<ExpenseAllocation> result = [];
      for (var m = 1; m <= 12; m++) {
        final month = DateTime(now.year, m, 1);
        final allocations = expenseAllocationsForMonth(month)
            .where((a) => !a.expense.isRefunded)
            .where((a) => !a.expense.isIncome);
        result.addAll(_filterAllocations(allocations, budget.categoryIds));
      }
      return result;
    }
  }

  Iterable<ExpenseAllocation> _filterAllocations(
    Iterable<ExpenseAllocation> allocations,
    List<String> categoryIds,
  ) {
    if (categoryIds.isEmpty) {
      return allocations;
    }
    return allocations
        .where((a) => categoryIds.contains(a.expense.categoryId));
  }

  double _sumAllocations(
    Iterable<ExpenseAllocation> allocations,
    List<String> categoryIds,
  ) {
    if (categoryIds.isEmpty) {
      return allocations.fold(0, (sum, a) => sum + a.amount);
    }
    return allocations
        .where((a) => categoryIds.contains(a.expense.categoryId))
        .fold(0, (sum, a) => sum + a.amount);
  }

  Future<NotificationScheduleStatus?> addExpense(Expense expense) async {
    expenses = [...expenses, expense];
    expenses.sort((a, b) => _expenseSortDate(b).compareTo(_expenseSortDate(a)));
    _incrementDailyExpense(expense.date);
    _applyStatImpact(expense);
    await _persist();
    notifyListeners();
    _tryCompleteQuest('quest_add_expense');
    if (_dailyExpenseCount(expense.date) >= 3) {
      _tryCompleteQuest('quest_add_3_expenses');
    }
    if (expense.recurrence != null &&
        expense.recurrence!.type != RecurrenceType.none) {
      _tryCompleteQuest('quest_add_recurrent');
    }

    return _scheduleExpenseReminder(expense);
  }

  void _applyStatImpact(Expense expense) {
    final category = getCategory(expense.categoryId);
    final statKey = category?.statKey ?? StatKey.spirit;
    final delta = min(1, expense.amount.abs() / 200);
    final Map<StatKey, double> nextStats = Map.of(profile.stats);
    for (final key in StatKey.values) {
      final current = nextStats[key] ?? 0;
      if (key == statKey) {
        nextStats[key] = _clampStat(current + delta);
      } else {
        nextStats[key] = _clampStat(current - (delta / 2));
      }
    }
    profile = profile.copyWith(stats: nextStats);
  }

  double _clampStat(double value) {
    if (value > 20) return 20;
    if (value < -20) return -20;
    return value;
  }

  List<Expense> expensesForMonth(DateTime month) {
    return expenses.where((expense) {
      final date = _expenseSortDate(expense);
      return date.year == month.year && date.month == month.month;
    }).toList();
  }

  List<ExpenseAllocation> expenseAllocationsForMonth(DateTime month) {
    return expenses
        .expand((expense) => expense.allocations())
        .where(
          (allocation) =>
              allocation.date.year == month.year &&
              allocation.date.month == month.month,
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<NotificationScheduleStatus?> updateExpense(Expense expense) async {
    expenses = expenses
        .map((existing) => existing.id == expense.id ? expense : existing)
        .toList();
    expenses.sort((a, b) => _expenseSortDate(b).compareTo(_expenseSortDate(a)));
    await _persist();
    notifyListeners();

    return _scheduleExpenseReminder(expense);
  }

  Future<void> removeExpense(String id) async {
    expenses = expenses.where((expense) => expense.id != id).toList();
    await _persist();
    notifyListeners();
    await NotificationService.cancelExpenseReminder(id);
  }

  Future<void> _syncExpenseReminders() async {
    for (final expense in expenses) {
      await _scheduleExpenseReminder(expense);
    }
  }

  Future<NotificationScheduleStatus?> _scheduleExpenseReminder(
    Expense expense,
  ) async {
    await NotificationService.cancelExpenseReminder(expense.id);
    final reminderDateTime = expense.reminderDateTime;
    if (!expense.reminderEnabled || reminderDateTime == null) {
      return null;
    }

    return NotificationService.scheduleExpenseReminder(
      expenseId: expense.id,
      scheduledAt: reminderDateTime,
      message: expense.reminderMessage.trim().isEmpty
          ? expense.name
          : expense.reminderMessage,
    );
  }

  List<Quest> get quests => defaultQuests;

  void markCategoriesOpened() {
    _tryCompleteQuest('quest_open_category_list');
  }

  void _incrementDailyExpense(DateTime date) {
    final key = _dateKey(date);
    dailyExpenseCounts[key] = _dailyExpenseCount(date) + 1;
  }

  int _dailyExpenseCount(DateTime date) {
    return dailyExpenseCounts[_dateKey(date)] ?? 0;
  }

  void _tryCompleteQuest(String questId) {
    final quest = quests.firstWhere(
      (item) => item.id == questId,
      orElse: () => defaultQuests.first,
    );
    if (profile.name.trim().isEmpty) {
      return;
    }
    if (!canCompleteQuest(quest)) {
      return;
    }
    if (isQuestLimitReached()) {
      return;
    }
    final todayKey = _dateKey(DateTime.now());
    final dailyCount = dailyQuestCounts[todayKey] ?? 0;
    _recordQuestCompletion(quest, DateTime.now());
    dailyQuestCounts[todayKey] = dailyCount + 1;
    _addXp(quest.expPoints);
    lastQuestCompletedId = quest.id;
    lastQuestCompletedName = quest.name;
    questCompletionTick += 1;
    _persist();
    notifyListeners();
  }

  bool isQuestLimitReached() {
    final todayKey = _dateKey(DateTime.now());
    final dailyCount = dailyQuestCounts[todayKey] ?? 0;
    return dailyCount >= 3;
  }

  Duration timeToNextQuestReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }

  bool canCompleteQuest(Quest quest) {
    final completions = questCompletions[quest.id] ?? [];
    if (quest.frequency == QuestFrequency.once) {
      return completions.isEmpty;
    }
    if (completions.isEmpty) {
      return true;
    }
    final last = DateTime.parse(completions.last);
    if (quest.frequency == QuestFrequency.daily) {
      return !isSameDay(last, DateTime.now());
    }
    final now = DateTime.now();
    final lastWeek = DateTime(
      last.year,
      last.month,
      last.day,
    ).subtract(Duration(days: last.weekday - 1));
    final currentWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return lastWeek.isBefore(currentWeek);
  }

  void _recordQuestCompletion(Quest quest, DateTime date) {
    final list = questCompletions[quest.id] ?? [];
    list.add(dateOnly(date).toIso8601String());
    questCompletions[quest.id] = list;
  }

  int _addXp(int exp) {
    var totalXp = profile.xp + exp;
    var level = profile.level;
    var levelsGained = 0;
    while (totalXp >= _xpForNextLevel(level)) {
      totalXp -= _xpForNextLevel(level);
      level += 1;
      levelsGained += 1;
    }
    profile = profile.copyWith(level: level, xp: totalXp);
    return levelsGained;
  }

  int xpForNextLevel() => _xpForNextLevel(profile.level);

  int _xpForNextLevel(int level) {
    final questsNeeded =
        (3 + (level - 1) * 0.6 + (level - 1) * (level - 1) * 0.01).round();
    return questsNeeded * 10;
  }

  String exportStateJson() {
    return jsonEncode({
      AppConfig.keyCategories: categories.map((category) => category.toJson()).toList(),
      AppConfig.keyExpenses: expenses.map((expense) => expense.toJson()).toList(),
      AppConfig.keyProfile: profile.toJson(),
      AppConfig.keySettings: settings.toJson(),
    });
  }

  void importExpenses(List<Expense> imported) {
    expenses = [...expenses, ...imported];
    expenses.sort((a, b) => _expenseSortDate(b).compareTo(_expenseSortDate(a)));
    _persist();
    notifyListeners();
  }

  DateTime _expenseSortDate(Expense expense) {
    return expense.refundDate ?? expense.date;
  }

  String _dateKey(DateTime date) {
    final day = dateOnly(date);
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _buildStateData() {
    return {
      AppConfig.keyCategories: categories.map((c) => c.toJson()).toList(),
      AppConfig.keyExpenses: expenses.map((e) => e.toJson()).toList(),
      AppConfig.keyBudgets: budgets.map((b) => b.toJson()).toList(),
      AppConfig.keyProfile: profile.toJson(),
      AppConfig.keyQuestProgress: questCompletions,
      AppConfig.keyDailyExpenseCounts: dailyExpenseCounts,
      AppConfig.keyDailyQuestCounts: dailyQuestCounts,
    };
  }

  void _applyStateData(Map<String, dynamic> data) {
    if (data[AppConfig.keyCategories] is List) {
      categories = (data[AppConfig.keyCategories] as List)
          .map((item) => Category.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    if (data[AppConfig.keyExpenses] is List) {
      expenses = (data[AppConfig.keyExpenses] as List)
          .map((item) => Expense.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      expenses.sort((a, b) => _expenseSortDate(b).compareTo(_expenseSortDate(a)));
    }
    if (data[AppConfig.keyBudgets] is List) {
      budgets = (data[AppConfig.keyBudgets] as List)
          .map((item) => Budget.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    if (data[AppConfig.keyProfile] is Map) {
      profile = Profile.fromJson(Map<String, dynamic>.from(data[AppConfig.keyProfile]));
    }
    if (data[AppConfig.keyQuestProgress] is Map) {
      questCompletions = Map<String, List<String>>.fromEntries(
        (data[AppConfig.keyQuestProgress] as Map).entries.map(
          (entry) => MapEntry(entry.key as String, List<String>.from(entry.value as List)),
        ),
      );
    }
    if (data[AppConfig.keyDailyExpenseCounts] is Map) {
      dailyExpenseCounts = (data[AppConfig.keyDailyExpenseCounts] as Map).map(
        (key, value) => MapEntry(key as String, value as int),
      );
    }
    if (data[AppConfig.keyDailyQuestCounts] is Map) {
      dailyQuestCounts = (data[AppConfig.keyDailyQuestCounts] as Map).map(
        (key, value) => MapEntry(key as String, value as int),
      );
    }
    _persist();
  }

  Future<void> _persistSyncMeta() async {
    await _storage.writeString(AppConfig.keySyncEmail, _syncEmail ?? '');
    await _storage.writeString(
      AppConfig.keyLastSyncTime,
      _lastSyncTime?.toIso8601String() ?? '',
    );
  }

  Future<void> pushToCloud() async {
    final service = _supabaseService;
    if (service == null || !service.isSignedIn) return;

    _syncStatus = SyncStatus.syncing;
    notifyListeners();

    try {
      final appId = await service.getApplicationId();
      if (appId == null) return;

      await service.pushPreferences(appId, settings.toJson());
      await service.pushAppData(appId, 'state', _buildStateData());

      _lastSyncTime = DateTime.now();
      _syncEmail = service.currentUser?.email;
      _syncStatus = SyncStatus.synced;
      await _persistSyncMeta();
    } catch (_) {
      _syncStatus = SyncStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> pullFromCloud() async {
    final service = _supabaseService;
    if (service == null || !service.isSignedIn) return;

    _syncStatus = SyncStatus.syncing;
    notifyListeners();

    try {
      final appId = await service.getApplicationId();
      if (appId == null) return;

      final prefsJson = await service.pullPreferences(appId);
      if (prefsJson != null) {
        settings = Settings.fromJson(prefsJson);
      }

      final stateData = await service.pullAppData(appId, 'state');
      if (stateData != null) {
        _applyStateData(stateData);
      }

      _lastSyncTime = DateTime.now();
      _syncEmail = service.currentUser?.email;
      _syncStatus = SyncStatus.synced;
      await _persistSyncMeta();
      await _syncReminders();
      await _syncExpenseReminders();
    } catch (_) {
      _syncStatus = SyncStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> hasCloudData() async {
    final service = _supabaseService;
    if (service == null || !service.isSignedIn) return false;

    final appId = await service.getApplicationId();
    if (appId == null) return false;

    return service.hasCloudData(appId);
  }

  Future<void> registerAppLink() async {
    final service = _supabaseService;
    if (service == null || !service.isSignedIn) return;

    final appId = await service.getApplicationId();
    if (appId == null) return;

    await service.registerAppLink(appId);
    _syncEmail = service.currentUser?.email;
    await _persistSyncMeta();
  }

  Future<void> clearSyncState() async {
    _syncStatus = SyncStatus.idle;
    _lastSyncTime = null;
    _syncEmail = null;
    await _storage.writeString(AppConfig.keySyncEmail, '');
    await _storage.writeString(AppConfig.keyLastSyncTime, '');
    notifyListeners();
  }
}
