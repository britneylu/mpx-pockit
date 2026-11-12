import 'package:flutter/foundation.dart';

import 'budget_viewmodel.dart';
import 'expenses_viewmodel.dart';

// keep the selected month and its spending totals read only
@immutable
class DashboardState {
  const DashboardState({
    required this.month,
    required this.spentMinor,
    required this.expenseCount,
    required this.budgetMinor,
    required this.expensesLoading,
    required this.budgetLoading,
    this.expensesError,
    this.budgetError,
  });
  final DateTime month;
  final int spentMinor;
  final int expenseCount;
  final int? budgetMinor;
  final bool expensesLoading;
  final bool budgetLoading;
  final String? expensesError;
  final String? budgetError;
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
  late DashboardState _state;
  DashboardState get state => _state;

  DashboardState _calculate() {
    final expenses = _expenses.state;
    final budget = _budget.state;
    // use purchase dates and fixed usd amounts rather than current rates
    final monthly = expenses.expenses.where(
      (expense) =>
          expense.date.year == _month.year &&
          expense.date.month == _month.month,
    );
    return DashboardState(
      month: _month,
      spentMinor: monthly.fold(
        0,
        (total, expense) => total + expense.amountUsdMinor,
      ),
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

  // date construction handles year boundaries automatically
  void previousMonth() {
    _month = DateTime(_month.year, _month.month - 1);
    _refresh();
  }

  void nextMonth() {
    _month = DateTime(_month.year, _month.month + 1);
    _refresh();
  }

  void currentMonth() {
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
