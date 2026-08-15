import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mesa/app/router.dart';
import 'package:mesa/core/validation/validators.dart';
import 'package:mesa/features/auth/presentation/auth_failure_message.dart';
import 'package:mesa/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mesa/features/auth/providers/auth_providers.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// Email/password sign-in, with Google Sign-In alongside it (F1).
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authControllerProvider.notifier)
        .signIn(email: _email.text, password: _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(authControllerProvider);
    final busy = state.isLoading;
    final message = state.hasError ? authFailureMessage(l10n, state.error!) : null;

    return AuthScaffold(
      title: l10n.authSignInTitle,
      children: [
        if (message != null) AuthErrorBanner(message: message),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _email,
                enabled: !busy,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.authEmailLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => Validators.email(l10n, value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                enabled: !busy,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.authPasswordLabel,
                  border: const OutlineInputBorder(),
                ),
                // Only presence is checked here. Rejecting a short password on
                // sign-in would lock out anyone whose account predates the
                // current minimum.
                validator: (value) => (value ?? '').isEmpty
                    ? l10n.validationPasswordRequired
                    : null,
                onFieldSubmitted: (_) => busy ? null : _submit(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: busy ? null : _submit,
          child: busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.authSignInTitle),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: busy
              ? null
              : () => ref.read(authControllerProvider.notifier).signInWithGoogle(),
          icon: const Icon(Icons.account_circle_outlined),
          label: Text(l10n.authGoogleButton),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: busy ? null : () => context.goNamed(Routes.signUp),
          child: Text(l10n.authNoAccountPrompt),
        ),
        TextButton(
          onPressed: busy ? null : () => context.goNamed(Routes.passwordReset),
          child: Text(l10n.authForgotPasswordPrompt),
        ),
      ],
    );
  }
}
