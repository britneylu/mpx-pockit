import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

// store one recurring monthly limit in usd cents
abstract interface class BudgetRepository {
  Stream<int?> watch();
  Future<void> save(int amountMinor);
  Future<int> saveIfUnset(int amountMinor);
}

class FirestoreBudgetRepository implements BudgetRepository {
  FirestoreBudgetRepository(String userId, {FirebaseFirestore? firestore})
    : _document = (firestore ?? FirebaseFirestore.instance)
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('preferences');
  final DocumentReference<Map<String, dynamic>> _document;

  @override
  Stream<int?> watch() => _document.snapshots().map(
    (snapshot) => snapshot.data()?['monthlyBudgetMinor'] as int?,
  );

  Map<String, dynamic> _fields(int amountMinor) => {
    'monthlyBudgetMinor': amountMinor,
    'reportingCurrency': 'USD',
    'updatedAt': FieldValue.serverTimestamp(),
  };
  @override
  Future<void> save(int amountMinor) =>
      _document.set(_fields(amountMinor), SetOptions(merge: true));

  @override
  // keep an existing account budget when importing a guest budget
  Future<int> saveIfUnset(int amountMinor) =>
      _document.firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(_document);
        final existing = snapshot.data()?['monthlyBudgetMinor'] as int?;
        if (existing != null) return existing;
        transaction.set(
          _document,
          _fields(amountMinor),
          SetOptions(merge: true),
        );
        return amountMinor;
      });
}

// keep guest settings in memory for the current session
class MemoryBudgetRepository implements BudgetRepository {
  int? amountMinor;
  final _listeners = <MultiStreamController<int?>>{};
  @override
  Stream<int?> watch() => Stream.multi((listener) {
    _listeners.add(listener);
    listener.add(amountMinor);
    listener.onCancel = () => _listeners.remove(listener);
  });
  @override
  Future<void> save(int amountMinor) async {
    this.amountMinor = amountMinor;
    for (final listener in _listeners) {
      listener.add(amountMinor);
    }
  }

  @override
  Future<int> saveIfUnset(int amountMinor) async {
    if (this.amountMinor == null) await save(amountMinor);
    return this.amountMinor!;
  }
}
