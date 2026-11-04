import 'currency.dart';

// limit expenses to the supported categories
const expenseCategories = [
  'Food',
  'Shopping',
  'Transportation',
  'Entertainment',
  'Travel',
  'Bills',
  'Other',
];

// keep the original purchase and its fixed usd conversion together
class Expense {
  const Expense({
    required this.id,
    required this.amountMinor,
    required this.currency,
    required this.amountUsdMinor,
    required this.exchangeRate,
    required this.rateDate,
    required this.category,
    required this.description,
    required this.date,
  });
  final String id;
  final int amountMinor;
  final Currency currency;
  final int amountUsdMinor;
  final double exchangeRate;
  final DateTime rateDate;
  final String category;
  final String description;
  final DateTime date;

  // convert expense fields into a plain map
  Map<String, dynamic> toJson() => {
    'id': id,
    'amountMinor': amountMinor,
    'currency': currency.code,
    'amountUsdMinor': amountUsdMinor,
    'exchangeRate': exchangeRate,
    'rateDate': rateDate.toIso8601String(),
    'category': category,
    'description': description,
    'date': date.toIso8601String(),
  };
  // rebuild an expense from stored fields
  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    amountMinor: json['amountMinor'] as int,
    currency: Currency.values.firstWhere((c) => c.code == json['currency']),
    amountUsdMinor: json['amountUsdMinor'] as int,
    exchangeRate: (json['exchangeRate'] as num).toDouble(),
    rateDate: DateTime.parse(json['rateDate'] as String),
    category: json['category'] as String,
    description: json['description'] as String,
    date: DateTime.parse(json['date'] as String),
  );
}
