import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mesa/domain/models/body_part.dart';
import 'package:mesa/domain/models/equipment.dart';
import 'package:mesa/domain/models/muscle.dart';
import 'package:mesa/features/catalog/presentation/exercise_labels.dart';
import 'package:mesa/features/catalog/providers/catalog_providers.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// Body part, primary muscle and equipment filters (F2).
///
/// A bottom sheet rather than a side drawer: it opens under the thumb and every
/// chip in it stays in the lower half of the screen (NFR4).
class ExerciseFiltersSheet extends ConsumerWidget {
  const ExerciseFiltersSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const ExerciseFiltersSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final filter = ref.watch(catalogFilterProvider);
    final controller = ref.read(catalogFilterProvider.notifier);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Row(
              children: [
                Text(l10n.catalogFiltersTitle, style: theme.textTheme.titleLarge),
                const Spacer(),
                if (!filter.isEmpty)
                  TextButton(
                    onPressed: controller.clear,
                    child: Text(l10n.catalogClearFilters),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                SwitchListTile(
                  value: filter.favouritesOnly,
                  onChanged: (value) =>
                      controller.update(filter.copyWith(favouritesOnly: value)),
                  title: Text(l10n.catalogFilterFavourites),
                  contentPadding: EdgeInsets.zero,
                ),
                _FilterGroup<BodyPart>(
                  heading: l10n.catalogFilterBodyPart,
                  values: BodyPart.values,
                  selected: filter.bodyPart,
                  label: (value) => ExerciseLabels.bodyPart(l10n, value),
                  // Passing the value again clears it, so the same tap that
                  // selected a chip deselects it.
                  onSelected: (value) => controller.update(
                    filter.copyWith(bodyPart: value == filter.bodyPart ? null : value),
                  ),
                ),
                _FilterGroup<Muscle>(
                  heading: l10n.catalogFilterMuscle,
                  values: Muscle.values,
                  selected: filter.primaryMuscle,
                  label: (value) => ExerciseLabels.muscle(l10n, value),
                  onSelected: (value) => controller.update(
                    filter.copyWith(
                      primaryMuscle: value == filter.primaryMuscle ? null : value,
                    ),
                  ),
                ),
                _FilterGroup<Equipment>(
                  heading: l10n.catalogFilterEquipment,
                  values: Equipment.values,
                  selected: filter.equipment,
                  label: (value) => ExerciseLabels.equipment(l10n, value),
                  onSelected: (value) => controller.update(
                    filter.copyWith(equipment: value == filter.equipment ? null : value),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.catalogFilterDone),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterGroup<T> extends StatelessWidget {
  const _FilterGroup({
    required this.heading,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final String heading;
  final List<T> values;
  final T? selected;
  final String Function(T value) label;
  final void Function(T value) onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(heading, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              FilterChip(
                label: Text(label(value)),
                selected: value == selected,
                onSelected: (_) => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
}
