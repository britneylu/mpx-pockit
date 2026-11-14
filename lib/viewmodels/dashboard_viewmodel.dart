import 'package:flutter/foundation.dart';

import '../models/category_spending.dart';
import '../models/expense.dart';

import 'budget_viewmodel.dart';
import 'expenses_viewmodel.dart';

// keep the selected month and its spending totals read only
@immutable
class DashboardState {
  DashboardState({
    required this.month,
    required this.spentMinor,
    required this.expenseCount,
    required this.budgetMinor,
    required this.expensesLoading,
    required this.budgetLoading,
    this.expensesError,
    this.budgetError,
    this.selectedCategory,
    List<Expense> monthlyExpenses = const [],
    List<CategorySpending> categories = const [],
  }) : categories = List.unmodifiable(categories),
       monthlyExpenses = List.unmodifiable(monthlyExpenses);
  final DateTime month;
  final int spentMinor;
  final int expenseCount;
  final int? budgetMinor;
  final bool expensesLoading;
  final bool budgetLoading;
  final String? expensesError;
  final String? budgetError;
  final List<CategorySpending> categories;
  final List<Expense> monthlyExpenses;
  final String? selectedCategory;
  List<Expense> get visibleExpenses => List.unmodifiable(
    monthlyExpenses.where(
      (expense) =>
          selectedCategory == null || expense.category == selectedCategory,
    ),
  );
  // keep usage above one when spending exceeds the budget
  double? get budgetUsage => remainingMinor == null || budgetMinor! <= 0
      ? null
      : spentMinor / budgetMinor!;

  int? get remainingMinor =>
      expensesLoading ||
          budgetLoading ||
          expensesError != null ||
          budgetError != null ||
          budgetMinor == null
      ? null
      : budgetMinor! - spentMinor;
}

// derive monthly totals from the existing expense and budget streams
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._expenses, this._budget, {DateTime? initialMonth}) {
    final date = initialMonth ?? DateTime.now();
    _month = DateTime(date.year, date.month);
    _state = _calculate();
    _expenses.addListener(_refresh);
    _budget.addListener(_refresh);
  }
  final ExpensesViewModel _expenses;
  final BudgetViewModel _budget;
  late DateTime _month;
  String? _selectedCategory;
  late DashboardState _state;
  DashboardState get state => _state;

  DashboardState _calculate() {
    final expenses = _expenses.state;
    final budget = _budget.state;
    // use purchase dates and fixed usd amounts rather than current rates
    final monthly =
        expenses.expenses
            .where(
              (expense) =>
                  expense.date.year == _month.year &&
                  expense.date.month == _month.month,
            )
            .toList()
          ..sort((a, b) {
            final order = b.date.compareTo(a.date);
            return order == 0 ? b.id.compareTo(a.id) : order;
          });
    final amounts = <String, int>{};
    final counts = <String, int>{};
    for (final expense in monthly) {
      amounts.update(
        expense.category,
        (amount) => amount + expense.amountUsdMinor,
        ifAbsent: () => expense.amountUsdMinor,
      );
      counts.update(expense.category, (count) => count + 1, ifAbsent: () => 1);
    }
    final total = amounts.values.fold(0, (sum, amount) => sum + amount);
    // sort largest totals first and use category names to break ties
    final categories =
        amounts.entries
            .map(
              (entry) => CategorySpending(
                category: entry.key,
                amountUsdMinor: entry.value,
                expenseCount: counts[entry.key]!,
                share: total == 0 ? 0 : entry.value / total,
              ),
            )
            .toList()
          ..sort((a, b) {
            final amountOrder = b.amountUsdMinor.compareTo(a.amountUsdMinor);
            return amountOrder == 0
                ? a.category.compareTo(b.category)
                : amountOrder;
          });
    return DashboardState(
      month: _month,
      spentMinor: total,
      categories: categories,
      monthlyExpenses: monthly,
      selectedCategory: _selectedCategory,
      expenseCount: monthly.length,
      budgetMinor: budget.amountMinor,
      expensesLoading: expenses.loading,
      budgetLoading: budget.loading || budget.transferring,
      expensesError: expenses.error,
      budgetError: budget.loadError ?? budget.transferError,
    );
  }

  void _refresh() {
    _state = _calculate();
    notifyListeners();
  }

  // selecting the same category again restores the full monthly list
  void selectCategory(String? category) {
    if (category != null && !expenseCategories.contains(category)) return;
    _selectedCategory = _selectedCategory == category ? null : category;
    _refresh();
  }

  // date construction handles year boundaries automatically
  void previousMonth() {
    _selectedCategory = null;
    _month = DateTime(_month.year, _month.month - 1);
    _refresh();
  }

  void nextMonth() {
    _selectedCategory = null;
    _month = DateTime(_month.year, _month.month + 1);
    _refresh();
  }

  void currentMonth() {
    _selectedCategory = null;
    final today = DateTime.now();
    _month = DateTime(today.year, today.month);
    _refresh();
  }

  Future<void> retryExpenses() => _expenses.load();
  Future<void> retryBudget() async {
    if (_budget.state.transferError != null) {
      await _budget.retryTransfer();
    } else {
      await _budget.reload();
    }
  }

  @override
  void dispose() {
    _expenses.removeListener(_refresh);
    _budget.removeListener(_refresh);
    super.dispose();
  }
}
