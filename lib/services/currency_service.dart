import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/currency.dart';
import '../models/exchange_rate.dart';

// allow real or fake exchange rate services
abstract interface class CurrencyService {
  Future<ExchangeRate> fetchRate(Currency from, Currency to);
}

// fetch daily reference rates from frankfurter
class FrankfurterCurrencyService implements CurrencyService {
  @override
  Future<ExchangeRate> fetchRate(Currency from, Currency to) async {
    // request the selected currency pair with a timeout
    final response = await http
        .get(
          Uri.https(
            'api.frankfurter.dev',
            '/v2/rate/${from.code.toLowerCase()}/${to.code.toLowerCase()}',
          ),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Exchange rate unavailable');
    }
    // read the rate and effective date from the response
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rate = (data['rate'] as num).toDouble();
    final date = DateTime.parse(data['date'] as String);
    // reject invalid rates before using them in calculations
    if (!rate.isFinite || rate <= 0) {
      throw const FormatException('Invalid exchange rate');
    }
    return ExchangeRate(rate: rate, date: date);
  }
}
