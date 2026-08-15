import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mesa/app/router.dart';
import 'package:mesa/features/auth/providers/auth_providers.dart';
import 'package:mesa/features/settings/providers/profile_providers.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// The authenticated landing screen.
///
/// Still a placeholder for the training content that arrives from M2 onward;
/// what it proves today is that a session survives a restart and that the
/// profile document belongs to this account and no other (F1).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    // Prefers the profile's name over the auth account's: it is the one the
    // user can actually edit.
    final profileName = ref.watch(userProfileProvider).value?.displayName;
    final authUser = ref.watch(authStateProvider).value;
    final name = (profileName != null && profileName.isNotEmpty)
        ? profileName
        : (authUser?.email ?? '');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                l10n.homeGreeting(name),
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.homePlaceholderBody,
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // NFR4: the actions sit in the bottom third, within thumb reach.
              FilledButton.icon(
                onPressed: () => context.goNamed(Routes.profile),
                icon: const Icon(Icons.person_outline),
                label: Text(l10n.homeProfileAction),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                icon: const Icon(Icons.logout),
                label: Text(l10n.homeSignOutAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
