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
  test(
    'category totals use saved usd amounts and stable descending order',
    () async {
      final fixture = DashboardFixture();
      await fixture.initialize(
        values: [
          summaryExpense('food one', DateTime(2026, 11), 1250),
          summaryExpense(
            'food two',
            DateTime(2026, 11),
            750,
            currency: Currency.jpy,
          ),
          summaryExpense(
            'travel',
            DateTime(2026, 11),
            2000,
            category: 'Travel',
          ),
          summaryExpense(
            'shopping',
            DateTime(2026, 11),
            1000,
            category: 'Shopping',
          ),
          summaryExpense('outside', DateTime(2026, 10), 40000),
        ],
      );
      addTearDown(fixture.dispose);
      final categories = fixture.model.state.categories;
      expect(categories.map((item) => item.category), [
        'Food',
        'Travel',
        'Shopping',
      ]);
      expect(categories.map((item) => item.amountUsdMinor), [2000, 2000, 1000]);
      expect(categories.first.expenseCount, 2);
      expect(categories.first.share, 0.4);
      expect(
        categories.fold(0, (sum, item) => sum + item.amountUsdMinor),
        fixture.model.state.spentMinor,
      );
      expect(() => categories.clear(), throwsUnsupportedError);
      fixture.expenses.setFilter('Travel');
      expect(fixture.model.state.categories.length, 3);
      fixture.model.previousMonth();
      expect(fixture.model.state.categories.single.amountUsdMinor, 40000);
    },
  );
  test('category totals update after remote edits and handle zero or empty spending', () async {
    final fixture = DashboardFixture();
    await fixture.initialize();
    addTearDown(fixture.dispose);
    expect(fixture.model.state.categories, isEmpty);
    fixture.repository.remoteUpdate([
      summaryExpense('rounded', DateTime(2026, 11), 0),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(fixture.model.state.categories.single.share, 0);
    expect(fixture.model.state.categories.single.expenseCount, 1);
    fixture.repository.remoteUpdate([
      summaryExpense('edited', DateTime(2026, 11), 500, category: 'Bills'),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(fixture.model.state.categories.single.category, 'Bills');
    expect(fixture.model.state.categories.single.share, 1);
    fixture.repository.remoteUpdate([]);
    await Future<void>.delayed(Duration.zero);
    expect(fixture.model.state.categories, isEmpty);
  });
  test('category selection filters every monthly expense without changing summary totals', () async {
    final fixture = DashboardFixture();
    await fixture.initialize(
      values: [
        summaryExpense('food older', DateTime(2026, 11, 1), 1000),
        summaryExpense(
          'travel',
          DateTime(2026, 11, 3),
          2000,
          category: 'Travel',
        ),
        summaryExpense('food newer', DateTime(2026, 11, 2), 500),
        summaryExpense('other month', DateTime(2026, 10, 1), 10000),
      ],
    );
    addTearDown(fixture.dispose);
    fixture.model.selectCategory('Food');
    expect(fixture.model.state.visibleExpenses.map((e) => e.id), [
      'food newer',
      'food older',
    ]);
    expect(fixture.model.state.spentMinor, 3500);
    expect(fixture.model.state.categories.length, 2);
    expect(fixture.expenses.state.filter, isNull);
    expect(
      () => fixture.model.state.visibleExpenses.clear(),
      throwsUnsupportedError,
    );
    fixture.model.selectCategory('Food');
    expect(fixture.model.state.visibleExpenses.length, 3);
    fixture.model.selectCategory('Travel');
    fixture.repository.remoteUpdate([
      summaryExpense('new travel', DateTime(2026, 11), 800, category: 'Travel'),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(fixture.model.state.visibleExpenses.single.id, 'new travel');
    fixture.model.previousMonth();
    expect(fixture.model.state.selectedCategory, isNull);
    expect(fixture.model.state.visibleExpenses, isEmpty);
  });
}
