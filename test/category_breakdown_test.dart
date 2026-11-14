import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/models/category_spending.dart';
import 'package:pockit/widgets/category_breakdown.dart';

void main() {
  testWidgets(
    'categories show readable totals percentages and screen reader labels',
    (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryBreakdown(
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
          ),
        ),
      );
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('75.00 USD'), findsOneWidget);
      expect(find.text('75.0% of spending · 2 expenses'), findsOneWidget);
      expect(find.text('25.0% of spending · 1 expense'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Food, 75.00 USD, 75.0 percent of spending, 2 expenses',
        ),
        findsOneWidget,
      );
      handle.dispose();
    },
  );
  testWidgets('empty and narrow layouts work with larger text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CategoryBreakdown(categories: [])),
      ),
    );
    expect(find.text('No expenses for this month yet.'), findsOneWidget);
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CategoryBreakdown(
                  categories: [
                    CategorySpending(
                      category: 'Transportation',
                      amountUsdMinor: 100000000,
                      expenseCount: 10,
                      share: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('1000000.00 USD'), findsOneWidget);
  });
}
