import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/app.dart';
import 'package:pockit/repositories/budget_repository.dart';

import 'helpers/fake_auth_service.dart';
import 'helpers/memory_expense_repository.dart';

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    150,
    scrollable: find
        .descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('guest can validate and update a monthly budget', (tester) async {
    await tester.pumpWidget(
      PockitApp(
        authService: FakeAuthService(account: null),
        expenseRepositoryFactory: (_) => MemoryExpenseRepository(),
        budgetRepositoryFactory: (_) => MemoryBudgetRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Save budget'));
    await tester.tap(find.text('Save budget'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a positive amount.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('monthlyBudget')), '1200.50');
    await reveal(tester, find.text('Save budget'));
    await tester.tap(find.text('Save budget'));
    await tester.pumpAndSettle();
    expect(find.text('Budget set for this session'), findsOneWidget);
    expect(find.text('Current budget: 1200.50 USD'), findsOneWidget);
  });
  testWidgets('account budget loads into the field and saves changes', (
    tester,
  ) async {
    final repo = MemoryBudgetRepository();
    await repo.save(90000);
    await tester.pumpWidget(
      PockitApp(
        authService: FakeAuthService(),
        expenseRepositoryFactory: (_) => MemoryExpenseRepository(),
        budgetRepositoryFactory: (_) => repo,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await reveal(tester, find.byKey(const Key('monthlyBudget')));
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('monthlyBudget')))
          .controller!
          .text,
      '900.00',
    );
    await tester.enterText(find.byKey(const Key('monthlyBudget')), '950');
    await reveal(tester, find.text('Save budget'));
    await tester.tap(find.text('Save budget'));
    await tester.pumpAndSettle();
    expect(repo.amountMinor, 95000);
    expect(find.text('Monthly budget saved'), findsOneWidget);
  });
}
