import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/widgets/budget_progress.dart';

Widget example(double usage, {bool reduced = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: BudgetProgress(usage: usage),
      ),
    ),
  ),
);

double fill(WidgetTester tester) => tester
    .widget<LinearProgressIndicator>(
      find.byKey(const Key('budgetProgressFill')),
    )
    .value!;

void main() {
  testWidgets(
    'progress animates into place and updates when spending changes',
    (tester) async {
      await tester.pumpWidget(example(0.5));
      expect(fill(tester), 0);
      await tester.pump(const Duration(milliseconds: 350));
      expect(fill(tester), greaterThan(0));
      expect(fill(tester), lessThan(0.5));
      await tester.pumpAndSettle();
      expect(fill(tester), 0.5);
      expect(find.text('50% used'), findsOneWidget);
      await tester.pumpWidget(example(0.75));
      expect(fill(tester), 0.5);
      await tester.pumpAndSettle();
      expect(fill(tester), 0.75);
      await tester.pumpWidget(example(0));
      await tester.pumpAndSettle();
      expect(fill(tester), 0);
      expect(find.text('0% used'), findsOneWidget);
    },
  );
  testWidgets('over budget keeps the actual percentage and caps the fill', (
    tester,
  ) async {
    await tester.pumpWidget(example(1.5));
    await tester.pumpAndSettle();
    expect(fill(tester), 1);
    expect(find.text('150% used'), findsOneWidget);
    expect(find.text('Over budget'), findsOneWidget);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Monthly budget usage'), findsOneWidget);
    await tester.pumpWidget(example(1));
    await tester.pumpAndSettle();
    expect(find.text('Budget reached'), findsOneWidget);
    semantics.dispose();
  });
  testWidgets('reduced motion shows the result without an animation', (
    tester,
  ) async {
    await tester.pumpWidget(example(0.75, reduced: true));
    await tester.pump();
    expect(fill(tester), 0.75);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
