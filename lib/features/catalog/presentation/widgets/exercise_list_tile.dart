import 'package:flutter/material.dart';
import 'package:mesa/core/formatters/exercise_display.dart';
import 'package:mesa/domain/models/exercise.dart';
import 'package:mesa/features/catalog/presentation/exercise_labels.dart';
import 'package:mesa/features/catalog/presentation/widgets/exercise_media.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// One row of the catalogue list (F2).
///
/// The subtitle always carries equipment and primary muscle. That is §5.4's
/// "disambiguate by appending equipment" done for every row rather than only
/// the duplicated ones — it is more useful, and the six pairs §5.4 had in mind
/// share their equipment anyway, which is what [showId] is for.
class ExerciseListTile extends StatelessWidget {
  const ExerciseListTile({
    required this.exercise,
    required this.onTap,
    this.isFavourite = false,
    this.onToggleFavourite,
    this.showId = false,
    super.key,
  });

  final Exercise exercise;
  final VoidCallback onTap;
  final bool isFavourite;
  final VoidCallback? onToggleFavourite;

  /// Whether the name collides with another that has the same equipment, so
  /// the upstream id is the only thing that tells them apart.
  final bool showId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final title = showId
        ? '${exerciseTitle(exercise.name)} (${exercise.id})'
        : exerciseTitle(exercise.name);

    return ListTile(
      onTap: onTap,
      // NFR4: comfortably past the 48 dp minimum with a 56 dp thumbnail.
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ExerciseMedia(url: exercise.thumbnailUrl, size: 56),
      title: Row(
        children: [
          Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
          if (exercise.isCustom) ...[
            const SizedBox(width: 8),
            _CustomBadge(label: l10n.catalogCustomBadge),
          ],
        ],
      ),
      subtitle: Text(
        '${ExerciseLabels.equipment(l10n, exercise.equipment)}'
        ' · ${ExerciseLabels.muscle(l10n, exercise.primaryMuscle)}',
        style: theme.textTheme.bodySmall,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: onToggleFavourite == null
          ? null
          : IconButton(
              onPressed: onToggleFavourite,
              icon: Icon(isFavourite ? Icons.star : Icons.star_border),
              color: isFavourite ? theme.colorScheme.primary : null,
              tooltip: isFavourite ? l10n.catalogFavouriteRemove : l10n.catalogFavouriteAdd,
            ),
    );
  }
}

/// Marks a user-created exercise in a list of catalogue ones (F2).
class _CustomBadge extends StatelessWidget {
  const _CustomBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colours.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colours.onSecondaryContainer),
      ),
    );
  }
}
