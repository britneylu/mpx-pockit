import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/core/money.dart';
import 'package:pockit/models/currency.dart';
import 'package:pockit/models/expense.dart';
import 'package:pockit/models/exchange_rate.dart';
import 'package:pockit/services/currency_service.dart';
import 'package:pockit/viewmodels/expenses_viewmodel.dart';

import 'helpers/memory_expense_repository.dart';

class RateService implements CurrencyService {
  int calls = 0;
  bool fail = false;
  @override
  Future<ExchangeRate> fetchRate(Currency from, Currency to) async {
    calls++;
    if (fail) throw Exception('Offline');
    return ExchangeRate(rate: 0.006667, date: DateTime(2026, 11, 3));
  }
}

void main() {
  test('minor units and half-up conversion are decimal safe', () {
    expect(parseMinor('0.29', Currency.usd), 29);
    expect(parseMinor('1500', Currency.jpy), 1500);
    expect(() => parseMinor('1.5', Currency.jpy), throwsFormatException);
    expect(convertToUsdMinor(1500, Currency.jpy, 0.006667), 1000);
    expect(convertToUsdMinor(1, Currency.usd, 0.5), 1);
    expect(formatMinor(29, Currency.usd), '0.29');
  });
  test(
    'save, edit preservation, recalculate, delete, undo, and reload',
    () async {
      final repo = MemoryExpenseRepository();
      final service = RateService();
      final model = ExpensesViewModel(repo, service);
      addTearDown(model.dispose);
      await model.load();
      final date = DateTime(2026, 1, 1);
      expect(
        await model.saveExpense(
          amount: '1500',
          currency: Currency.jpy,
          category: 'Food',
          description: 'Lunch',
          date: date,
        ),
        isTrue,
      );
      final original = model.state.expenses.single;
      expect(original.amountUsdMinor, 1000);
      expect(Expense.fromJson(original.toJson()).toJson(), original.toJson());
      service.fail = true;
      expect(
        await model.saveExpense(
          original: original,
          amount: '1500',
          currency: Currency.jpy,
          category: 'Travel',
          description: 'Updated',
          date: date,
        ),
        isTrue,
      );
      expect(service.calls, 1);
      expect(model.state.expenses.single.exchangeRate, original.exchangeRate);
      expect(
        await model.saveExpense(
          original: model.state.expenses.single,
          amount: '1600',
          currency: Currency.jpy,
          category: 'Travel',
          description: 'Updated',
          date: date,
        ),
        isFalse,
      );
      expect(model.state.expenses.single.amountMinor, 1500);
      service.fail = false;
      expect(
        await model.saveExpense(
          original: model.state.expenses.single,
          amount: '1600',
          currency: Currency.jpy,
          category: 'Travel',
          description: 'Updated',
          date: date,
        ),
        isTrue,
      );
      final saved = model.state.expenses.single;
      model.setFilter('Food');
      expect(model.state.visible, isEmpty);
      expect(await model.delete(saved), isTrue);
      expect(model.state.expenses, isEmpty);
      expect(await model.restore(saved), isTrue);
      final reloaded = ExpensesViewModel(repo, service);
      addTearDown(reloaded.dispose);
      await reloaded.load();
      expect(reloaded.state.expenses.single.amountMinor, 1600);
    },
  );
  test(
    'storage failure preserves existing expenses and supports retry',
    () async {
      final repo = MemoryExpenseRepository();
      final service = RateService();
      final model = ExpensesViewModel(repo, service);
      addTearDown(model.dispose);
      await model.load();
      await model.saveExpense(
        amount: '12.00',
        currency: Currency.usd,
        category: 'Food',
        description: '',
        date: DateTime(2026),
      );
      repo.fail = true;
      expect(await model.delete(model.state.expenses.single), isFalse);
      expect(model.state.expenses.length, 1);
      await model.load();
      expect(model.state.error, isNotNull);
      repo.fail = false;
      await model.load();
      expect(model.state.error, isNull);
      expect(model.state.expenses.length, 1);
    },
  );
  test(
    'remote expense updates flow into immutable state and stop after dispose',
    () async {
      final repo = MemoryExpenseRepository();
      final model = ExpensesViewModel(repo, RateService());
      await model.load();
      final expense = Expense(
        id: 'remote',
        amountMinor: 100,
        currency: Currency.usd,
        amountUsdMinor: 100,
        exchangeRate: 1,
        rateDate: DateTime(2026),
        category: 'Food',
        description: 'Other device',
        date: DateTime(2026),
      );
      repo.remoteUpdate([expense]);
      await Future<void>.delayed(Duration.zero);
      expect(model.state.expenses.single.id, 'remote');
      expect(() => model.state.expenses.clear(), throwsUnsupportedError);
      model.dispose();
      await Future<void>.delayed(Duration.zero);
      expect(repo.listeners, 0);
    },
  );
}
