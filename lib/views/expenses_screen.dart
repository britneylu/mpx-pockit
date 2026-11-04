import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/money.dart';
import '../models/expense.dart';
import '../viewmodels/expenses_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'expense_form.dart';
import '../widgets/expense_card.dart';

// show filtered expenses with edit and delete actions
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  // confirm deletion and offer an undo action after success
  Future<void> _delete(BuildContext context, Expense expense) async {
    final model = context.read<ExpensesViewModel>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text(
          '${formatMinor(expense.amountMinor, expense.currency)} ${expense.currency.code} · ${expense.category}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await model.delete(expense);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Expense deleted' : 'Couldn’t delete. Please retry.',
        ),
        action: success
            ? SnackBarAction(
                label: 'Undo',
                onPressed: () async {
                  final restored = await model.restore(expense);
                  if (!restored) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Couldn’t restore. Please retry.'),
                      ),
                    );
                  }
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ExpensesViewModel>();
    // read the current expense list and loading status
    final state = model.state;
    final guest = context.watch<AuthViewModel>().state.account == null;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Every purchase, in perspective.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text('Original currency. One clear USD total.'),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: state.loading || state.saving || state.error != null
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const ExpenseForm()),
                ),
          icon: const Icon(Icons.add),
          label: const Text('Add expense'),
        ),
        const SizedBox(height: 16),
        Text(
          guest
              ? 'Guest mode · expenses are temporary and disappear when you leave this session'
              : 'Expenses sync with your signed-in account.',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: state.filter ?? 'All categories',
          decoration: const InputDecoration(labelText: 'Filter by category'),
          items: [
            'All categories',
            ...expenseCategories,
          ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (value) =>
              model.setFilter(value == 'All categories' ? null : value),
        ),
        const SizedBox(height: 16),
        // handle loading errors and empty results before showing cards
        if (state.loading)
          const LinearProgressIndicator()
        else if (state.error != null) ...[
          Text(state.error!),
          TextButton(
            onPressed: model.load,
            child: const Text('Retry loading expenses'),
          ),
        ] else if (state.visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              state.expenses.isEmpty
                  ? 'No expenses yet. Add your first purchase to get started.'
                  : 'No expenses in this category.',
            ),
          )
        else
          ...state.visible.map(
            // let users swipe an expense to request deletion
            (expense) => Dismissible(
              key: ValueKey(expense.id),
              direction: state.saving
                  ? DismissDirection.none
                  : DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.delete_outline),
              ),
              confirmDismiss: (_) async {
                await _delete(context, expense);
                return false;
              },
              child: ExpenseCard(
                expense: expense,
                onEdit: state.saving
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ExpenseForm(expense: expense),
                        ),
                      ),
                onDelete: state.saving ? null : () => _delete(context, expense),
              ),
            ),
          ),
      ],
    );
  }
}
