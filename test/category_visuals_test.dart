import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/core/category_style.dart';
import 'package:pockit/models/category_spending.dart';
import 'package:pockit/models/currency.dart';
import 'package:pockit/models/expense.dart';
import 'package:pockit/widgets/category_breakdown.dart';
import 'package:pockit/widgets/expense_card.dart';

void main() {
  test('every supported category has a distinct stable color', () {
    expect(
      expenseCategories
          .map((category) => CategoryStyle.color(category).toARGB32())
          .toSet()
          .length,
      expenseCategories.length,
    );
    expect(CategoryStyle.color('unknown'), CategoryStyle.color('Other'));
  });
  testWidgets(
    'ring shows spending without a budget and card accents match its legend',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const CategoryBreakdown(
                    categories: [
                      CategorySpending(
                        category: 'Food',
                        amountUsdMinor: 7500,
                        expenseCount: 2,
                        share: 0.75,
                      ),
                      CategorySpending(
                        category: 'Travel',
                        amountUsdMinor: 2500,
                        expenseCount: 1,
                        share: 0.25,
                      ),
                    ],
                  ),
                  ExpenseCard(
                    expense: Expense(
                      id: 'food',
                      amountMinor: 7500,
                      currency: Currency.usd,
                      amountUsdMinor: 7500,
                      exchangeRate: 1,
                      rateDate: DateTime(2026),
                      category: 'Food',
                      description: 'Lunch',
                      date: DateTime(2026),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const Key('categoryDonut')), findsOneWidget);
      expect(find.text('100.00'), findsOneWidget);
      final dot = tester.widget<Container>(
        find.byKey(const ValueKey('categoryColor-Food')),
      );
      expect(
        (dot.decoration as BoxDecoration).color,
        CategoryStyle.color('Food'),
      );
      final card = tester.widget<Card>(
        find.descendant(
          of: find.byType(ExpenseCard),
          matching: find.byType(Card),
        ),
      );
      expect(card.color, isNull);
      final icon = tester.widget<Icon>(find.byIcon(Icons.restaurant_outlined));
      expect(icon.color, CategoryStyle.color('Food'));
    },
  );
  testWidgets('empty and rounded zero totals show a neutral ring', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CategoryBreakdown(categories: [])),
      ),
    );
    expect(find.byKey(const Key('categoryDonut')), findsOneWidget);
    expect(find.text('No spending\nyet'), findsOneWidget);
    expect(find.text('No expenses for this month yet.'), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CategoryBreakdown(
            categories: [
              CategorySpending(
                category: 'Food',
                amountUsdMinor: 0,
                expenseCount: 1,
                share: 0,
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('0.00'), findsOneWidget);
    expect(find.text('0.0% of spending · 1 expense'), findsOneWidget);
  });
}
