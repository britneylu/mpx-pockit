import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/expenses_viewmodel.dart';

// show the signed in account and sign out controls
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    // check whether an expense write is still pending
    final saving = context.watch<ExpensesViewModel>().state.saving;
    // explain guest storage without requiring an account
    if (auth.state.account == null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Make room for your goals.',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          const Text('Guest mode'),
          const SizedBox(height: 8),
          const Text(
            'Explore Pockit without an account. Expenses stay in this session only and disappear when you close or restart the app. Use Sign in at the top right to save future expenses to your account.',
          ),
          const SizedBox(height: 24),
          const Text('Budget and currency preferences are coming next.'),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Make room for your goals.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        const Text('ACCOUNT'),
        const SizedBox(height: 8),
        Text(auth.state.account?.email ?? ''),
        const SizedBox(height: 8),
        const Text(
          'Your expenses are stored privately under your account in Cloud Firestore.',
        ),
        // remind the user to reconnect while a save is pending
        if (saving)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'An expense is still syncing. Keep the app open and reconnect to finish saving.',
            ),
          ),
        if (auth.state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Semantics(liveRegion: true, child: Text(auth.state.error!)),
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: auth.state.busy
              ? null
              : () async {
                  // ask before ending the session
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign out?'),
                      content: Text(
                        saving
                            ? 'An expense is still syncing. It may not have reached the cloud yet. Sign out anyway?'
                            : 'Your cloud expenses will be available when you sign in again.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) await auth.signOut();
                },
          icon: const Icon(Icons.logout),
          label: Text(auth.state.busy ? 'Signing out…' : 'Sign out'),
        ),
        const SizedBox(height: 32),
        const Text('Budget and currency preferences are coming next.'),
        const SizedBox(height: 16),
        const Text('Pockit · Your money, wherever you go.'),
      ],
    );
  }
}
