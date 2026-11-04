import 'dart:async';

import 'package:pockit/models/account.dart';
import 'package:pockit/services/auth_service.dart';

class FakeAuthService implements AuthService {
  FakeAuthService({
    this.account = const Account(id: 'test-user', email: 'test@example.com'),
  });
  Account? account;
  String? failure;
  String? submittedEmail;
  int registrationCalls = 0;
  int googleCalls = 0;
  bool cancelGoogle = false;
  final _updates = StreamController<Account?>.broadcast();
  @override
  Stream<Account?> get accountChanges => Stream.multi((controller) {
    controller.add(account);
    final subscription = _updates.stream.listen(controller.addSync);
    controller.onCancel = subscription.cancel;
  });
  void emit(Account? value) {
    account = value;
    _updates.add(value);
  }

  @override
  Future<void> signIn(String email, String password) async {
    if (failure != null) throw AuthFailure(failure!);
    submittedEmail = email;
    emit(Account(id: email, email: email));
  }

  @override
  Future<void> register(String email, String password) async {
    registrationCalls++;
    await signIn(email, password);
  }

  @override
  Future<void> signInWithGoogle() async {
    googleCalls++;
    if (cancelGoogle) throw const AuthCancelled();
    if (failure != null) throw AuthFailure(failure!);
    emit(const Account(id: 'google-user', email: 'google@example.com'));
  }

  @override
  Future<void> signOut() async {
    if (failure != null) throw AuthFailure(failure!);
    emit(null);
  }

  @override
  Future<void> resetPassword(String email) async {
    if (failure != null) throw AuthFailure(failure!);
  }
}
