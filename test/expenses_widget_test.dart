import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/app.dart';

import 'helpers/memory_expense_repository.dart';
import 'helpers/fake_auth_service.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
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
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('expense form validates, saves, edits, deletes and undoes', (
    tester,
  ) async {
    final repo = MemoryExpenseRepository();
    await tester.pumpWidget(
      PockitApp(
        authService: FakeAuthService(),
        expenseRepositoryFactory: (_) => repo,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    expect(
      find.text('No expenses yet. Add your first purchase to get started.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Save expense'));
    expect(find.text('Enter a positive amount.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '12.50');
    await tester.enterText(find.byType(TextFormField).last, 'Coffee');
    await tapVisible(tester, find.text('Save expense'));
    expect(repo.expenses.single.amountUsdMinor, 1250);
    expect(find.text('Coffee'), findsOneWidget);
    await tapVisible(tester, find.text('Edit'));
    await tester.enterText(find.byType(TextFormField).last, 'Lunch');
    await tapVisible(tester, find.text('Save expense'));
    expect(repo.expenses.single.description, 'Lunch');
    await tester.ensureVisible(find.byType(Dismissible));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Dismissible), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(repo.expenses, isEmpty);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(repo.expenses.single.description, 'Lunch');
  });
}
