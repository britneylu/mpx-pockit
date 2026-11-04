import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/models/account.dart';
import 'package:pockit/models/currency.dart';
import 'package:pockit/models/expense.dart';
import 'package:pockit/viewmodels/auth_viewmodel.dart';
import 'package:pockit/viewmodels/guest_transfer_viewmodel.dart';

import 'helpers/fake_auth_service.dart';
import 'helpers/memory_expense_repository.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);
const user = Account(id: 'new-user', email: 'new@example.com');
Expense purchase() => Expense(
  id: 'guest-1',
  amountMinor: 1500,
  currency: Currency.jpy,
  amountUsdMinor: 1000,
  exchangeRate: 0.006667,
  rateDate: DateTime(2026),
  category: 'Food',
  description: 'Guest lunch',
  date: DateTime(2026),
);

void main() {
  test(
    'registration transfers guest purchases with the original conversion',
    () async {
      final service = FakeAuthService(account: null);
      final auth = AuthViewModel(service);
      final repo = MemoryExpenseRepository();
      final transfer = GuestTransferViewModel(auth, (_) => repo);
      addTearDown(auth.dispose);
      addTearDown(transfer.dispose);
      await flush();
      await transfer.guestRepository.upsert(purchase());
      await auth.register(user.email, 'secret123');
      await flush();
      expect(repo.expenses.single.description, 'Guest lunch');
      expect(repo.expenses.single.amountUsdMinor, 1000);
      expect(repo.expenses.single.exchangeRate, 0.006667);
      expect(transfer.guestRepository.expenses, isEmpty);
      expect(transfer.pendingCount, 0);
      await transfer.retry();
      expect(repo.expenses.length, 1);
    },
  );
  test(
    'failed transfers retain purchases and stay isolated from other accounts',
    () async {
      final service = FakeAuthService(account: null);
      final auth = AuthViewModel(service);
      final first = MemoryExpenseRepository()..fail = true;
      final other = MemoryExpenseRepository();
      final transfer = GuestTransferViewModel(
        auth,
        (id) => id == user.id ? first : other,
      );
      addTearDown(auth.dispose);
      addTearDown(transfer.dispose);
      await flush();
      await transfer.guestRepository.upsert(purchase());
      service.emit(user);
      await flush();
      expect(transfer.failed, isTrue);
      expect(transfer.pendingCount, 1);
      service.emit(const Account(id: 'other', email: 'other@example.com'));
      await flush();
      expect(transfer.pendingCount, 0);
      expect(other.expenses, isEmpty);
      first.fail = false;
      service.emit(user);
      await flush();
      expect(first.expenses.length, 1);
      expect(transfer.pendingCount, 0);
      expect(transfer.failed, isFalse);
    },
  );
  test('google sign in transfers the guest purchases', () async {
    final service = FakeAuthService(account: null);
    final auth = AuthViewModel(service);
    final repo = MemoryExpenseRepository();
    final transfer = GuestTransferViewModel(auth, (_) => repo);
    addTearDown(auth.dispose);
    addTearDown(transfer.dispose);
    await flush();
    await transfer.guestRepository.upsert(purchase());
    await auth.signInWithGoogle();
    await flush();
    expect(repo.expenses.single.description, 'Guest lunch');
    expect(transfer.pendingCount, 0);
  });
}
