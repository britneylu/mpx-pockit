import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/models/currency.dart';
import 'package:pockit/models/exchange_rate.dart';
import 'package:pockit/services/currency_service.dart';
import 'package:pockit/viewmodels/converter_viewmodel.dart';

class ControlledService implements CurrencyService {
  final requests = <Completer<ExchangeRate>>[];
  @override
  Future<ExchangeRate> fetchRate(Currency from, Currency to) {
    final request = Completer<ExchangeRate>();
    requests.add(request);
    return request.future;
  }
}

ExchangeRate quote(double rate) =>
    ExchangeRate(rate: rate, date: DateTime(2026, 11, 4));

void main() {
  test(
    'loading, conversion, and amount edits use the same fetched rate',
    () async {
      final service = ControlledService();
      final model = ConverterViewModel(service);
      addTearDown(model.dispose);
      final pending = model.refresh();
      expect(model.state.status, ConversionStatus.loading);
      model.setAmount('100');
      service.requests.single.complete(quote(0.9));
      await pending;
      expect(model.state.result, 90);
      model.setAmount('50');
      expect(model.state.result, 45);
      expect(service.requests.length, 1);
    },
  );
  test('older responses cannot replace the current currency pair', () async {
    final service = ControlledService();
    final model = ConverterViewModel(service);
    addTearDown(model.dispose);
    final old = model.refresh();
    final current = model.setTo(Currency.gbp);
    service.requests[1].complete(quote(0.8));
    await current;
    service.requests[0].complete(quote(0.9));
    await old;
    expect(model.state.to, Currency.gbp);
    expect(model.state.quote!.rate, 0.8);
  });
  test(
    'same currency needs no network request and validates minor units',
    () async {
      final service = ControlledService();
      final model = ConverterViewModel(service);
      addTearDown(model.dispose);
      await model.setTo(Currency.usd);
      model.setAmount('10.25');
      expect(model.state.result, 10.25);
      model.setAmount('10.255');
      expect(model.state.amountError, isNotNull);
      expect(model.state.result, isNull);
      expect(service.requests, isEmpty);
    },
  );
}
