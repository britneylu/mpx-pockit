import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/account.dart';

// keep authentication operations independent of firebase
abstract interface class AuthService {
  // convert firebase session updates into app account data
  Stream<Account?> get accountChanges;
  Future<void> signIn(String email, String password);
  Future<void> register(String email, String password);
  Future<void> signOut();
  Future<void> signInWithGoogle();
  Future<void> resetPassword(String email);
}

// treat a dismissed account chooser as a cancelled action
class AuthCancelled implements Exception {
  const AuthCancelled();
}

// carry a readable authentication error to the viewmodel
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
}

// wrap firebase authentication behind the service interface
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;
  static Future<void>? _googleInitialization;
  @override
  Stream<Account?> get accountChanges => _auth.authStateChanges().map(
    (user) =>
        user == null ? null : Account(id: user.uid, email: user.email ?? ''),
  );

  // translate firebase errors into messages for the user
  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      if (error.code == 'popup-closed-by-user' ||
          error.code == 'cancelled-popup-request') {
        throw const AuthCancelled();
      }
      throw AuthFailure(switch (error.code) {
        'invalid-email' => 'Enter a valid email address.',
        'weak-password' =>
          'Choose a stronger password with at least 6 characters.',
        'email-already-in-use' =>
          'An account already uses this email. Try signing in.',
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'The email or password is incorrect.',
        'user-disabled' => 'This account has been disabled.',
        'network-request-failed' => 'Check your internet connection and retry.',
        'too-many-requests' =>
          'Too many attempts. Please wait before trying again.',
        'operation-not-allowed' =>
          'Enable this sign-in provider in Firebase Authentication.',
        'account-exists-with-different-credential' =>
          'Use the original sign-in method for this email address.',
        'popup-blocked' =>
          'Allow pop-ups for this site, then retry Google sign-in.',
        'unauthorized-domain' =>
          'This site needs to be added to Firebase authorized domains.',
        _ => 'Authentication is unavailable. Please retry.',
      });
    } on MissingPluginException {
      throw const AuthFailure(
        'Google sign-in needs an updated app build. Fully stop the app and run it again.',
      );
    } on PlatformException catch (error) {
      if (error.code == 'channel-error') {
        throw const AuthFailure(
          'Google sign-in needs an updated app build. Fully stop the app and run it again.',
        );
      }
      throw AuthFailure(
        'Google sign-in couldn’t start (${error.code}). Please restart the app and retry.',
      );
    }
  }

  @override
  // sign in with an existing email and password
  Future<void> signIn(String email, String password) => _run(() async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  });
  @override
  // create a new email and password account
  Future<void> register(String email, String password) => _run(() async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  });
  @override
  // end the current firebase session
  Future<void> signOut() => _run(() async {
    await _auth.signOut();
    // clear the native account selection without blocking firebase sign out
    if (!kIsWeb && _googleInitialization != null) {
      try {
        await _googleInitialization;
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // firebase has already ended the session
      }
    }
  });

  @override
  // use a browser popup on web and the native account chooser on mobile
  Future<void> signInWithGoogle() => _run(() async {
    if (kIsWeb) {
      await _auth.signInWithPopup(
        GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'}),
      );
      return;
    }
    try {
      await (_googleInitialization ??= GoogleSignIn.instance.initialize());
      final account = await GoogleSignIn.instance.authenticate();
      final token = account.authentication.idToken;
      if (token == null) {
        throw const AuthFailure(
          'Google didn’t return a sign-in token. Please retry.',
        );
      }
      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: token),
      );
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthCancelled();
      }
      throw const AuthFailure(
        'Couldn’t sign in with Google. Check your connection and Google sign-in configuration.',
      );
    }
  });
  @override
  // send a password reset link to the supplied email
  Future<void> resetPassword(String email) =>
      _run(() => _auth.sendPasswordResetEmail(email: email));
}
