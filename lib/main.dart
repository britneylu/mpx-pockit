import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_theme.dart';
import 'firebase_options.dart';

// prepare flutter before starting firebase
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _FirebaseBootstrap());
}

// show startup progress before opening the app
class _FirebaseBootstrap extends StatefulWidget {
  const _FirebaseBootstrap();
  @override
  State<_FirebaseBootstrap> createState() => _FirebaseBootstrapState();
}

class _FirebaseBootstrapState extends State<_FirebaseBootstrap> {
  late Future<FirebaseApp> _initialization;
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  // keep the initialization future stable across rebuilds
  void _initialize() {
    _initialization = _start();
  }

  // load the firebase options for the current platform
  Future<FirebaseApp> _start() async =>
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  @override
  Widget build(BuildContext context) => FutureBuilder<FirebaseApp>(
    future: _initialization,
    builder: (context, snapshot) {
      // open the app once firebase is ready
      if (snapshot.hasData) return const PockitApp();
      return MaterialApp(
        title: 'Pockit',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: snapshot.hasError
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Couldn’t start Pockit. Check your connection and Firebase setup.',
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => setState(_initialize),
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    : const CircularProgressIndicator(
                        semanticsLabel: 'Starting Pockit',
                      ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
