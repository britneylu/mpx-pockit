import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pockit/models/category_spending.dart';
import 'package:pockit/viewmodels/dashboard_viewmodel.dart';
import 'package:pockit/views/home_screen.dart';
import 'package:pockit/widgets/category_donut.dart';

import 'helpers/dashboard_fixture.dart';

void main() {
  testWidgets(
    'ring segments select categories and the center does not filter',
    (tester) async {
      final selections = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDonut(
              categories: const [
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
              onCategorySelected: selections.add,
            ),
          ),
        ),
      );
      final chart = find.byKey(const Key('categoryDonut'));
      final origin = tester.getTopLeft(chart);
      final size = tester.getSize(chart);
      await tester.tapAt(origin + Offset(size.width * 0.94, size.height * 0.5));
      expect(selections.last, 'Food');
      await tester.tapAt(
        origin + Offset(size.width * 0.185, size.height * 0.185),
      );
      expect(selections.last, 'Travel');
      await tester.tapAt(tester.getCenter(chart));
      expect(selections.length, 2);
    },
  );
  testWidgets(
    'tapping a category shows purchases and clear restores category rows',
    (tester) async {
      final fixture = DashboardFixture();
      await fixture.initialize(
        values: [
          summaryExpense('lunch', DateTime(2026, 11, 1), 1000),
          summaryExpense('dinner', DateTime(2026, 11, 2), 2000),
          summaryExpense(
            'train',
            DateTime(2026, 11, 3),
            3000,
            category: 'Travel',
          ),
          summaryExpense('last month', DateTime(2026, 10), 4000),
        ],
      );
      addTearDown(fixture.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<DashboardViewModel>.value(
          value: fixture.model,
          child: MaterialApp(
            home: Scaffold(
              body: HomeScreen(
                onExpenses: () {},
                onSettings: () {},
                onConvert: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('categoryFilter-Food')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('categoryFilter-Food')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('monthlyExpenseListTitle')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Food expenses'), findsOneWidget);
      expect(find.byKey(const ValueKey('categoryFilter-Travel')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('categoryBreakdownCard')),
          matching: find.byKey(const ValueKey('monthlyExpense-lunch')),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('monthlyExpense-lunch')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('monthlyExpense-dinner')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('monthlyExpense-train')), findsNothing);
      expect(
        find.byKey(const ValueKey('monthlyExpense-last month')),
        findsNothing,
      );
      await tester.tap(find.byTooltip('Clear category filter'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('monthlyExpense-train')), findsNothing);
      expect(find.text('This month’s expenses'), findsNothing);
      expect(find.byKey(const ValueKey('categoryFilter-Food')), findsOneWidget);
      expect(fixture.model.state.spentMinor, 6000);
    },
  );
}
