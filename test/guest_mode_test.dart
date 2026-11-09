import 'package:pockit/repositories/budget_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/app.dart';

import 'helpers/fake_auth_service.dart';
import 'helpers/memory_expense_repository.dart';

void main() {
  testWidgets(
    'guests can add expenses without cloud storage and return from sign in',
    (tester) async {
      var cloudRequests = 0;
      Widget app(Key key) => PockitApp(
        budgetRepositoryFactory: (_) => MemoryBudgetRepository(),
        key: key,
        authService: FakeAuthService(account: null),
        expenseRepositoryFactory: (_) {
          cloudRequests++;
          return MemoryExpenseRepository();
        },
      );
      await tester.pumpWidget(app(const ValueKey('first-session')));
      await tester.pumpAndSettle();
      expect(find.text('Your money, wherever you go.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('signInButton')));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add expense'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '15');
      await tester.enterText(find.byType(TextFormField).last, 'Guest lunch');
      await tester.scrollUntilVisible(
        find.text('Save expense'),
        150,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save expense'));
      await tester.pumpAndSettle();
      expect(find.text('Guest lunch'), findsOneWidget);
      expect(cloudRequests, 0);
      await tester.pumpWidget(app(const ValueKey('new-session')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();
      expect(find.text('Guest lunch'), findsNothing);
      expect(
        find.text('No expenses yet. Add your first purchase to get started.'),
        findsOneWidget,
      );
      expect(cloudRequests, 0);
    },
  );
}
