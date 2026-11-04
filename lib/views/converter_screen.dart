import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/currency.dart';
import '../viewmodels/converter_viewmodel.dart';

// display currency conversion inputs and results
class ConverterScreen extends StatelessWidget {
  const ConverterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // rebuild the screen when conversion state changes
    final model = context.watch<ConverterViewModel>();
    final state = model.state;
    final quote = state.quote;
    final result = state.result;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'A world of possibilities.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text('Check a currency before your next adventure.'),
        const SizedBox(height: 24),
        // send amount edits to the viewmodel for local calculation
        TextField(
          key: const Key('amount'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount',
            hintText: 'Enter an amount',
            suffixText: state.from.code,
            errorText: state.amountError,
          ),
          onChanged: model.setAmount,
        ),
        const SizedBox(height: 20),
        _CurrencySelector(
          label: 'From',
          value: state.from,
          onChanged: model.setFrom,
        ),
        Center(
          child: IconButton.filledTonal(
            onPressed: model.swap,
            tooltip: 'Swap currencies',
            icon: const Icon(Icons.swap_vert),
          ),
        ),
        _CurrencySelector(label: 'To', value: state.to, onChanged: model.setTo),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CONVERTED AMOUNT'),
                const SizedBox(height: 12),
                // show loading error or result content for the current request
                if (state.status == ConversionStatus.loading)
                  Semantics(
                    label: 'Fetching exchange rate',
                    child: const LinearProgressIndicator(),
                  )
                else if (state.status == ConversionStatus.error) ...[
                  Semantics(liveRegion: true, child: Text(state.error!)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: model.refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ] else ...[
                  if (result != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        '${result.toStringAsFixed(state.to.decimals)} ${state.to.code}',
                        key: const Key('conversionResult'),
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    )
                  else
                    Text(
                      state.amountError == null
                          ? 'Enter an amount to get started.'
                          : 'Check the amount above.',
                    ),
                  if (quote != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      '1 ${state.from.code} = ${quote.rate.toStringAsFixed(6)} ${state.to.code}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.from == state.to
                          ? 'Same currency · no exchange needed'
                          : 'Rate date: ${quote.date.toIso8601String().split('T').first}',
                    ),
                    TextButton.icon(
                      onPressed: model.refresh,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh rate'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Reference rates from Frankfurter. Rates update daily; your bank or card provider may charge a different rate or fees.',
        ),
      ],
    );
  }
}

// reuse the supported currency dropdown for both selections
class _CurrencySelector extends StatelessWidget {
  const _CurrencySelector({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final Currency value;
  final ValueChanged<Currency> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<Currency>(
    key: ValueKey('$label-${value.code}'),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: Currency.values
        .map(
          (currency) => DropdownMenuItem(
            value: currency,
            child: Text(
              '${currency.code} · ${currency.label}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(),
    onChanged: (currency) {
      if (currency != null) onChanged(currency);
    },
  );
}
