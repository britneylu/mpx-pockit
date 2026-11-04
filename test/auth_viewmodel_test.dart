import 'package:flutter_test/flutter_test.dart';
import 'package:pockit/viewmodels/auth_viewmodel.dart';

import 'helpers/fake_auth_service.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);
void main() {
  test(
    'restores session, signs out and registers with trimmed email',
    () async {
      final service = FakeAuthService();
      final model = AuthViewModel(service);
      addTearDown(model.dispose);
      expect(model.state.initializing, isTrue);
      await flush();
      expect(model.state.account!.id, 'test-user');
      expect(await model.signOut(), isTrue);
      await flush();
      expect(model.state.account, isNull);
      expect(await model.register(' new@example.com ', 'secret123'), isTrue);
      await flush();
      expect(service.submittedEmail, 'new@example.com');
      expect(model.state.account!.email, 'new@example.com');
      expect(service.registrationCalls, 1);
    },
  );
  test('authentication errors are displayed and can be retried', () async {
    final service = FakeAuthService(account: null)
      ..failure = 'Check your internet connection and retry.';
    final model = AuthViewModel(service);
    addTearDown(model.dispose);
    await flush();
    expect(await model.signIn('test@example.com', 'secret123'), isFalse);
    expect(model.state.error, service.failure);
    expect(model.state.busy, isFalse);
    service.failure = null;
    expect(await model.signIn('test@example.com', 'secret123'), isTrue);
    await flush();
    expect(model.state.error, isNull);
    expect(model.state.account, isNotNull);
  });
  test('password reset exposes feedback without storing credentials', () async {
    final model = AuthViewModel(FakeAuthService(account: null));
    addTearDown(model.dispose);
    await flush();
    expect(await model.resetPassword('test@example.com'), isTrue);
    expect(model.state.message, contains('reset link'));
    expect(model.state.account, isNull);
  });
  test('google authentication publishes the selected account', () async {
    final service = FakeAuthService(account: null);
    final model = AuthViewModel(service);
    addTearDown(model.dispose);
    await flush();
    expect(await model.signInWithGoogle(), isTrue);
    await flush();
    expect(service.googleCalls, 1);
    expect(model.state.account!.email, 'google@example.com');
  });
  test(
    'google cancellation stays signed out and failures can be retried',
    () async {
      final service = FakeAuthService(account: null)..cancelGoogle = true;
      final model = AuthViewModel(service);
      addTearDown(model.dispose);
      await flush();
      expect(await model.signInWithGoogle(), isFalse);
      expect(model.state.error, isNull);
      expect(model.state.account, isNull);
      expect(model.state.busy, isFalse);
      service.cancelGoogle = false;
      service.failure = 'Google unavailable';
      expect(await model.signInWithGoogle(), isFalse);
      expect(model.state.error, 'Google unavailable');
      service.failure = null;
      expect(await model.signInWithGoogle(), isTrue);
    },
  );
}
