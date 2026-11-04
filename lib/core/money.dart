import '../models/currency.dart';

// parse user input without passing monetary values through floating point
int parseMinor(String input, Currency currency) {
  final value = input.trim();
  if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value)) {
    throw const FormatException('Enter a positive amount.');
  }
  final parts = value.split('.');
  final fraction = parts.length == 2 ? parts[1] : '';
  if (fraction.length > currency.decimals) {
    throw FormatException(
      '${currency.code} allows ${currency.decimals} decimal places.',
    );
  }
  // combine whole and fractional digits into integer minor units
  final minor =
      BigInt.parse(parts[0]) * BigInt.from(10).pow(currency.decimals) +
      BigInt.parse(
        fraction.padRight(currency.decimals, '0').isEmpty
            ? '0'
            : fraction.padRight(currency.decimals, '0'),
      );
  if (minor <= BigInt.zero || minor > BigInt.from(1000000000000)) {
    throw const FormatException(
      'Enter an amount greater than zero and no more than 1 trillion minor units.',
    );
  }
  return minor.toInt();
}

// turn minor units into a readable currency amount
String formatMinor(int minor, Currency currency) {
  if (currency.decimals == 0) return '$minor';
  final digits = minor.abs().toString().padLeft(currency.decimals + 1, '0');
  return '${minor < 0 ? '-' : ''}${digits.substring(0, digits.length - currency.decimals)}.${digits.substring(digits.length - currency.decimals)}';
}

// apply a decimal rate with integer arithmetic and round half up to usd cents
int convertToUsdMinor(int minor, Currency currency, double rate) {
  if (!rate.isFinite || rate <= 0) throw const FormatException('Invalid rate.');
  // split the rate into decimal digits and an optional exponent
  final parts = rate.toString().toLowerCase().split('e');
  final exponent = parts.length == 2 ? int.parse(parts[1]) : 0;
  final decimal = parts[0].split('.');
  final fraction = decimal.length == 2 ? decimal[1] : '';
  // build an integer fraction for the conversion into usd cents
  var numerator =
      BigInt.from(minor) *
      BigInt.parse('${decimal[0]}$fraction') *
      BigInt.from(100);
  var denominator = BigInt.from(10).pow(currency.decimals + fraction.length);
  if (exponent >= 0) {
    numerator *= BigInt.from(10).pow(exponent);
  } else {
    denominator *= BigInt.from(10).pow(-exponent);
  }
  // round half up without floating point money arithmetic
  final result =
      (numerator * BigInt.two + denominator) ~/ (denominator * BigInt.two);
  if (result > BigInt.from(1000000000000)) {
    throw const FormatException('Converted amount is too large.');
  }
  return result.toInt();
}
