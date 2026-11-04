import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';

// display sign in registration and password reset controls
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _obscure = true;
  String? _emailError(String? value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Enter a valid email address.';
  // validate the form before requesting authentication
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // observe authentication progress and feedback
    final model = context.read<AuthViewModel>();
    if (_register) {
      await model.register(_email.text, _password.text);
    } else {
      await model.signIn(_email.text, _password.text);
    }
  }

  @override
  // release the email and password controllers
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<AuthViewModel>();
    final state = model.state;
    return Scaffold(
      appBar: AppBar(title: const Text('Your account')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AutofillGroup(
              child: Form(
                key: _form,
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      'pockit.',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _register ? 'Make yourself at home.' : 'Welcome back.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('Your money, wherever you go.'),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to save expenses across sessions. Your guest expenses will transfer to your account.',
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      key: const Key('authEmail'),
                      controller: _email,
                      enabled: !state.busy,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: _emailError,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('authPassword'),
                      controller: _password,
                      enabled: !state.busy,
                      obscureText: _obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: [
                        _register
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Enter your password.'
                          : _register && value.length < 6
                          ? 'Use at least 6 characters.'
                          : null,
                      onFieldSubmitted: state.busy ? null : (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    if (state.error != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          state.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (state.message != null)
                      Semantics(liveRegion: true, child: Text(state.message!)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: state.busy ? null : _submit,
                      child: Text(
                        state.busy
                            ? 'Please wait…'
                            : _register
                            ? 'Create account'
                            : 'Sign in',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // google authentication does not require the email form fields
                    OutlinedButton.icon(
                      key: const Key('googleSignIn'),
                      onPressed: state.busy
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              model.signInWithGoogle();
                            },
                      icon: const Icon(Icons.login),
                      label: const Text('Continue with Google'),
                    ),
                    TextButton(
                      onPressed: state.busy
                          ? null
                          : () {
                              model.clearFeedback();
                              _password.clear();
                              _form.currentState!.reset();
                              setState(() => _register = !_register);
                            },
                      child: Text(
                        _register
                            ? 'Already have an account? Sign in'
                            : 'New here? Create an account',
                      ),
                    ),
                    if (!_register)
                      TextButton(
                        onPressed: state.busy
                            ? null
                            : () {
                                if (_emailError(_email.text) != null) {
                                  _form.currentState!.validate();
                                  return;
                                }
                                model.resetPassword(_email.text);
                              },
                        child: const Text('Forgot password?'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
