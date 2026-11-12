import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/viewmodels/dashboard_viewmodel.dart';
import 'package:pockit/models/currency.dart';

import 'helpers/dashboard_fixture.dart';

void main() {
  test(
    'totals use purchase month and fixed usd conversions across all categories',
    () async {
      final fixture = DashboardFixture();
      await fixture.initialize(
        budgetMinor: 10000,
        values: [
          summaryExpense('usd', DateTime(2026, 11, 1), 2000),
          summaryExpense(
            'jpy',
            DateTime(2026, 11, 30, 23, 59),
            1450,
            currency: Currency.jpy,
            category: 'Travel',
          ),
          summaryExpense('october', DateTime(2026, 10, 31, 23, 59), 9000),
          summaryExpense('december', DateTime(2026, 12, 1), 7000),
          summaryExpense('last year', DateTime(2025, 11, 1), 5000),
        ],
      );
      addTearDown(fixture.dispose);
      expect(fixture.model.state.spentMinor, 3450);
      expect(fixture.model.state.expenseCount, 2);
      expect(fixture.model.state.remainingMinor, 6550);
      fixture.expenses.setFilter('Food');
      expect(fixture.model.state.spentMinor, 3450);
      fixture.model.previousMonth();
      expect(fixture.model.state.spentMinor, 9000);
      fixture.model.nextMonth();
      fixture.model.nextMonth();
      fixture.model.nextMonth();
      expect(fixture.model.state.month, DateTime(2027, 1));
      expect(fixture.model.state.spentMinor, 0);
    },
  );
  test(
    'remote changes and budget updates refresh the selected summary',
    () async {
      final fixture = DashboardFixture();
      await fixture.initialize(budgetMinor: 10000);
      addTearDown(fixture.dispose);
      fixture.repository.remoteUpdate([
        summaryExpense('remote', DateTime(2026, 11), 12000),
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(fixture.model.state.remainingMinor, -2000);
      await fixture.budgets.save(15000);
      await Future<void>.delayed(Duration.zero);
      expect(fixture.model.state.remainingMinor, 3000);
      fixture.model.currentMonth();
      expect(
        fixture.model.state.month,
        DateTime(DateTime.now().year, DateTime.now().month),
      );
    },
  );
  test(
    'missing budget and failed loads do not produce a remaining balance',
    () async {
      final fixture = DashboardFixture();
      await fixture.initialize(expenseFailure: true, budgetMinor: 10000);
      addTearDown(fixture.dispose);
      expect(fixture.model.state.expensesError, isNotNull);
      expect(fixture.model.state.remainingMinor, isNull);
      fixture.repository.fail = false;
      await fixture.model.retryExpenses();
      expect(fixture.model.state.expensesError, isNull);
      expect(fixture.model.state.remainingMinor, 10000);
      final noBudget = DashboardFixture();
      await noBudget.initialize();
      addTearDown(noBudget.dispose);
      expect(noBudget.model.state.budgetMinor, isNull);
      expect(noBudget.model.state.remainingMinor, isNull);
    },
  );
  test('budget usage preserves overages and stays unavailable for missing or failed data', () {
    DashboardState snapshot(
      int spent,
      int? budget, {
      bool loading = false,
      String? error,
    }) => DashboardState(
      month: DateTime(2026, 11),
      spentMinor: spent,
      expenseCount: 1,
      budgetMinor: budget,
      expensesLoading: loading,
      budgetLoading: false,
      expensesError: error,
    );
    expect(snapshot(0, 10000).budgetUsage, 0);
    expect(snapshot(5000, 10000).budgetUsage, 0.5);
    expect(snapshot(10000, 10000).budgetUsage, 1);
    expect(snapshot(15000, 10000).budgetUsage, 1.5);
    expect(snapshot(5000, null).budgetUsage, isNull);
    expect(snapshot(5000, 0).budgetUsage, isNull);
    expect(snapshot(5000, 10000, loading: true).budgetUsage, isNull);
    expect(snapshot(5000, 10000, error: 'unavailable').budgetUsage, isNull);
  });
}
