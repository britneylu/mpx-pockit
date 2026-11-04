import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/account.dart';
import '../services/auth_service.dart';

// expose a read only snapshot of authentication state
@immutable
class AuthState {
  const AuthState({
    this.account,
    this.initializing = false,
    this.busy = false,
    this.error,
    this.message,
  });
  final Account? account;
  final bool initializing;
  final bool busy;
  final String? error;
  final String? message;
}

// coordinate session updates and authentication actions
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._service) {
    reconnect();
  }
  final AuthService _service;
  AuthState _state = const AuthState(initializing: true);
  AuthState get state => _state;
  StreamSubscription<Account?>? _subscription;
  bool _disposed = false;
  // publish state changes while the viewmodel is active
  void _emit(AuthState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  // replace the session listener and restore the current account
  void reconnect() {
    _subscription?.cancel();
    _emit(AuthState(account: _state.account, initializing: true));
    _subscription = _service.accountChanges.listen(
      (account) {
        _emit(AuthState(account: account));
      },
      onError: (Object error) {
        _emit(
          const AuthState(
            error: 'Couldn’t restore your session. Please retry.',
          ),
        );
      },
    );
  }

  // track progress and feedback for authentication requests
  Future<bool> _run(Future<void> Function() action, {String? message}) async {
    if (_state.busy || _state.initializing) return false;
    _emit(AuthState(account: _state.account, busy: true));
    try {
      await action();
      _emit(AuthState(account: _state.account, message: message));
      return true;
    } on AuthCancelled {
      _emit(AuthState(account: _state.account));
    } on AuthFailure catch (error) {
      _emit(AuthState(account: _state.account, error: error.message));
    } catch (_) {
      _emit(
        AuthState(
          account: _state.account,
          error: 'Couldn’t complete that action. Please retry.',
        ),
      );
    }
    return false;
  }

  Future<bool> signIn(String email, String password) =>
      _run(() => _service.signIn(email.trim(), password));
  Future<bool> register(String email, String password) =>
      _run(() => _service.register(email.trim(), password));
  Future<bool> signInWithGoogle() => _run(_service.signInWithGoogle);
  Future<bool> signOut() => _run(_service.signOut);
  Future<bool> resetPassword(String email) => _run(
    () => _service.resetPassword(email.trim()),
    message:
        'If an account exists for this email, you’ll receive a reset link.',
  );
  void clearFeedback() => _emit(AuthState(account: _state.account));
  @override
  // stop listening when this viewmodel is removed
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
