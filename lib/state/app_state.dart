import 'dart:convert';
import 'dart:math';

import 'package:cheapcheap/data/defaults.dart';
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
import 'package:cheapcheap/utils/date_utils.dart';
import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  AppState._(this._storage);

  final StorageService _storage;

  List<Category> categories = [];
  List<Expense> expenses = [];
  Profile profile = Profile();
  Settings settings = Settings();
  Map<String, List<String>> questCompletions = {};
  Map<String, int> dailyExpenseCounts = {};
  Map<String, int> dailyQuestCounts = {};
  String? lastQuestCompletedId;
  String? lastQuestCompletedName;
  int questCompletionTick = 0;

  static Future<AppState> create() async {
    final storage = await StorageService.create();
    final state = AppState._(storage);
    await state._load();
    return state;
  }

  Future<void> _load() async {
    final categoryList = _storage.readJsonList('categories');
    categories = categoryList == null
        ? [...defaultCategories]
        : categoryList
              .map((item) => Category.fromJson(Map<String, dynamic>.from(item)))
              .toList();

    final expenseList = _storage.readJsonList('expenses');
    expenses = expenseList == null
        ? []
        : expenseList
              .map((item) => Expense.fromJson(Map<String, dynamic>.from(item)))
              .toList();
    expenses.sort((a, b) => _expenseSortDate(b).compareTo(_expenseSortDate(a)));

    final profileJson = _storage.readJson('profile');
    profile = profileJson == null ? Profile() : Profile.fromJson(profileJson);

    final settingsJson = _storage.readJson('settings');
    settings = settingsJson == null
        ? Settings()
        : Settings.fromJson(settingsJson);
    await _syncReminders();

    final questJson = _storage.readJson('questProgress');
    if (questJson != null) {
      questCompletions = Map<String, List<String>>.fromEntries(
        questJson.entries.map(
          (entry) =>
              MapEntry(entry.key, List<String>.from(entry.value as List)),
        ),
      );
    }

    final expenseCountJson = _storage.readJson('dailyExpenseCounts');
    if (expenseCountJson != null) {
      dailyExpenseCounts = expenseCountJson.map(
        (key, value) => MapEntry(key, value as int),
      );
    }

    final questCountJson = _storage.readJson('dailyQuestCounts');
    if (questCountJson != null) {
      dailyQuestCounts = questCountJson.map(
        (key, value) => MapEntry(key, value as int),
      );
    }
  }

  Future<void> _persist() async {
    await _storage.writeJsonList(
      'categories',
      categories.map((category) => category.toJson()).toList(),
    );
    await _storage.writeJsonList(
      'expenses',
      expenses.map((expense) => expense.toJson()).toList(),
    );
    await _storage.writeJson('profile', profile.toJson());
    await _storage.writeJson('settings', settings.toJson());
    await _storage.writeJson('questProgress', questCompletions);
    await _storage.writeJson('dailyExpenseCounts', dailyExpenseCounts);
    await _storage.writeJson('dailyQuestCounts', dailyQuestCounts);
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

  void addExpense(Expense expense) {
    expenses = [...expenses, expense];
    expenses.sort((a, b) => _expenseSortDate(b).compareTo(_expenseSortDate(a)));
    _incrementDailyExpense(expense.date);
    _applyStatImpact(expense);
    _persist();
    notifyListeners();
    _tryCompleteQuest('quest_add_expense');
    if (_dailyExpenseCount(expense.date) >= 3) {
      _tryCompleteQuest('quest_add_3_expenses');
    }
    if (expense.recurrence != null &&
        expense.recurrence!.type != RecurrenceType.none) {
      _tryCompleteQuest('quest_add_recurrent');
    }
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

  void updateExpense(Expense expense) {
    expenses = expenses
        .map((existing) => existing.id == expense.id ? expense : existing)
        .toList();
    expenses.sort((a, b) => _expenseSortDate(b).compareTo(_expenseSortDate(a)));
    _persist();
    notifyListeners();
  }

  void removeExpense(String id) {
    expenses = expenses.where((expense) => expense.id != id).toList();
    _persist();
    notifyListeners();
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
      'categories': categories.map((category) => category.toJson()).toList(),
      'expenses': expenses.map((expense) => expense.toJson()).toList(),
      'profile': profile.toJson(),
      'settings': settings.toJson(),
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
}
