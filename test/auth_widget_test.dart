import 'package:pockit/repositories/budget_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/app.dart';
import 'package:pockit/models/account.dart';
import 'package:pockit/models/currency.dart';
import 'package:pockit/models/expense.dart';

import 'helpers/fake_auth_service.dart';
import 'helpers/memory_expense_repository.dart';

void main() {
  testWidgets('registration validates and enters the authenticated app', (
    tester,
  ) async {
    final auth = FakeAuthService(account: null);
    await tester.pumpWidget(
      PockitApp(
        budgetRepositoryFactory: (_) => MemoryBudgetRepository(),
        authService: auth,
        expenseRepositoryFactory: (_) => MemoryExpenseRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('signInButton')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('New here? Create an account'),
      120,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('authEmail')),
      'new@example.com',
    );
    await tester.enterText(find.byKey(const Key('authPassword')), 'secret123');
    await tester.ensureVisible(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Your money, wherever you go.'), findsOneWidget);
    expect(auth.registrationCalls, 1);
  });

  testWidgets('account changes clear open forms and previous expenses', (
    tester,
  ) async {
    final auth = FakeAuthService();
    final first = MemoryExpenseRepository();
    first.expenses = [
      Expense(
        id: 'private-expense',
        amountMinor: 100,
        currency: Currency.usd,
        amountUsdMinor: 100,
        exchangeRate: 1,
        rateDate: DateTime(2026),
        category: 'Food',
        description: 'Private purchase',
        date: DateTime(2026),
      ),
    ];
    final second = MemoryExpenseRepository();
    await tester.pumpWidget(
      PockitApp(
        budgetRepositoryFactory: (_) => MemoryBudgetRepository(),
        authService: auth,
        expenseRepositoryFactory: (id) => id == 'test-user' ? first : second,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    expect(find.text('Private purchase'), findsOneWidget);
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    expect(find.text('Expense amount'), findsOneWidget);
    auth.emit(null);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('signInButton')), findsOneWidget);
    expect(find.text('Your money, wherever you go.'), findsOneWidget);
    expect(find.text('Expense amount'), findsNothing);
    expect(first.listeners, 0);
    auth.emit(const Account(id: 'second-user', email: 'second@example.com'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    expect(find.text('Private purchase'), findsNothing);
    expect(
      find.text('No expenses yet. Add your first purchase to get started.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('second@example.com'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('signInButton')), findsOneWidget);
    expect(find.text('Your money, wherever you go.'), findsOneWidget);
    expect(second.listeners, 0);
  });
  testWidgets('google button works with empty email and password', (
    tester,
  ) async {
    final auth = FakeAuthService(account: null);
    await tester.pumpWidget(
      PockitApp(
        budgetRepositoryFactory: (_) => MemoryBudgetRepository(),
        authService: auth,
        expenseRepositoryFactory: (_) => MemoryExpenseRepository(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('signInButton')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('googleSignIn')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('googleSignIn')));
    await tester.pumpAndSettle();
    expect(auth.googleCalls, 1);
    expect(find.text('Your money, wherever you go.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsNothing);
  });
}
