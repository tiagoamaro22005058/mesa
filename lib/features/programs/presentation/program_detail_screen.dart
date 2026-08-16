import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mesa/app/router.dart';
import 'package:mesa/domain/models/day.dart';
import 'package:mesa/domain/models/program.dart';
import 'package:mesa/features/programs/presentation/program_labels.dart';
import 'package:mesa/features/programs/presentation/widgets/confirm.dart';
import 'package:mesa/features/programs/providers/program_providers.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// One program: its week roles, its days, and what can be done to it (F3).
class ProgramDetailScreen extends ConsumerWidget {
  const ProgramDetailScreen({required this.programId, super.key});

  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final programs = ref.watch(programsProvider);
    final program = ref.watch(programByIdProvider(programId));

    // Loading and gone are different states. Showing "no longer exists" before
    // the first snapshot lands would flash an error on every deep link.
    if (programs.isLoading && !programs.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (program == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.programNotFound)),
      );
    }

    return _Detail(program: program);
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.program});

  final Program program;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final days = ref.watch(programDaysProvider(program.id)).value ?? const <Day>[];
    final busy = ref.watch(programControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(program.name),
        actions: [
          PopupMenuButton<_Action>(
            onSelected: (action) => _run(context, ref, action, days),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _Action.edit,
                child: Text(l10n.programEditAction),
              ),
              PopupMenuItem(
                value: _Action.duplicate,
                child: Text(l10n.commonDuplicate),
              ),
              if (program.status != ProgramStatus.archived)
                PopupMenuItem(
                  value: _Action.archive,
                  child: Text(l10n.programArchive),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            ListTile(
              title: Text(ProgramLabels.status(l10n, program.status)),
              subtitle: Text(
                [
                  if (program.goal != null) program.goal!,
                  l10n.programDayCount(days.length),
                ].join(' · '),
              ),
              leading: Icon(
                program.isActive ? Icons.play_circle : Icons.description_outlined,
                color: program.isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),

            ListTile(
              title: Text(l10n.weekRolesTitle),
              subtitle: Text(l10n.weekRoleCount(program.weekRoles.length)),
              trailing: const Icon(Icons.chevron_right),
              minTileHeight: 64,
              onTap: () => context.goNamed(
                Routes.weekRoles,
                pathParameters: {'programId': program.id},
              ),
            ),
            const Divider(),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(l10n.programDaysHeading, style: theme.textTheme.titleMedium),
            ),
            if (days.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(l10n.programDaysHint, style: theme.textTheme.bodySmall),
              ),

            _Days(program: program, days: days),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: OutlinedButton.icon(
                onPressed: busy ? null : () => _addDay(context, ref),
                icon: const Icon(Icons.add),
                label: Text(l10n.programAddDay),
              ),
            ),
          ],
        ),
      ),
      // NFR4: the action that matters most, within thumb reach.
      floatingActionButton: program.isActive
          ? null
          : FloatingActionButton.extended(
              onPressed: busy ? null : () => _activate(context, ref),
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.programActivate),
            ),
    );
  }

  Future<void> _addDay(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final router = GoRouter.of(context);

    final day = await ref
        .read(programControllerProvider.notifier)
        .addDay(program.id, l10n.dayNewName);
    if (day == null) return;

    router.goNamed(
      Routes.dayEditor,
      pathParameters: {'programId': program.id, 'dayId': day.id},
    );
  }

  Future<void> _activate(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(programControllerProvider.notifier);
    final current = ref.read(activeProgramProvider);

    // Activation displaces whatever held the slot, so it is confirmed when
    // there is something to displace — exactly one program may be active (F3)
    // and the user should not discover that by losing their place.
    if (current != null && current.id != program.id) {
      final proceed = await confirm(
        context,
        title: l10n.programActivateTitle,
        body: l10n.programActivateReplaces(current.name),
        confirmLabel: l10n.programActivate,
        destructive: false,
      );
      if (!proceed) return;
    }

    await controller.activateProgram(program);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.programActivated(program.name))),
    );
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    _Action action,
    List<Day> days,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final controller = ref.read(programControllerProvider.notifier);

    switch (action) {
      case _Action.edit:
        router.goNamed(
          Routes.programEdit,
          pathParameters: {'programId': program.id},
        );

      case _Action.duplicate:
        final name = l10n.programCopyName(program.name);
        final copyId = await controller.duplicateProgram(program, name: name);
        if (copyId == null) return;

        messenger.showSnackBar(SnackBar(content: Text(l10n.programDuplicated(name))));
        router.goNamed(
          Routes.programDetail,
          pathParameters: {'programId': copyId},
        );

      case _Action.archive:
        final proceed = await confirm(
          context,
          title: l10n.programArchiveTitle,
          body: l10n.programArchiveBody(program.name),
          confirmLabel: l10n.programArchive,
        );
        if (!proceed) return;

        await controller.archiveProgram(program);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.programArchived(program.name))),
        );
        router.goNamed(Routes.programs);
    }
  }
}

class _Days extends ConsumerWidget {
  const _Days({required this.program, required this.days});

  final Program program;
  final List<Day> days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (days.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(
          l10n.programDayCount(0),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      // `onReorderItem`, not the deprecated `onReorder`: it reports the
      // destination index already adjusted for the item having left its old
      // slot, so the off-by-one correction every `onReorder` had to make by
      // hand is gone. Re-adding it here would move an item dragged downwards
      // one place short.
      onReorderItem: (oldIndex, newIndex) {
        final reordered = [...days];
        reordered.insert(newIndex, reordered.removeAt(oldIndex));
        ref.read(programControllerProvider.notifier).reorderDays(program.id, reordered);
      },
      itemBuilder: (context, position) {
        final day = days[position];

        return ListTile(
          key: ValueKey(day.id),
          title: Text(day.name),
          subtitle: Text(l10n.programBlockCount(day.blocks.length)),
          // NFR4: a 48 dp handle, not a hairline.
          trailing: ReorderableDragStartListener(
            index: position,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.drag_handle),
            ),
          ),
          minTileHeight: 64,
          onTap: () => context.goNamed(
            Routes.dayEditor,
            pathParameters: {'programId': program.id, 'dayId': day.id},
          ),
        );
      },
    );
  }
}

enum _Action { edit, duplicate, archive }
