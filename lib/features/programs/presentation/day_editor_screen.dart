import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Block` is ours (§3's glossary name) and also go_router's, so its import is
// narrowed rather than the domain model renamed.
import 'package:go_router/go_router.dart' hide Block;
import 'package:mesa/app/router.dart';
import 'package:mesa/core/formatters/exercise_display.dart';
import 'package:mesa/domain/models/block.dart';
import 'package:mesa/domain/models/day.dart';
import 'package:mesa/features/catalog/providers/catalog_providers.dart';
import 'package:mesa/features/programs/presentation/program_labels.dart';
import 'package:mesa/features/programs/presentation/widgets/confirm.dart';
import 'package:mesa/features/programs/providers/program_providers.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// One day template: its name and its ordered exercise blocks (F3).
class DayEditorScreen extends ConsumerWidget {
  const DayEditorScreen({required this.programId, required this.dayId, super.key});

  final String programId;
  final String dayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final days = ref.watch(programDaysProvider(programId));
    final day = ref.watch(dayByIdProvider(programId, dayId));

    // Loading and gone are different states. Showing "no longer exists" before
    // the first snapshot lands would flash an error on every deep link.
    if (days.isLoading && !days.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (day == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.dayNotFound)),
      );
    }

    return _Editor(programId: programId, day: day);
  }
}

class _Editor extends ConsumerWidget {
  const _Editor({required this.programId, required this.day});

  final String programId;
  final Day day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final busy = ref.watch(programControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(day.name),
        actions: [
          PopupMenuButton<_Action>(
            onSelected: (action) => _run(context, ref, action),
            itemBuilder: (context) => [
              PopupMenuItem(value: _Action.rename, child: Text(l10n.dayRename)),
              PopupMenuItem(value: _Action.duplicate, child: Text(l10n.commonDuplicate)),
              PopupMenuItem(value: _Action.delete, child: Text(l10n.commonDelete)),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: day.blocks.isEmpty
            ? const _Empty()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (day.blocks.length > 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(l10n.dayBlocksHint, style: theme.textTheme.bodySmall),
                    ),
                  Expanded(
                    child: ReorderableListView.builder(
                      // Room for the FAB to sit over, so the last row stays
                      // reachable.
                      padding: const EdgeInsets.only(top: 8, bottom: 88),
                      itemCount: day.blocks.length,
                      // `onReorderItem` reports the destination already
                      // adjusted for the item having left its old slot, unlike
                      // the deprecated `onReorder`. Correcting it again here
                      // would drop a block one place short of where it was
                      // dragged.
                      onReorderItem: (oldIndex, newIndex) {
                        final reordered = [...day.blocks];
                        reordered.insert(newIndex, reordered.removeAt(oldIndex));
                        ref
                            .read(programControllerProvider.notifier)
                            .reorderBlocks(programId, day, reordered);
                      },
                      itemBuilder: (context, position) => _BlockRow(
                        key: ValueKey(day.blocks[position].blockId),
                        programId: programId,
                        day: day,
                        block: day.blocks[position],
                        index: position,
                      ),
                    ),
                  ),
                ],
              ),
      ),
      // NFR4: within thumb reach, not in the app bar.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: busy
            ? null
            : () => context.goNamed(
                Routes.blockNew,
                pathParameters: {'programId': programId, 'dayId': day.id},
              ),
        icon: const Icon(Icons.add),
        label: Text(l10n.dayAddBlock),
      ),
    );
  }

  Future<void> _run(BuildContext context, WidgetRef ref, _Action action) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final controller = ref.read(programControllerProvider.notifier);

    switch (action) {
      case _Action.rename:
        final name = await _promptForName(context, day.name);
        if (name == null) return;

        await controller.saveDay(programId, day.copyWith(name: name));

      case _Action.duplicate:
        final name = l10n.programCopyName(day.name);
        final copy = await controller.duplicateDay(programId, day, name: name);
        if (copy == null) return;

        messenger.showSnackBar(SnackBar(content: Text(l10n.dayDuplicated(name))));
        router.goNamed(
          Routes.dayEditor,
          pathParameters: {'programId': programId, 'dayId': copy.id},
        );

      case _Action.delete:
        final proceed = await confirm(
          context,
          title: l10n.dayDeleteTitle,
          body: l10n.dayDeleteBody(day.name),
          confirmLabel: l10n.commonDelete,
        );
        if (!proceed) return;

        await controller.deleteDay(programId, day.id);
        messenger.showSnackBar(SnackBar(content: Text(l10n.dayDeleted)));

        // Back where the user came from. A deep link straight here has nothing
        // to pop, so the program is the fallback rather than a dead end.
        if (router.canPop()) {
          router.pop();
        } else {
          router.goNamed(
            Routes.programDetail,
            pathParameters: {'programId': programId},
          );
        }
    }
  }
}

/// One block row: what it is, what it prescribes, and how many substitutes it
/// carries.
class _BlockRow extends ConsumerWidget {
  const _BlockRow({
    required this.programId,
    required this.day,
    required this.block,
    required this.index,
    super.key,
  });

  final String programId;
  final Day day;
  final Block block;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final exercise = ref.watch(exerciseByIdProvider(block.exerciseId)).value;

    // A block whose exercise no longer resolves still renders — a deleted
    // custom exercise must not blank out the day around it.
    final title = exercise == null
        ? l10n.blockExerciseMissing
        : exerciseTitle(exercise.name);

    return ListTile(
      title: Text(title),
      subtitle: Text(
        [
          ProgramLabels.setScheme(l10n, block.setScheme),
          l10n.blockRestSummary(block.setScheme.restSec),
          if (block.alternativeExerciseIds.isNotEmpty)
            l10n.blockAlternativeCount(block.alternativeExerciseIds.length),
        ].join(' · '),
      ),
      minTileHeight: 64,
      trailing: ReorderableDragStartListener(
        index: index,
        // NFR4: a 48 dp handle, not a hairline.
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.drag_handle),
        ),
      ),
      onTap: () => context.goNamed(
        Routes.blockEdit,
        pathParameters: {
          'programId': programId,
          'dayId': day.id,
          'blockId': block.blockId,
        },
      ),
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
              Icons.fitness_center,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(l10n.dayEmptyTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              l10n.dayEmptyBody,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Renaming is a one-field edit, so it is a dialog rather than a screen — a
/// day called "New day" has to be cheap to fix (F3's five minutes).
Future<String?> _promptForName(BuildContext context, String current) async {
  final name = await showDialog<String>(
    context: context,
    builder: (context) => _NameDialog(initialValue: current),
  );

  return (name == null || name.isEmpty) ? null : name;
}

/// Stateful so the controller is owned by the widget that uses it.
///
/// Creating it alongside `showDialog` and disposing it when the future
/// completes does not work: the dialog's exit animation is still running at
/// that point, and the field rebuilds against a disposed controller.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initialValue});

  final String initialValue;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.dayRename),
      content: TextField(
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: l10n.dayNameLabel,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_name.text.trim()),
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

enum _Action { rename, duplicate, delete }
