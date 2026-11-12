import 'package:pockit/models/currency.dart';
import 'package:pockit/models/exchange_rate.dart';
import 'package:pockit/models/expense.dart';
import 'package:pockit/repositories/budget_repository.dart';
import 'package:pockit/services/currency_service.dart';
import 'package:pockit/viewmodels/auth_viewmodel.dart';
import 'package:pockit/viewmodels/budget_viewmodel.dart';
import 'package:pockit/viewmodels/dashboard_viewmodel.dart';
import 'package:pockit/viewmodels/expenses_viewmodel.dart';

import 'fake_auth_service.dart';
import 'memory_expense_repository.dart';

class _UnusedRates implements CurrencyService {
  @override
  Future<ExchangeRate> fetchRate(Currency from, Currency to) =>
      throw StateError('Summary must use saved conversions');
}

Expense summaryExpense(
  String id,
  DateTime date,
  int usdMinor, {
  Currency currency = Currency.usd,
  String category = 'Food',
}) => Expense(
  id: id,
  amountMinor: 1500,
  currency: currency,
  amountUsdMinor: usdMinor,
  exchangeRate: 0.01,
  rateDate: date,
  category: category,
  description: id,
  date: date,
);

class DashboardFixture {
  final repository = MemoryExpenseRepository();
  final budgets = MemoryBudgetRepository();
  late AuthViewModel auth;
  late BudgetViewModel budget;
  late ExpensesViewModel expenses;
  late DashboardViewModel model;
  Future<void> initialize({
    List<Expense> values = const [],
    int? budgetMinor,
    bool expenseFailure = false,
  }) async {
    repository.expenses = values;
    repository.fail = expenseFailure;
    if (budgetMinor != null) await budgets.save(budgetMinor);
    auth = AuthViewModel(FakeAuthService());
    budget = BudgetViewModel(auth, (_) => budgets);
    expenses = ExpensesViewModel(repository, _UnusedRates());
    await expenses.load();
    await Future<void>.value();
    model = DashboardViewModel(
      expenses,
      budget,
      initialMonth: DateTime(2026, 11),
    );
  }

  void dispose() {
    model.dispose();
    expenses.dispose();
    budget.dispose();
    auth.dispose();
  }
}
