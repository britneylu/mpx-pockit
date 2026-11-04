import 'dart:async';

import '../models/expense.dart';
import 'expense_repository.dart';

// keep guest expenses in memory without writing to disk or firebase
class GuestExpenseRepository implements ExpenseRepository {
  final Map<String, Expense> _expenses = {};
  final Set<MultiStreamController<List<Expense>>> _listeners = {};
  int _nextId = 0;

  List<Expense> get expenses => List.unmodifiable(_expenses.values);

  // clear guest entries after handing them to the account transfer queue
  void clear() {
    _expenses.clear();
    _notify();
  }

  @override
  Stream<List<Expense>> watch() => Stream.multi((listener) {
    _listeners.add(listener);
    listener.add(_expenses.values.toList());
    listener.onCancel = () => _listeners.remove(listener);
  });

  @override
  String newId() => 'guest-${++_nextId}';

  // update every active listener after a session change
  void _notify() {
    for (final listener in _listeners) {
      listener.add(_expenses.values.toList());
    }
  }

  @override
  Future<void> upsert(Expense expense) async {
    _expenses[expense.id] = expense;
    _notify();
  }

  @override
  Future<void> delete(String id) async {
    _expenses.remove(id);
    _notify();
  }
}
