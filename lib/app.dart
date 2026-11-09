import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'repositories/budget_repository.dart';
import 'viewmodels/budget_viewmodel.dart';
import 'services/currency_service.dart';
import 'viewmodels/converter_viewmodel.dart';
import 'views/converter_screen.dart';
import 'views/expenses_screen.dart';
import 'repositories/expense_repository.dart';
import 'repositories/firestore_expense_repository.dart';
import 'viewmodels/guest_transfer_viewmodel.dart';
import 'services/auth_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/auth_screen.dart';
import 'views/settings_screen.dart';
import 'viewmodels/expenses_viewmodel.dart';

// create a separate expense repository for each account
typedef ExpenseRepositoryFactory = ExpenseRepository Function(String userId);

// provide authentication state to the whole app
class PockitApp extends StatelessWidget {
  const PockitApp({
    super.key,
    this.currencyService,
    this.authService,
    this.expenseRepositoryFactory,
    this.budgetRepositoryFactory,
  });
  final CurrencyService? currencyService;
  final AuthService? authService;
  final ExpenseRepositoryFactory? expenseRepositoryFactory;
  final BudgetRepository Function(String)? budgetRepositoryFactory;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => AuthViewModel(authService ?? FirebaseAuthService()),
      ),
      ChangeNotifierProvider(
        lazy: false,
        create: (context) => BudgetViewModel(
          context.read<AuthViewModel>(),
          budgetRepositoryFactory ?? (id) => FirestoreBudgetRepository(id),
        ),
      ),
      ChangeNotifierProvider(
        lazy: false,
        create: (context) => GuestTransferViewModel(
          context.read<AuthViewModel>(),
          expenseRepositoryFactory ??
              (id) => FirestoreExpenseRepository(userId: id),
        ),
      ),
    ],
    child: Consumer<AuthViewModel>(
      builder: (context, model, _) {
        final state = model.state;
        final account = state.account;
        // reset the workspace when the account changes
        return _AccountWorkspace(
          key: ValueKey(account == null ? 'guest' : 'account:${account.id}'),
          currencyService: currencyService ?? FrankfurterCurrencyService(),
          repositoryFactory:
              expenseRepositoryFactory ??
              (id) => FirestoreExpenseRepository(userId: id),
        );
      },
    ),
  );
}

// the account key destroys the previous navigator, viewmodels, and subscriptions
// on sign-out or account changes, including any open expense form
class _AccountWorkspace extends StatelessWidget {
  const _AccountWorkspace({
    super.key,
    required this.currencyService,
    required this.repositoryFactory,
  });
  final CurrencyService currencyService;
  final ExpenseRepositoryFactory repositoryFactory;
  @override
  Widget build(BuildContext context) {
    final account = context.read<AuthViewModel>().state.account;
    // use temporary guest storage or the signed in account repository
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ConverterViewModel(currencyService),
        ),
        ChangeNotifierProvider(
          create: (_) => ExpensesViewModel(
            account == null
                ? context.read<GuestTransferViewModel>().guestRepository
                : repositoryFactory(account.id),
            currencyService,
          )..load(),
        ),
      ],
      child: MaterialApp(
        title: 'Pockit',
        theme: appTheme,
        debugShowCheckedModeBanner: false,
        home: const PockitShell(),
      ),
    );
  }
}

// keep the four main tabs in one navigation shell
class PockitShell extends StatefulWidget {
  const PockitShell({super.key});
  @override
  State<PockitShell> createState() => _PockitShellState();
}

class _PockitShellState extends State<PockitShell> {
  int _index = 0;
  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_outlined),
      label: 'Expenses',
    ),
    NavigationDestination(
      icon: Icon(Icons.currency_exchange),
      label: 'Convert',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      label: 'Settings',
    ),
  ];
  // change tabs and fetch the first converter rate when needed
  void _select(int value) {
    setState(() => _index = value);
    final model = context.read<ConverterViewModel>();
    if (value == 2 && model.state.status == ConversionStatus.idle) {
      model.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final transfer = context.watch<GuestTransferViewModel>();
    final content = SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          // preserve each tab while another tab is visible
          child: IndexedStack(
            index: _index,
            children: [
              _PlaceholderPage(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Your money, wherever you go.',
                message: 'Welcome to Pockit. Your monthly overview will live here as we add expense tracking and budgets.',
                action: FilledButton.icon(
                  onPressed: () => _select(2),
                  icon: const Icon(Icons.currency_exchange),
                  label: const Text('Try the converter'),
                ),
              ),
              const ExpensesScreen(),
              const ConverterScreen(),
              const SettingsScreen(),
            ],
          ),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // use a navigation rail when the window is wide enough
        final wide = constraints.maxWidth >= 840;
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'pockit.',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1),
            ),
            centerTitle: false,
            actions: [
              if (auth.state.account == null)
                TextButton.icon(
                  key: const Key('signInButton'),
                  onPressed: auth.state.initializing
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const AuthScreen(),
                          ),
                        ),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in'),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              if (transfer.pendingCount > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      children: [
                        Text(
                          transfer.failed
                              ? 'Couldn’t transfer guest expenses. Keep the app open and retry.'
                              : 'Saving ${transfer.pendingCount} guest expenses to your account…',
                        ),
                        if (transfer.failed)
                          TextButton(
                            onPressed: transfer.retry,
                            child: const Text('Retry transfer'),
                          ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: wide
                    ? Row(
                        children: [
                          NavigationRail(
                            selectedIndex: _index,
                            onDestinationSelected: _select,
                            labelType: NavigationRailLabelType.all,
                            destinations: _destinations
                                .map(
                                  (d) => NavigationRailDestination(
                                    icon: d.icon,
                                    label: Text(d.label),
                                  ),
                                )
                                .toList(),
                          ),
                          const VerticalDivider(width: 1),
                          Expanded(child: content),
                        ],
                      )
                    : content,
              ),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  destinations: _destinations,
                ),
        );
      },
    );
  }
}

// show introductory content for unfinished features
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 32),
      Align(
        alignment: Alignment.centerLeft,
        child: CircleAvatar(
          radius: 32,
          backgroundColor: const Color(0xFFDDE9E1),
          child: Icon(
            icon,
            size: 30,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 16),
      Text(message, style: Theme.of(context).textTheme.bodyLarge),
      if (action != null) ...[
        const SizedBox(height: 24),
        Align(alignment: Alignment.centerLeft, child: action!),
      ],
    ],
  );
}
