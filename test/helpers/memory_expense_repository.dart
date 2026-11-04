import 'dart:async';

import 'package:pockit/models/expense.dart';
import 'package:pockit/repositories/expense_repository.dart';

class MemoryExpenseRepository implements ExpenseRepository {
  List<Expense> expenses = [];
  bool fail = false;
  int _nextId = 0;
  int listeners = 0;
  final _updates = StreamController<List<Expense>>.broadcast();
  @override
  Stream<List<Expense>> watch() => Stream.multi((controller) {
    if (fail) {
      controller.addError(Exception('Storage unavailable'));
      controller.close();
      return;
    }
    listeners++;
    controller.add([...expenses]);
    final subscription = _updates.stream.listen(controller.addSync);
    controller.onCancel = () async {
      listeners--;
      await subscription.cancel();
    };
  });
  @override
  String newId() => 'expense-${++_nextId}';
  @override
  Future<void> upsert(Expense expense) async {
    if (fail) throw Exception('Storage unavailable');
    expenses = [...expenses.where((e) => e.id != expense.id), expense];
    _updates.add([...expenses]);
  }

  @override
  Future<void> delete(String id) async {
    if (fail) throw Exception('Storage unavailable');
    expenses = expenses.where((e) => e.id != id).toList();
    _updates.add([...expenses]);
  }

  void remoteUpdate(List<Expense> values) {
    expenses = [...values];
    _updates.add([...expenses]);
  }
}
