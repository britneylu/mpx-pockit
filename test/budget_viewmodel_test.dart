import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/models/account.dart';
import 'package:pockit/repositories/budget_repository.dart';
import 'package:pockit/viewmodels/auth_viewmodel.dart';
import 'package:pockit/viewmodels/budget_viewmodel.dart';

import 'helpers/fake_auth_service.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

class TestBudgetRepository extends MemoryBudgetRepository {
  bool failRead = false;
  bool failWrite = false;
  Completer<void>? gate;
  @override
  Stream<int?> watch() =>
      failRead ? Stream.error(Exception('read failed')) : super.watch();
  @override
  Future<void> save(int amountMinor) async {
    if (failWrite) throw Exception('save failed');
    await gate?.future;
    await super.save(amountMinor);
  }
}

void main() {
  test('validates positive usd amounts and persists exact cents', () async {
    final auth = AuthViewModel(FakeAuthService());
    final repo = TestBudgetRepository();
    final model = BudgetViewModel(auth, (_) => repo);
    addTearDown(auth.dispose);
    addTearDown(model.dispose);
    await flush();
    for (final value in ['', '0', '-10', '12.345', 'abc']) {
      expect(await model.save(value), isFalse);
      expect(model.state.saveError, isNotNull);
    }
    expect(await model.save('1200.29'), isTrue);
    expect(repo.amountMinor, 120029);
    expect(model.state.message, 'Monthly budget saved');
    final reloaded = BudgetViewModel(auth, (_) => repo);
    addTearDown(reloaded.dispose);
    await flush();
    expect(reloaded.state.amountMinor, 120029);
  });
  test('load and save failures preserve values and allow retry', () async {
    final auth = AuthViewModel(FakeAuthService());
    final repo = TestBudgetRepository()..failRead = true;
    final model = BudgetViewModel(auth, (_) => repo);
    addTearDown(auth.dispose);
    addTearDown(model.dispose);
    await flush();
    expect(model.state.loadError, isNotNull);
    repo.failRead = false;
    await model.reload();
    await flush();
    await model.save('500');
    repo.failWrite = true;
    expect(await model.save('600'), isFalse);
    expect(model.state.amountMinor, 50000);
    expect(model.state.saveError, isNotNull);
    repo.failWrite = false;
    expect(await model.save('600'), isTrue);
    expect(model.state.amountMinor, 60000);
  });
  test(
    'guest budget transfers and failures stay retryable for its account',
    () async {
      final service = FakeAuthService(account: null);
      final auth = AuthViewModel(service);
      final repo = TestBudgetRepository()..failWrite = true;
      final model = BudgetViewModel(auth, (_) => repo);
      addTearDown(auth.dispose);
      addTearDown(model.dispose);
      await flush();
      expect(await model.save('800.50'), isTrue);
      service.emit(const Account(id: 'first', email: 'first@example.com'));
      await flush();
      expect(model.state.transferError, isNotNull);
      repo.failWrite = false;
      await model.retryTransfer();
      expect(repo.amountMinor, 80050);
      expect(model.state.transferError, isNull);
    },
  );
  test('guest transfer keeps an existing account budget', () async {
    final service = FakeAuthService(account: null);
    final auth = AuthViewModel(service);
    final repo = TestBudgetRepository();
    await repo.save(100000);
    final model = BudgetViewModel(auth, (_) => repo);
    addTearDown(auth.dispose);
    addTearDown(model.dispose);
    await flush();
    await model.save('800');
    service.emit(const Account(id: 'existing', email: 'existing@example.com'));
    await flush();
    expect(repo.amountMinor, 100000);
    expect(model.state.amountMinor, 100000);
    expect(model.state.message, 'Your existing account budget was kept');
  });
  test('old save completion cannot update another account state', () async {
    final service = FakeAuthService();
    final auth = AuthViewModel(service);
    final repo = TestBudgetRepository()..gate = Completer<void>();
    final other = TestBudgetRepository();
    final model = BudgetViewModel(
      auth,
      (id) => id == 'test-user' ? repo : other,
    );
    addTearDown(auth.dispose);
    addTearDown(model.dispose);
    await flush();
    final saving = model.save('750');
    service.emit(const Account(id: 'other', email: 'other@example.com'));
    await flush();
    repo.gate!.complete();
    expect(await saving, isFalse);
    expect(model.state.amountMinor, isNull);
    expect(other.amountMinor, isNull);
  });
}
