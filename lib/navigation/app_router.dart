import 'package:cheapcheap/models/category.dart';
import 'package:cheapcheap/models/expense.dart';
import 'package:cheapcheap/ui/category_form_screen.dart';
import 'package:cheapcheap/ui/current_stats_screen.dart';
import 'package:cheapcheap/ui/expense_detail_screen.dart';
import 'package:cheapcheap/ui/expense_form_screen.dart';
import 'package:cheapcheap/ui/monthly_stats_screen.dart';
import 'package:flutter/material.dart';

final class AppRoutes {
  static const monthlyStats = '/monthly-stats';
  static const currentStats = '/current-stats';
}

final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.monthlyStats:
        return _materialRoute(
          builder: (_) => const MonthlyStatsScreen(),
          settings: settings,
        );
      case AppRoutes.currentStats:
        return _materialRoute(
          builder: (_) => const CurrentStatsScreen(),
          settings: settings,
        );
      default:
        throw StateError('Unknown route: ${settings.name}');
    }
  }

  static Future<void> showMonthlyStats(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.monthlyStats);
  }

  static Future<void> showCurrentStats(BuildContext context) {
    return Navigator.of(context).pushNamed(AppRoutes.currentStats);
  }

  static Future<void> showExpenseForm(
    BuildContext context, {
    required DateTime initialMonth,
  }) {
    return Navigator.of(context).push(
      _materialRoute(
        builder: (_) => ExpenseFormScreen(initialMonth: initialMonth),
      ),
    );
  }

  static Future<void> showExpenseDetails(
    BuildContext context, {
    required Expense expense,
    bool initialSplitExpanded = false,
  }) {
    return Navigator.of(context).push(
      _materialRoute(
        builder: (_) => ExpenseDetailScreen(
          expense: expense,
          initialSplitExpanded: initialSplitExpanded,
        ),
      ),
    );
  }

  static Future<Category?> showCreateCategory(BuildContext context) {
    return Navigator.of(context).push<Category>(
      _materialRoute(builder: (_) => const CategoryFormScreen()),
    );
  }

  static Future<Category?> showEditCategory(
    BuildContext context, {
    required Category category,
  }) {
    return Navigator.of(context).push<Category>(
      _materialRoute(builder: (_) => CategoryFormScreen(category: category)),
    );
  }

  static Future<Category?> showCloneCategory(
    BuildContext context, {
    required Category category,
  }) {
    return Navigator.of(context).push<Category>(
      _materialRoute(
        builder: (_) => CategoryFormScreen(category: category, isClone: true),
      ),
    );
  }

  static MaterialPageRoute<T> _materialRoute<T>({
    required WidgetBuilder builder,
    RouteSettings? settings,
  }) {
    return MaterialPageRoute<T>(builder: builder, settings: settings);
  }
}
