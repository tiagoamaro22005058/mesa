import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `Block` is ours (§3's glossary name) and also go_router's, so its import is
// narrowed rather than the domain model renamed.
import 'package:go_router/go_router.dart' hide Block;
import 'package:mesa/core/formatters/exercise_display.dart';
import 'package:mesa/core/formatters/weight_format.dart';
import 'package:mesa/core/ids.dart';
import 'package:mesa/core/validation/validators.dart';
import 'package:mesa/domain/models/block.dart';
import 'package:mesa/domain/models/day.dart';
import 'package:mesa/domain/models/exercise.dart';
import 'package:mesa/domain/models/set_scheme.dart';
import 'package:mesa/features/catalog/providers/catalog_providers.dart';
import 'package:mesa/features/programs/presentation/widgets/confirm.dart';
import 'package:mesa/features/programs/presentation/widgets/exercise_picker_sheet.dart';
import 'package:mesa/features/programs/presentation/widgets/rpe_dropdown.dart';
import 'package:mesa/features/programs/providers/program_providers.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// Creates or edits one block: the exercise, its set scheme, its notes and its
/// ordered alternatives (F3).
///
/// [blockId] is null when adding.
class BlockFormScreen extends ConsumerWidget {
  const BlockFormScreen({
    required this.programId,
    required this.dayId,
    this.blockId,
    super.key,
  });

  final String programId;
  final String dayId;
  final String? blockId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final days = ref.watch(programDaysProvider(programId));
    final day = ref.watch(dayByIdProvider(programId, dayId));

    if (days.isLoading && !days.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (day == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.dayNotFound)),
      );
    }

    Block? existing;
    if (blockId != null) {
      for (final block in day.blocks) {
        if (block.blockId == blockId) existing = block;
      }
      if (existing == null) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(l10n.exerciseNotFound)),
        );
      }
    }

    return _Form(
      // Rebuilt when the block identity changes, so a draft is never carried
      // across to a different block.
      key: ValueKey(existing?.blockId ?? 'new'),
      programId: programId,
      day: day,
      existing: existing,
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({
    required this.programId,
    required this.day,
    required this.existing,
    super.key,
  });

  final String programId;
  final Day day;
  final Block? existing;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _sets;
  late final TextEditingController _repMin;
  late final TextEditingController _repMax;
  late final TextEditingController _rest;
  late final TextEditingController _notes;

  late double _rpeTarget;
  String? _exerciseId;
  bool _isCustom = false;
  late List<String> _alternativeExerciseIds;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    // A new block starts from the previous block's prescription rather than
    // §4's example (F3's five-minute criterion). Measured at M3: retyping the
    // scheme was 6 of the 11 taps a block costs, the single largest cost in
    // the flow. Adjacent exercises in a day rarely share a scheme outright,
    // but they sit closer to each other than to a fixed default, so this
    // reduces how many fields are edited rather than removing the step.
    final scheme =
        existing?.setScheme ?? widget.day.blocks.lastOrNull?.setScheme ?? const SetScheme();

    _sets = TextEditingController(text: '${scheme.sets}');
    _repMin = TextEditingController(text: '${scheme.repMin}');
    _repMax = TextEditingController(text: '${scheme.repMax}');
    _rest = TextEditingController(text: '${scheme.restSec}');
    _notes = TextEditingController(text: existing?.notes ?? '');
    _rpeTarget = scheme.rpeTarget;
    _exerciseId = existing?.exerciseId;
    _isCustom = existing?.isCustom ?? false;
    _alternativeExerciseIds = [...?existing?.alternativeExerciseIds];
  }

  @override
  void dispose() {
    _sets.dispose();
    _repMin.dispose();
    _repMax.dispose();
    _rest.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final busy = ref.watch(programControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? l10n.blockNewTitle : l10n.blockEditTitle,
        ),
        actions: [
          if (widget.existing != null)
            IconButton(
              onPressed: busy ? null : _delete,
              tooltip: l10n.commonRemove,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.blockExerciseLabel, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              _ExerciseField(
                exerciseId: _exerciseId,
                onPick: busy ? null : _pickExercise,
              ),
              const SizedBox(height: 24),

              Text(l10n.blockSchemeHeading, style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),

              _CountField(
                controller: _sets,
                label: l10n.blockSetsLabel,
                enabled: !busy,
                validator: (value) => Validators.positiveInt(l10n, value),
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CountField(
                      controller: _repMin,
                      label: l10n.blockRepMinLabel,
                      enabled: !busy,
                      validator: (value) => Validators.positiveInt(l10n, value),
                      onChanged: _onRepMinChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CountField(
                      controller: _repMax,
                      label: l10n.blockRepMaxLabel,
                      enabled: !busy,
                      validator: (value) =>
                          Validators.repMax(l10n, value, _repMin.text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              RpeDropdown(
                label: l10n.blockRpeLabel,
                helperText: l10n.blockRpeHint,
                value: _rpeTarget,
                enabled: !busy,
                onChanged: (value) => setState(() => _rpeTarget = value),
              ),
              const SizedBox(height: 16),

              _CountField(
                controller: _rest,
                label: l10n.blockRestLabel,
                enabled: !busy,
                validator: (value) => Validators.restSeconds(l10n, value),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _notes,
                enabled: !busy,
                decoration: InputDecoration(
                  labelText: l10n.blockNotesLabel,
                  border: const OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 5,
              ),
              const SizedBox(height: 24),

              Text(l10n.blockAlternativesHeading, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              // §F7 will also compute suggestions, in M7. This is the manual
              // list, which §F7 says always outranks the computed one.
              Text(l10n.blockAlternativesHint, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              _Alternatives(
                exerciseIds: _alternativeExerciseIds,
                onRemove: (id) => setState(() => _alternativeExerciseIds.remove(id)),
                onReorder: (reordered) =>
                    setState(() => _alternativeExerciseIds = reordered),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : _addAlternative,
                icon: const Icon(Icons.add),
                label: Text(l10n.blockAddAlternative),
              ),
              const SizedBox(height: 24),

              // NFR4: the commit action in the bottom third, thumb-reachable.
              FilledButton(
                onPressed: busy ? null : _save,
                child: Text(l10n.commonSave),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Carries the top of the rep range up when the bottom passes it.
  ///
  /// Carrying the previous block's scheme forward made this worth handling
  /// rather than rejecting. Every new block now inherits a narrow range, so
  /// widening 6-8 to 12-20 means typing a `repMin` that is momentarily above
  /// the inherited `repMax` — which failed validation on save, pointed at the
  /// field the user had not touched, and cost a second trip through the form.
  /// Raising the top to match is the reading that matches the intent: nobody
  /// typing 12 into the bottom of a range means to leave the top at 8.
  void _onRepMinChanged(String value) {
    final min = parseCount(value);
    final max = parseCount(_repMax.text);

    if (min != null && max != null && min > max) {
      _repMax.text = '$min';
    }
    _formKey.currentState?.validate();
  }

  Future<void> _pickExercise() async {
    final exercise = await ExercisePickerSheet.show(context);
    if (exercise == null) return;

    setState(() {
      _exerciseId = exercise.id;
      // Derived from the picked exercise, never typed. §4 stores it so a day
      // document says where to resolve the id without loading the catalogue.
      _isCustom = exercise.isCustom;
    });
  }

  Future<void> _addAlternative() async {
    final exercise = await ExercisePickerSheet.show(context);
    if (exercise == null) return;

    setState(() {
      // The list is a preference ranking, so a duplicate would be two rankings
      // for one exercise.
      if (!_alternativeExerciseIds.contains(exercise.id)) {
        _alternativeExerciseIds.add(exercise.id);
      }
    });
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final existing = widget.existing;
    if (existing == null) return;

    final exercise = ref.read(exerciseByIdProvider(existing.exerciseId)).value;
    final name = exercise == null
        ? l10n.blockExerciseMissing
        : exerciseTitle(exercise.name);

    final proceed = await confirm(
      context,
      title: l10n.blockDeleteTitle,
      body: l10n.blockDeleteBody(name),
      confirmLabel: l10n.commonRemove,
    );
    if (!proceed) return;

    await ref
        .read(programControllerProvider.notifier)
        .deleteBlock(widget.programId, widget.day, existing.blockId);
    if (!mounted) return;

    messenger.showSnackBar(SnackBar(content: Text(l10n.blockDeleted)));
    if (router.canPop()) router.pop();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final exerciseId = _exerciseId;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    // A block with no exercise cannot be saved, and the picker is not a
    // TextFormField, so the Form cannot say so on its own.
    if (exerciseId == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.blockChooseExercise)));
      return;
    }

    final notes = _notes.text.trim();
    final block = Block(
      blockId: widget.existing?.blockId ?? newId('block'),
      exerciseId: exerciseId,
      isCustom: _isCustom,
      setScheme: SetScheme(
        sets: parseCount(_sets.text) ?? SetScheme.defaultSets,
        repMin: parseCount(_repMin.text) ?? SetScheme.defaultRepMin,
        repMax: parseCount(_repMax.text) ?? SetScheme.defaultRepMax,
        rpeTarget: _rpeTarget,
        restSec: parseCount(_rest.text) ?? SetScheme.defaultRestSec,
      ),
      alternativeExerciseIds: [..._alternativeExerciseIds],
      notes: notes.isEmpty ? null : notes,
    );

    await ref
        .read(programControllerProvider.notifier)
        .saveBlock(widget.programId, widget.day, block);
    if (!mounted) return;

    // Editing one block is a single errand: confirm it and leave.
    if (widget.existing != null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.blockSaved)));
      if (router.canPop()) router.pop();
      return;
    }

    // Adding is a loop, so stay and offer the next exercise straight away
    // rather than returning to the day editor to be told to add another
    // (F3's five-minute criterion). Measured at M3: the round trip out and
    // back in cost two taps and about 1.1 s of animation per block.
    //
    // No snackbar here — the picker opens over it immediately, and the day
    // editor lists everything that landed once the loop ends.
    setState(() {
      _exerciseId = null;
      _isCustom = false;
      _alternativeExerciseIds = [];
      _notes.clear();
      // The scheme deliberately stays as typed: it is what the next block
      // inherits.
    });

    final next = await ExercisePickerSheet.show(context);
    if (!mounted) return;

    // Dismissing the picker is how the user says they are done adding.
    if (next == null) {
      if (router.canPop()) router.pop();
      return;
    }

    setState(() {
      _exerciseId = next.id;
      _isCustom = next.isCustom;
    });
  }
}

/// The chosen exercise, or the prompt to choose one.
class _ExerciseField extends ConsumerWidget {
  const _ExerciseField({required this.exerciseId, required this.onPick});

  final String? exerciseId;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final id = exerciseId;
    final exercise = id == null ? null : ref.watch(exerciseByIdProvider(id)).value;

    final label = switch ((id, exercise)) {
      (null, _) => l10n.blockChooseExercise,
      (_, null) => l10n.blockExerciseMissing,
      (_, final Exercise found) => exerciseTitle(found.name),
    };

    return OutlinedButton.icon(
      onPressed: onPick,
      icon: const Icon(Icons.fitness_center),
      label: Align(alignment: Alignment.centerLeft, child: Text(label)),
      style: OutlinedButton.styleFrom(
        // NFR4: a full-width, 56 dp target rather than a text-sized one.
        minimumSize: const Size.fromHeight(56),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

/// The block's substitutes, in the user's preference order.
class _Alternatives extends ConsumerWidget {
  const _Alternatives({
    required this.exerciseIds,
    required this.onRemove,
    required this.onReorder,
  });

  final List<String> exerciseIds;
  final ValueChanged<String> onRemove;
  final ValueChanged<List<String>> onReorder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (exerciseIds.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exerciseIds.length,
      // `onReorderItem` already adjusts for the item leaving its old slot.
      onReorderItem: (oldIndex, newIndex) {
        final reordered = [...exerciseIds];
        reordered.insert(newIndex, reordered.removeAt(oldIndex));
        onReorder(reordered);
      },
      itemBuilder: (context, position) {
        final id = exerciseIds[position];
        final exercise = ref.watch(exerciseByIdProvider(id)).value;

        return ListTile(
          key: ValueKey(id),
          dense: true,
          title: Text(
            exercise == null
                ? l10n.blockExerciseMissing
                : exerciseTitle(exercise.name),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => onRemove(id),
                tooltip: l10n.commonRemove,
                icon: const Icon(Icons.close),
              ),
              ReorderableDragStartListener(
                index: position,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.drag_handle),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A whole-number field: sets, reps, rest seconds.
///
/// Accepts a comma as well as a dot, because the parser behind it does (§9.1) —
/// a field that rejected what `parseCount` accepts would be lying about it.
class _CountField extends StatelessWidget {
  const _CountField({
    required this.controller,
    required this.label,
    required this.validator,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String> validator;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      validator: validator,
      onChanged: onChanged,
      // Every one of these fields arrives pre-filled — from §4's example, or
      // from the previous block. Without this, tapping one drops a caret after
      // the digits and changing `12` to `8` costs two backspaces before the
      // keystroke that matters. Selecting on focus makes an edit a type.
      onTap: () => controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      ),
    );
  }
}
