// firebase client configuration reconstructed from this project's registered apps
// these are client identifiers, not administrative credentials
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  // select the registered app for this platform
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError(
        'Firebase is configured for iOS, Android, and Web. Run flutterfire configure to add this platform.',
      ),
    };
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDTN7-e5azeMNnXaIC8f2Km7zixfoJVyyo",
    appId: "1:683695534295:web:9515dcd655675e8c9c0092",
    messagingSenderId: "683695534295",
    projectId: "pockit-90b0e",
    authDomain: "pockit-90b0e.firebaseapp.com",
    storageBucket: "pockit-90b0e.firebasestorage.app",
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyDhEXtCEA0oixSThjUuUg9WGHTPBignakg",
    appId: "1:683695534295:android:aabd657cc15583189c0092",
    messagingSenderId: "683695534295",
    projectId: "pockit-90b0e",
    storageBucket: "pockit-90b0e.firebasestorage.app",
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyBWvzT_HeKMrcjGAZfN_EpZqSdE3-mguLE",
    appId: "1:683695534295:ios:0bd0df855a04ba4e9c0092",
    messagingSenderId: "683695534295",
    projectId: "pockit-90b0e",
    storageBucket: "pockit-90b0e.firebasestorage.app",
    iosBundleId: "com.example.pockit",
  );
}
