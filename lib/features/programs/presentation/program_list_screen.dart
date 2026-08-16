import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mesa/app/router.dart';
import 'package:mesa/domain/models/program.dart';
import 'package:mesa/features/programs/presentation/program_labels.dart';
import 'package:mesa/features/programs/providers/program_providers.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// Every program the user owns (F3).
///
/// Reads only from the Firestore offline cache, so it lists and activates
/// without connectivity (NFR1).
class ProgramListScreen extends ConsumerStatefulWidget {
  const ProgramListScreen({super.key});

  @override
  ConsumerState<ProgramListScreen> createState() => _ProgramListScreenState();
}

class _ProgramListScreenState extends ConsumerState<ProgramListScreen> {
  /// Archived programs are hidden by default rather than dropped: F3 archives
  /// rather than deletes, so they have to stay reachable.
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final programs = ref.watch(programsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.programsTitle),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showArchived = !_showArchived),
            tooltip: l10n.programsShowArchived,
            icon: Icon(_showArchived ? Icons.archive : Icons.archive_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: switch (programs) {
          AsyncData(value: final List<Program> all) => _List(
            programs: [
              for (final program in all)
                if (_showArchived || program.status != ProgramStatus.archived) program,
            ],
          ),
          AsyncLoading() => const Center(child: CircularProgressIndicator()),
          AsyncError() => _Centred(child: Text(l10n.authErrorUnknown)),
        },
      ),
      // NFR4: within thumb reach, not in the app bar.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goNamed(Routes.programNew),
        icon: const Icon(Icons.add),
        label: Text(l10n.programsNewAction),
      ),
    );
  }
}

class _List extends ConsumerWidget {
  const _List({required this.programs});

  final List<Program> programs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (programs.isEmpty) return const _Empty();

    return ListView.builder(
      // Room for the FAB to sit over, so the last row is still reachable.
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: programs.length,
      itemBuilder: (context, position) {
        final program = programs[position];

        return ListTile(
          title: Text(program.name),
          subtitle: Text(
            [
              ProgramLabels.status(l10n, program.status),
              l10n.weekRoleCount(program.weekRoles.length),
            ].join(' · '),
          ),
          leading: Icon(
            program.isActive ? Icons.play_circle : Icons.description_outlined,
            color: program.isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          // NFR4: 48 dp of row to hit, not a 24 dp icon.
          minTileHeight: 64,
          onTap: () => context.goNamed(
            Routes.programDetail,
            pathParameters: {'programId': program.id},
          ),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(l10n.programsEmptyTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              l10n.programsEmptyBody,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Centred extends StatelessWidget {
  const _Centred({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Center(child: Padding(padding: const EdgeInsets.all(32), child: child));
}
