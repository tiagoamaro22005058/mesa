import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mesa/app/router.dart';
import 'package:mesa/core/validation/validators.dart';
import 'package:mesa/features/auth/presentation/auth_failure_message.dart';
import 'package:mesa/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mesa/features/auth/providers/auth_providers.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// Email/password sign-up (F1).
///
/// The display name collected here seeds the profile document, so the user is
/// never dropped into the app with a blank profile.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    _displayName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authControllerProvider.notifier)
        .signUp(
          email: _email.text,
          password: _password.text,
          displayName: _displayName.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(authControllerProvider);
    final busy = state.isLoading;
    final message = state.hasError ? authFailureMessage(l10n, state.error!) : null;

    return AuthScaffold(
      title: l10n.authSignUpTitle,
      children: [
        if (message != null) AuthErrorBanner(message: message),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _displayName,
                enabled: !busy,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.authDisplayNameLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => Validators.displayName(l10n, value),
              ),
              const SizedBox(height: 16),
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
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.authPasswordLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => Validators.password(l10n, value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPassword,
                enabled: !busy,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.authConfirmPasswordLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => Validators.passwordConfirmation(
                  l10n,
                  value,
                  _password.text,
                ),
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
              : Text(l10n.authSignUpTitle),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: busy ? null : () => context.goNamed(Routes.signIn),
          child: Text(l10n.authHaveAccountPrompt),
        ),
      ],
    );
  }
}
