import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/money.dart';
import '../models/currency.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../widgets/budget_progress.dart';
import '../widgets/category_breakdown.dart';
import '../widgets/monthly_expense_list.dart';

// show one month of spending without making extra database requests
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onExpenses,
    required this.onSettings,
    required this.onConvert,
  });
  final VoidCallback onExpenses;
  final VoidCallback onSettings;
  final VoidCallback onConvert;
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  String _money(int minor) => '${formatMinor(minor, Currency.usd)} USD';

  @override
  Widget build(BuildContext context) {
    final model = context.watch<DashboardViewModel>();
    final state = model.state;
    final theme = Theme.of(context);
    final remaining = state.remainingMinor;
    final budgetDetails = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly budget',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                _money(state.budgetMinor ?? 0),
                key: const Key('monthlyLimit'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: onSettings,
              tooltip: 'Edit budget',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
          ],
        ),
      ],
    );
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Your money, wherever you go.',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text('A little clarity for the month ahead.'),
        const SizedBox(height: 24),
        Row(
          children: [
            IconButton(
              onPressed: model.previousMonth,
              tooltip: 'Previous month',
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  '${_months[state.month.month - 1]} ${state.month.year}',
                  key: const Key('summaryMonth'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ),
            IconButton(
              onPressed: model.nextMonth,
              tooltip: 'Next month',
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Center(
          child: TextButton(
            onPressed: model.currentMonth,
            child: const Text('This month'),
          ),
        ),
        const SizedBox(height: 12),
        // keep spending and its budget context together in one compact card
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Spent this month',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (!state.expensesLoading && state.expensesError == null)
                      Text(
                        '${state.expenseCount} ${state.expenseCount == 1 ? 'expense' : 'expenses'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (state.expensesLoading)
                  const LinearProgressIndicator(
                    semanticsLabel: 'Loading monthly spending',
                  )
                else if (state.expensesError != null) ...[
                  const Text('Couldn’t load monthly spending.'),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: model.retryExpenses,
                      child: const Text('Retry spending'),
                    ),
                  ),
                ] else ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _money(state.spentMinor),
                      key: const Key('monthlySpent'),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const Divider(height: 28),
                if (state.budgetLoading)
                  const LinearProgressIndicator(
                    semanticsLabel: 'Loading monthly budget',
                  )
                else if (state.budgetError != null) ...[
                  const Text('Couldn’t load your budget.'),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: model.retryBudget,
                      child: const Text('Retry budget'),
                    ),
                  ),
                ] else if (state.budgetMinor == null)
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('No monthly budget'),
                      TextButton(
                        onPressed: onSettings,
                        child: const Text('Set budget'),
                      ),
                    ],
                  )
                else ...[
                  if (state.budgetUsage != null)
                    BudgetProgress(
                      usage: state.budgetUsage!,
                      leading: budgetDetails,
                    )
                  else
                    budgetDetails,
                  const SizedBox(height: 12),
                  if (remaining != null)
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(remaining < 0 ? 'Over budget by' : 'Remaining'),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _money(remaining.abs()),
                            key: const Key('monthlyRemaining'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: remaining < 0
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Remaining balance unavailable while spending loads.',
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          key: const Key('categoryBreakdownCard'),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Spending by category', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('Share of this month’s USD spending'),
                const SizedBox(height: 12),
                if (state.expensesLoading)
                  const LinearProgressIndicator(
                    semanticsLabel: 'Loading category spending',
                  )
                else if (state.expensesError != null) ...[
                  const Text('Couldn’t load category spending.'),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: model.retryExpenses,
                      child: const Text('Retry categories'),
                    ),
                  ),
                ] else
                  CategoryBreakdown(
                    categories: state.categories,
                    selectedCategory: state.selectedCategory,
                    onCategorySelected: model.selectCategory,
                    selectedContent: MonthlyExpenseList(
                      expenses: state.visibleExpenses,
                      category: state.selectedCategory,
                      embedded: true,
                      onClear: () => model.selectCategory(null),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // keep both shortcuts aligned and easy to tap on smaller screens
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked =
                constraints.maxWidth < 300 ||
                MediaQuery.textScalerOf(context).scale(14) > 18;
            final shape = RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            );
            final expenses = FilledButton.icon(
              onPressed: onExpenses,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: shape,
              ),
              icon: const Icon(Icons.receipt_long_outlined, size: 20),
              label: const Text('View expenses'),
            );
            final converter = OutlinedButton.icon(
              onPressed: onConvert,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                shape: shape,
              ),
              icon: const Icon(Icons.currency_exchange, size: 20),
              label: const Text('Converter'),
            );
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [expenses, const SizedBox(height: 12), converter],
              );
            }
            return Row(
              children: [
                Expanded(child: expenses),
                const SizedBox(width: 12),
                Expanded(child: converter),
              ],
            );
          },
        ),
      ],
    );
  }
}
