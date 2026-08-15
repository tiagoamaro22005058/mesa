import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mesa/app/router.dart';
import 'package:mesa/core/validation/validators.dart';
import 'package:mesa/features/auth/presentation/auth_failure_message.dart';
import 'package:mesa/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:mesa/features/auth/providers/auth_providers.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// Password reset request (F1).
class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  /// Set once a request has gone through, so the screen can confirm without
  /// navigating away from the address the user just typed.
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    await controller.sendPasswordReset(_email.text);

    if (!mounted) return;
    if (!ref.read(authControllerProvider).hasError) {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(authControllerProvider);
    final busy = state.isLoading;
    final message = state.hasError ? authFailureMessage(l10n, state.error!) : null;

    return AuthScaffold(
      title: l10n.authResetTitle,
      children: [
        if (message != null) AuthErrorBanner(message: message),
        Text(l10n.authResetInstructions),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          child: TextFormField(
            controller: _email,
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.authEmailLabel,
              border: const OutlineInputBorder(),
            ),
            validator: (value) => Validators.email(l10n, value),
            onFieldSubmitted: (_) => busy ? null : _submit(),
          ),
        ),
        if (_sent) ...[
          const SizedBox(height: 16),
          Semantics(liveRegion: true, child: Text(l10n.authResetSent)),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: busy ? null : _submit,
          child: busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.authResetTitle),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: busy ? null : () => context.goNamed(Routes.signIn),
          child: Text(l10n.authSignInTitle),
        ),
      ],
    );
  }
}
