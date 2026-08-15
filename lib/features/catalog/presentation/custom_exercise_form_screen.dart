import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mesa/app/router.dart';
import 'package:mesa/core/validation/validators.dart';
import 'package:mesa/domain/models/body_part.dart';
import 'package:mesa/domain/models/equipment.dart';
import 'package:mesa/domain/models/exercise.dart';
import 'package:mesa/domain/models/muscle.dart';
import 'package:mesa/features/catalog/presentation/exercise_labels.dart';
import 'package:mesa/features/catalog/providers/catalog_providers.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// Creates or edits a user-created exercise (F2).
///
/// [exerciseId] is null when creating. Editing loads the existing exercise,
/// which is why the form is built from an [AsyncValue] rather than a plain
/// object.
class CustomExerciseFormScreen extends ConsumerWidget {
  const CustomExerciseFormScreen({this.exerciseId, super.key});

  final String? exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (exerciseId == null) {
      return const _Form(existing: null);
    }

    final exercise = ref.watch(exerciseByIdProvider(exerciseId!));
    return exercise.when(
      data: (found) => found == null
          ? Scaffold(
              appBar: AppBar(),
              body: Center(child: Text(l10n.exerciseNotFound)),
            )
          : _Form(existing: found),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.catalogLoadFailed)),
      ),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.existing});

  final Exercise? existing;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _steps;
  late BodyPart _bodyPart;
  late Muscle _primaryMuscle;
  late Equipment _equipment;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _name = TextEditingController(text: existing?.name ?? '');
    _steps = TextEditingController(text: existing?.steps.join('\n') ?? '');
    _bodyPart = existing?.bodyPart ?? BodyPart.chest;
    _primaryMuscle = existing?.primaryMuscle ?? Muscle.chest;
    _equipment = existing?.equipment ?? Equipment.barbell;
  }

  @override
  void dispose() {
    _name.dispose();
    _steps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final saving = ref.watch(catalogControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? l10n.customExerciseNewTitle : l10n.customExerciseEditTitle,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: l10n.customExerciseNameLabel,
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.none,
                validator: (value) => Validators.displayName(l10n, value),
              ),
              const SizedBox(height: 16),

              _Dropdown<BodyPart>(
                label: l10n.catalogFilterBodyPart,
                value: _bodyPart,
                values: BodyPart.values,
                labelFor: (value) => ExerciseLabels.bodyPart(l10n, value),
                onChanged: (value) => setState(() => _bodyPart = value),
              ),
              const SizedBox(height: 16),

              _Dropdown<Muscle>(
                label: l10n.catalogFilterMuscle,
                value: _primaryMuscle,
                values: Muscle.values,
                labelFor: (value) => ExerciseLabels.muscle(l10n, value),
                onChanged: (value) => setState(() => _primaryMuscle = value),
              ),
              const SizedBox(height: 16),

              _Dropdown<Equipment>(
                label: l10n.catalogFilterEquipment,
                value: _equipment,
                values: Equipment.values,
                labelFor: (value) => ExerciseLabels.equipment(l10n, value),
                onChanged: (value) => setState(() => _equipment = value),
              ),
              const SizedBox(height: 8),

              // Derived, not chosen. §5.6 makes the load model a function of
              // equipment, and letting the user pick a third thing that
              // disagrees with the other two is how the M5 maths goes quietly
              // wrong. Shown so the consequence of the equipment choice is
              // visible.
              Text(
                '${l10n.customExerciseLoadModelLabel}: '
                '${ExerciseLabels.loadModel(l10n, _equipment.defaultLoadModel)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _steps,
                decoration: InputDecoration(
                  labelText: l10n.customExerciseStepsLabel,
                  helperText: l10n.customExerciseStepsHint,
                  border: const OutlineInputBorder(),
                ),
                minLines: 3,
                maxLines: 8,
              ),
              const SizedBox(height: 24),

              // NFR4: the commit action in the bottom third, thumb-reachable.
              FilledButton(
                onPressed: saving ? null : _save,
                child: Text(l10n.commonSave),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final exercise = Exercise(
      id: widget.existing?.id ?? newCustomExerciseId(),
      name: _name.text.trim(),
      bodyPart: _bodyPart,
      primaryMuscle: _primaryMuscle,
      equipment: _equipment,
      loadModel: _equipment.defaultLoadModel,
      steps: [
        for (final line in _steps.text.split('\n'))
          if (line.trim().isNotEmpty) line.trim(),
      ],
      source: ExerciseSource.custom,
    );

    await ref.read(catalogControllerProvider.notifier).saveCustomExercise(exercise);
    if (!mounted) return;

    messenger.showSnackBar(SnackBar(content: Text(l10n.customExerciseSaved)));
    router.goNamed(Routes.exerciseDetail, pathParameters: {'id': exercise.id});
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final void Function(T value) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: [
        for (final item in values)
          DropdownMenuItem<T>(value: item, child: Text(labelFor(item))),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    );
  }
}
