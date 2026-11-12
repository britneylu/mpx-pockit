import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/money.dart';
import '../models/currency.dart';
import '../viewmodels/dashboard_viewmodel.dart';

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
        // avoid showing a misleading zero while expenses are unavailable
        Card(
          color: theme.colorScheme.primary,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spent this month',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                if (state.expensesLoading)
                  const LinearProgressIndicator(
                    semanticsLabel: 'Loading monthly spending',
                  )
                else if (state.expensesError != null) ...[
                  const Text(
                    'Couldn’t load monthly spending.',
                    style: TextStyle(color: Colors.white),
                  ),
                  TextButton(
                    onPressed: model.retryExpenses,
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: const Text('Retry spending'),
                  ),
                ] else ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _money(state.spentMinor),
                      key: const Key('monthlySpent'),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${state.expenseCount} ${state.expenseCount == 1 ? 'expense' : 'expenses'} · all categories',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Monthly budget', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
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
                ] else if (state.budgetMinor == null) ...[
                  const Text(
                    'Set a monthly budget to see how much you have left.',
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onSettings,
                      child: const Text('Set budget'),
                    ),
                  ),
                ] else ...[
                  Text(
                    _money(state.budgetMinor!),
                    key: const Key('monthlyLimit'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  if (remaining != null) ...[
                    Text(
                      remaining < 0 ? 'Over budget by' : 'Remaining this month',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _money(remaining.abs()),
                        key: const Key('monthlyRemaining'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: remaining < 0
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ] else
                    const Text(
                      'Remaining balance is available when spending loads.',
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your current budget applies to every month until you change it.',
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onSettings,
                      child: const Text('Edit budget'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!state.expensesLoading &&
            state.expensesError == null &&
            state.expenseCount == 0) ...[
          const SizedBox(height: 20),
          const Text('No expenses for this month yet.'),
        ],
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: onExpenses,
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('View expenses'),
            ),
            OutlinedButton.icon(
              onPressed: onConvert,
              icon: const Icon(Icons.currency_exchange),
              label: const Text('Try the converter'),
            ),
          ],
        ),
      ],
    );
  }
}
