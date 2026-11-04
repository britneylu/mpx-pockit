import 'package:flutter/foundation.dart';

import '../models/currency.dart';
import '../models/exchange_rate.dart';
import '../services/currency_service.dart';

enum ConversionStatus { idle, loading, ready, error }

// keep the selected currencies and conversion state read only
@immutable
class ConverterState {
  const ConverterState({
    this.from = Currency.usd,
    this.to = Currency.eur,
    this.amount = '',
    this.status = ConversionStatus.idle,
    this.quote,
    this.error,
  });
  final Currency from;
  final Currency to;
  final String amount;
  final ConversionStatus status;
  final ExchangeRate? quote;
  final String? error;

  double? get parsedAmount => double.tryParse(amount.trim());
  // validate the amount using the source currency precision
  String? get amountError {
    if (amount.trim().isEmpty) return null;
    final value = parsedAmount;
    if (value == null || !value.isFinite || value <= 0) {
      return 'Enter a positive number, such as 25.50.';
    }
    if (!RegExp(r'^\d+(\.\d*)?$').hasMatch(amount.trim()) ||
        (amount.contains('.') &&
            amount.split('.').last.length > from.decimals)) {
      return '${from.code} allows ${from.decimals} decimal places.';
    }
    if (quote != null && !(value * quote!.rate).isFinite) {
      return 'This amount is too large.';
    }
    return null;
  }

  // calculate a result only when the amount and rate are valid
  double? get result =>
      status == ConversionStatus.ready &&
          amount.trim().isNotEmpty &&
          amountError == null
      ? parsedAmount! * quote!.rate
      : null;
}

// manage currency selections and asynchronous rate requests
class ConverterViewModel extends ChangeNotifier {
  ConverterViewModel(this._service);
  final CurrencyService _service;
  ConverterState _state = const ConverterState();
  ConverterState get state => _state;
  int _request = 0;
  bool _disposed = false;

  // reuse the fetched rate when only the amount changes
  void setAmount(String amount) {
    _state = ConverterState(
      from: _state.from,
      to: _state.to,
      amount: amount,
      status: _state.status,
      quote: _state.quote,
      error: _state.error,
    );
    notifyListeners();
  }

  Future<void> setFrom(Currency from) => _load(from, _state.to);
  Future<void> setTo(Currency to) => _load(_state.from, to);
  Future<void> swap() => _load(_state.to, _state.from);
  Future<void> refresh() => _load(_state.from, _state.to);

  // fetch a rate for the latest selected pair
  Future<void> _load(Currency from, Currency to) async {
    // mark older requests so their responses can be ignored
    final request = ++_request;
    _state = ConverterState(
      from: from,
      to: to,
      amount: _state.amount,
      status: ConversionStatus.loading,
    );
    notifyListeners();
    try {
      // skip the network when both currencies are the same
      final quote = from == to
          ? ExchangeRate(rate: 1, date: DateTime.now())
          : await _service.fetchRate(from, to);
      if (_disposed || request != _request) return;
      _state = ConverterState(
        from: from,
        to: to,
        amount: _state.amount,
        status: ConversionStatus.ready,
        quote: quote,
      );
    } catch (_) {
      if (_disposed || request != _request) return;
      _state = ConverterState(
        from: from,
        to: to,
        amount: _state.amount,
        status: ConversionStatus.error,
        error:
            'Couldn’t load the exchange rate. Check your connection and retry.',
      );
    }
    notifyListeners();
  }

  @override
  // prevent pending requests from updating a removed viewmodel
  void dispose() {
    _disposed = true;
    _request++;
    super.dispose();
  }
}
