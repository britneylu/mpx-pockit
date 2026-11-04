import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/models/currency.dart';
import 'package:pockit/models/expense.dart';
import 'package:pockit/repositories/firestore_expense_repository.dart';

void main() {
  test(
    'Firestore mapping preserves integer amounts, rate, dates and document ID',
    () {
      final original = Expense(
        id: 'expense-123',
        amountMinor: 1500,
        currency: Currency.jpy,
        amountUsdMinor: 1000,
        exchangeRate: 0.006667,
        rateDate: DateTime(2026, 11, 3),
        category: 'Food',
        description: 'Lunch',
        date: DateTime(2026, 11, 4),
      );
      final fields = FirestoreExpenseRepository.encode(original);
      expect(fields['expenseDate'], isA<Timestamp>());
      expect(fields['updatedAt'], isA<FieldValue>());
      expect(fields.containsKey('id'), isFalse);
      final decoded = FirestoreExpenseRepository.decode(original.id, fields);
      expect(decoded.toJson(), original.toJson());
    },
  );
}
