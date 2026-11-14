import 'package:flutter/material.dart';

import '../core/category_style.dart';
import '../core/money.dart';
import '../models/currency.dart';
import '../models/expense.dart';

// show every matching purchase without changing the monthly summary totals
class MonthlyExpenseList extends StatelessWidget {
  const MonthlyExpenseList({
    super.key,
    required this.expenses,
    this.category,
    required this.onClear,
    this.embedded = false,
  });
  final List<Expense> expenses;
  final String? category;
  final VoidCallback onClear;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: embedded ? Colors.transparent : null,
      elevation: embedded ? 0 : null,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: embedded ? EdgeInsets.zero : const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category == null
                        ? 'This month’s expenses'
                        : '$category expenses',
                    key: const Key('monthlyExpenseListTitle'),
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                if (category != null)
                  IconButton(
                    onPressed: onClear,
                    tooltip: 'Clear category filter',
                    icon: const Icon(Icons.filter_alt_off_outlined),
                  ),
              ],
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                '${expenses.length} ${expenses.length == 1 ? 'expense' : 'expenses'}',
                style: theme.textTheme.bodySmall,
              ),
            ),
            if (expenses.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  category == null
                      ? 'No expenses this month.'
                      : 'No $category expenses this month.',
                ),
              ),
            for (final expense in expenses)
              Padding(
                key: ValueKey('monthlyExpense-${expense.id}'),
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Text(
                          expense.description.isEmpty
                              ? expense.category
                              : expense.description,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          '${formatMinor(expense.amountMinor, expense.currency)} ${expense.currency.code}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text(
                          '${expense.category} · ${expense.date.toIso8601String().split('T').first}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: CategoryStyle.color(expense.category),
                          ),
                        ),
                        if (expense.currency != Currency.usd)
                          Text(
                            '${formatMinor(expense.amountUsdMinor, Currency.usd)} USD',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
