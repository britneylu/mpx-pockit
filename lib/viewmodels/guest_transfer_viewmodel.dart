import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../repositories/expense_repository.dart';
import '../repositories/guest_expense_repository.dart';
import 'auth_viewmodel.dart';

// retain pending guest purchases until their account uploads succeed
class GuestTransferViewModel extends ChangeNotifier {
  GuestTransferViewModel(this._auth, this._repositoryFor) {
    _auth.addListener(_accountChanged);
    _accountChanged();
  }
  final AuthViewModel _auth;
  final ExpenseRepository Function(String) _repositoryFor;
  final guestRepository = GuestExpenseRepository();
  final _pending = <String, Map<String, Expense>>{};
  final _repositories = <String, ExpenseRepository>{};
  final _active = <String>{};
  final _errors = <String>{};
  bool _disposed = false;
  String? _lastAccount;

  int get pendingCount => _pending[_auth.state.account?.id]?.length ?? 0;
  bool get uploading => _active.contains(_auth.state.account?.id);
  bool get failed => _errors.contains(_auth.state.account?.id);
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _accountChanged() {
    final id = _auth.state.account?.id;
    if (id == _lastAccount) return;
    _lastAccount = id;
    // wait until authentication has finished notifying its listeners
    scheduleMicrotask(() {
      if (_disposed || _auth.state.account?.id != id) return;
      if (id != null) {
        final repository = _repositories.putIfAbsent(
          id,
          () => _repositoryFor(id),
        );
        final pending = _pending.putIfAbsent(id, () => {});
        for (final expense in guestRepository.expenses) {
          final copy = Expense.fromJson({
            ...expense.toJson(),
            'id': repository.newId(),
          });
          pending[copy.id] = copy;
        }
        // pending copies remain tied to this account if uploading fails
        guestRepository.clear();
        retry();
      }
      _notify();
    });
  }

  Future<void> retry() async {
    final id = _auth.state.account?.id;
    if (_disposed || id == null || _active.contains(id)) return;
    final pending = _pending[id];
    if (pending == null || pending.isEmpty) return;
    _active.add(id);
    _errors.remove(id);
    _notify();
    try {
      for (final expense in pending.values.toList()) {
        if (_disposed || _auth.state.account?.id != id) break;
        // reuse the same id on retry to avoid duplicate purchases
        await _repositories[id]!.upsert(expense);
        pending.remove(expense.id);
        _notify();
      }
    } catch (_) {
      _errors.add(id);
    } finally {
      _active.remove(id);
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_accountChanged);
    super.dispose();
  }
}
