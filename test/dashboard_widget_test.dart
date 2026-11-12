import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pockit/views/home_screen.dart';
import 'package:pockit/viewmodels/dashboard_viewmodel.dart';

import 'helpers/dashboard_fixture.dart';

void main() {
  testWidgets('home displays totals and changes months without mixing data', (
    tester,
  ) async {
    final fixture = DashboardFixture();
    await fixture.initialize(
      budgetMinor: 10000,
      values: [summaryExpense('lunch', DateTime(2026, 11), 12500)],
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
    expect(find.text('November 2026'), findsOneWidget);
    expect(find.text('125.00 USD'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('monthlyRemaining')));
    await tester.pumpAndSettle();
    expect(find.text('Over budget by'), findsOneWidget);
    expect(find.text('25.00 USD'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byTooltip('Previous month'),
      -150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    expect(find.text('October 2026'), findsOneWidget);
    expect(find.text('0.00 USD'), findsOneWidget);
  });
  testWidgets('home explains missing budgets and links to settings', (
    tester,
  ) async {
    final fixture = DashboardFixture();
    await fixture.initialize();
    addTearDown(fixture.dispose);
    var openedSettings = false;
    await tester.pumpWidget(
      ChangeNotifierProvider<DashboardViewModel>.value(
        value: fixture.model,
        child: MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              onExpenses: () {},
              onSettings: () => openedSettings = true,
              onConvert: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Set budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set budget'));
    expect(openedSettings, isTrue);
    expect(find.byKey(const Key('monthlyRemaining')), findsNothing);
  });
  testWidgets('failed spending loads show retry instead of a zero total', (
    tester,
  ) async {
    final fixture = DashboardFixture();
    await fixture.initialize(expenseFailure: true, budgetMinor: 10000);
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
    expect(find.text('Couldn’t load monthly spending.'), findsOneWidget);
    expect(find.byKey(const Key('monthlySpent')), findsNothing);
    fixture.repository.fail = false;
    await tester.tap(find.text('Retry spending'));
    await tester.pumpAndSettle();
    expect(find.text('0.00 USD'), findsOneWidget);
  });
}
