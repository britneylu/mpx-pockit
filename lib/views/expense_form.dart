import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/money.dart';
import '../models/currency.dart';
import '../models/expense.dart';
import '../viewmodels/expenses_viewmodel.dart';

// use the same form to add and edit expenses
class ExpenseForm extends StatefulWidget {
  const ExpenseForm({super.key, this.expense});
  final Expense? expense;
  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _description;
  late Currency _currency;
  late String _category;
  late DateTime _date;
  String? _error;
  @override
  // prefill saved values when editing an expense
  void initState() {
    super.initState();
    final expense = widget.expense;
    _currency = expense?.currency ?? Currency.usd;
    _category = expense?.category ?? expenseCategories.first;
    _date = expense?.date ?? DateUtils.dateOnly(DateTime.now());
    _amount = TextEditingController(
      text: expense == null
          ? ''
          : formatMinor(expense.amountMinor, expense.currency),
    );
    _description = TextEditingController(text: expense?.description ?? '');
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  // validate inputs and let the viewmodel handle conversion and storage
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _error = null);
    final model = context.read<ExpensesViewModel>();
    final success = await model.saveExpense(
      original: widget.expense,
      amount: _amount.text,
      currency: _currency,
      category: _category,
      description: _description.text,
      date: _date,
    );
    // avoid updating the form after it has closed
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      setState(
        () => _error = model.lastSaveError ?? 'Couldn’t save. Please retry.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // disable inputs while the expense is being saved
    final saving = context.watch<ExpensesViewModel>().state.saving;
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.expense == null ? 'Add expense' : 'Edit expense'),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    TextFormField(
                      controller: _amount,
                      enabled: !saving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Expense amount',
                      ),
                      validator: (value) {
                        try {
                          parseMinor(value ?? '', _currency);
                          return null;
                        } on FormatException catch (error) {
                          return error.message;
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Currency>(
                      initialValue: _currency,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: Currency.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text('${c.code} · ${c.label}'),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) => setState(() => _currency = value!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: expenseCategories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) => setState(() => _category = value!),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        'Date: ${_date.toIso8601String().split('T').first}',
                      ),
                      onPressed: saving
                          ? null
                          : () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (date != null && mounted) {
                                setState(() => _date = date);
                              }
                            },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _description,
                      enabled: !saving,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Foreign purchases use the latest available daily rate, even for past purchase dates. The USD amount and effective rate date are fixed when saved. Changing only category or description preserves that conversion.',
                    ),
                    if (widget.expense != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Saved: ${formatMinor(widget.expense!.amountUsdMinor, Currency.usd)} USD · rate date ${widget.expense!.rateDate.toIso8601String().split('T').first}',
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: saving ? null : _save,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        saving ? 'Saving… connection required' : 'Save expense',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
