import 'package:pockit/repositories/budget_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/app.dart';
import 'package:pockit/models/currency.dart';
import 'package:pockit/models/exchange_rate.dart';
import 'package:pockit/services/currency_service.dart';

import 'helpers/memory_expense_repository.dart';
import 'helpers/fake_auth_service.dart';

class FakeCurrencyService implements CurrencyService {
  bool fail = false;
  @override
  Future<ExchangeRate> fetchRate(Currency from, Currency to) async {
    if (fail) throw Exception('Offline');
    return ExchangeRate(
      rate: from == Currency.usd ? 0.9 : 1.1,
      date: DateTime(2026, 11, 4),
    );
  }
}

Future<void> openConverter(
  WidgetTester tester,
  FakeCurrencyService service,
) async {
  await tester.pumpWidget(
    PockitApp(
      budgetRepositoryFactory: (_) => MemoryBudgetRepository(),
      currencyService: service,
      authService: FakeAuthService(),
      expenseRepositoryFactory: (_) => MemoryExpenseRepository(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Convert'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('navigation opens each tab', (tester) async {
    await tester.pumpWidget(
      PockitApp(
        budgetRepositoryFactory: (_) => MemoryBudgetRepository(),
        currencyService: FakeCurrencyService(),
        authService: FakeAuthService(),
        expenseRepositoryFactory: (_) => MemoryExpenseRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your money, wherever you go.'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    expect(find.text('Every purchase, in perspective.'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Make room for your goals.'), findsOneWidget);
  });

  testWidgets('converter calculates and swaps currencies', (tester) async {
    await openConverter(tester, FakeCurrencyService());
    await tester.enterText(find.byKey(const Key('amount')), '100');
    await tester.pump();
    expect(find.text('90.00 EUR'), findsOneWidget);
    await tester.tap(find.byTooltip('Swap currencies'));
    await tester.pumpAndSettle();
    expect(find.text('110.00 USD'), findsOneWidget);
  });

  testWidgets('invalid amount has feedback and no result', (tester) async {
    await openConverter(tester, FakeCurrencyService());
    await tester.enterText(find.byKey(const Key('amount')), '-10');
    await tester.pump();
    expect(
      find.text('Enter a positive number, such as 25.50.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('conversionResult')), findsNothing);
  });

  testWidgets('failed rate can be retried', (tester) async {
    final service = FakeCurrencyService()..fail = true;
    await openConverter(tester, service);
    expect(find.text('Retry'), findsOneWidget);
    service.fail = false;
    await tester.ensureVisible(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsNothing);
    expect(find.text('Rate date: 2026-11-04'), findsOneWidget);
  });

  testWidgets('small screen and large text remain scrollable', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: PockitApp(
          budgetRepositoryFactory: (_) => MemoryBudgetRepository(),
          currencyService: FakeCurrencyService(),
          authService: FakeAuthService(),
          expenseRepositoryFactory: (_) => MemoryExpenseRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Convert'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
