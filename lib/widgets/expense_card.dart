import 'package:flutter/material.dart';

import '../core/money.dart';
import '../core/category_style.dart';
import '../models/currency.dart';
import '../models/expense.dart';

// group purchase details amounts and actions in a responsive card
class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    super.key,
    required this.expense,
    this.onEdit,
    this.onDelete,
  });
  final Expense expense;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  IconData get _icon => switch (expense.category) {
    'Food' => Icons.restaurant_outlined,
    'Shopping' => Icons.shopping_bag_outlined,
    'Transportation' => Icons.directions_bus_outlined,
    'Entertainment' => Icons.movie_outlined,
    'Travel' => Icons.flight_outlined,
    'Bills' => Icons.receipt_long_outlined,
    _ => Icons.payments_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final categoryColor = CategoryStyle.color(expense.category);
    final foreign = expense.currency != Currency.usd;
    final date = expense.date.toIso8601String().split('T').first;
    final amount = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${formatMinor(expense.amountMinor, expense.currency)} ${expense.currency.code}',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.primary,
            letterSpacing: -0.5,
          ),
        ),
        if (foreign) ...[
          const SizedBox(height: 4),
          Text(
            '≈ ${formatMinor(expense.amountUsdMinor, Currency.usd)} USD',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
    final details = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CategoryStyle.tint(expense.category, strength: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(_icon, color: categoryColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expense.description.isEmpty
                    ? expense.category
                    : expense.description,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (expense.description.isNotEmpty)
                    Text(
                      expense.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  Text(
                    date,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // stack amounts below the title on narrow screens or larger text
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked =
                      constraints.maxWidth < 480 ||
                      MediaQuery.textScalerOf(context).scale(16) > 22;
                  if (stacked) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [details, const SizedBox(height: 18), amount],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: details),
                      const SizedBox(width: 24),
                      Flexible(flex: 2, child: amount),
                    ],
                  );
                },
              ),
              if (foreign) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      Text(
                        '1 ${expense.currency.code} = ${expense.exchangeRate} USD',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        'Rate date: ${expense.rateDate.toIso8601String().split('T').first}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: colors.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 4),
              // keep actions separate from the purchase information
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 4,
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: onDelete,
                      style: TextButton.styleFrom(
                        foregroundColor: colors.error,
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
