import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mesa/app/router.dart';
import 'package:mesa/core/formatters/exercise_display.dart';
import 'package:mesa/domain/models/exercise.dart';
import 'package:mesa/features/catalog/presentation/exercise_labels.dart';
import 'package:mesa/features/catalog/presentation/widgets/exercise_media.dart';
import 'package:mesa/features/catalog/providers/catalog_providers.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// Everything the catalogue knows about one exercise (F2).
///
/// Personal history and the e1RM trend are F2 bullets that are not here:
/// `exerciseStats` has no writer until session logging lands in M4, and charts
/// are M6's milestone. Building either now would mean building against a
/// collection nothing writes.
class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({required this.exerciseId, super.key});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final exercise = ref.watch(exerciseByIdProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.value?.name == null ? '' : exerciseTitle(exercise.value!.name)),
        actions: [
          if (exercise.value != null)
            _FavouriteButton(exercise: exercise.value!),
        ],
      ),
      body: exercise.when(
        data: (found) => found == null
            ? Center(child: Text(l10n.exerciseNotFound))
            : _Detail(exercise: found),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text(l10n.catalogLoadFailed)),
      ),
    );
  }
}

class _FavouriteButton extends ConsumerWidget {
  const _FavouriteButton({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isFavourite = ref.watch(favouriteExerciseIdsProvider).contains(exercise.id);

    return IconButton(
      onPressed: () =>
          ref.read(catalogControllerProvider.notifier).toggleFavourite(exercise.id),
      icon: Icon(isFavourite ? Icons.star : Icons.star_border),
      tooltip: isFavourite ? l10n.catalogFavouriteRemove : l10n.catalogFavouriteAdd,
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            // The animation rather than the thumbnail: it is what actually
            // shows the movement, and it is cached after the first view.
            child: ExerciseMedia(url: exercise.gifUrl ?? exercise.thumbnailUrl),
          ),
        ),
        const SizedBox(height: 16),

        _Section(
          heading: l10n.exerciseEquipmentHeading,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ExerciseLabels.equipment(l10n, exercise.equipment)),
              const SizedBox(height: 4),
              Text(
                '${l10n.customExerciseLoadModelLabel}: '
                '${ExerciseLabels.loadModel(l10n, exercise.loadModel)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),

        _Section(
          heading: l10n.exerciseMusclesHeading,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MuscleRow(
                label: l10n.exercisePrimaryMuscle,
                value: ExerciseLabels.muscle(l10n, exercise.primaryMuscle),
              ),
              if (exercise.synergist != null)
                _MuscleRow(
                  label: l10n.exerciseSynergist,
                  value: ExerciseLabels.muscle(l10n, exercise.synergist!),
                ),
              if (exercise.secondaryMuscles.isNotEmpty)
                _MuscleRow(
                  label: l10n.exerciseSecondaryMuscles,
                  value: [
                    for (final muscle in exercise.secondaryMuscles)
                      ExerciseLabels.muscle(l10n, muscle),
                  ].join(', '),
                ),
            ],
          ),
        ),

        _Section(
          heading: l10n.exerciseInstructionsHeading,
          child: exercise.steps.isEmpty
              ? Text(l10n.exerciseNoInstructions, style: theme.textTheme.bodyMedium)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var step = 0; step < exercise.steps.length; step++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('${step + 1}. ${exercise.steps[step]}'),
                      ),
                  ],
                ),
        ),

        // §5.1 makes this a licence obligation wherever the media appears, not
        // a courtesy.
        if (exercise.attribution != null) ...[
          const SizedBox(height: 8),
          Text(
            exercise.attribution!,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],

        if (exercise.isCustom) ...[
          const SizedBox(height: 24),
          // NFR4: the actions a custom exercise offers sit at the bottom.
          OutlinedButton.icon(
            onPressed: () => context.goNamed(
              Routes.customExerciseEdit,
              pathParameters: {'id': exercise.id},
            ),
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.exerciseEdit),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(context, ref, exercise),
            icon: const Icon(Icons.delete_outline),
            style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
            label: Text(l10n.exerciseDelete),
          ),
        ],
      ],
    );
  }

  /// NFR5: no destructive action without confirmation.
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Exercise exercise) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exerciseDeleteTitle),
        content: Text(l10n.exerciseDeleteBody(exerciseTitle(exercise.name))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.exerciseDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(catalogControllerProvider.notifier).deleteCustomExercise(exercise.id);
    messenger.showSnackBar(SnackBar(content: Text(l10n.exerciseDeleted)));

    // Back where the user came from, which is the list they deleted it out of.
    // A deep link straight to this screen has nothing to pop, so the catalogue
    // is the fallback rather than a dead end.
    if (router.canPop()) {
      router.pop();
    } else {
      router.goNamed(Routes.catalog);
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.heading, required this.child});

  final String heading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(heading, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _MuscleRow extends StatelessWidget {
  const _MuscleRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
