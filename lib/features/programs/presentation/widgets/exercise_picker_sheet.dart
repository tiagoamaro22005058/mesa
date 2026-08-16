import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mesa/domain/models/exercise.dart';
import 'package:mesa/features/catalog/presentation/widgets/exercise_list_tile.dart';
import 'package:mesa/features/catalog/providers/catalog_providers.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// Picks one exercise for a block or an alternative (F3).
///
/// Reuses `exerciseIndexProvider` — the merged catalogue-plus-custom search
/// index M2 already builds and keeps alive — rather than assembling a second
/// one. That is what makes the picker cost zero Firestore reads (NFR2) and
/// work in aeroplane mode (NFR1), and it means a custom exercise is pickable
/// the moment it is created, exactly as in the catalogue screen.
///
/// The query is widget state rather than a provider: it is meaningless once the
/// sheet closes, and a provider would keep the last search alive for the next
/// block the user adds.
class ExercisePickerSheet extends ConsumerStatefulWidget {
  const ExercisePickerSheet({super.key});

  /// Opens the picker and resolves to the chosen exercise, or null if
  /// dismissed.
  static Future<Exercise?> show(BuildContext context) {
    return showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const ExercisePickerSheet(),
    );
  }

  @override
  ConsumerState<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final index = ref.watch(exerciseIndexProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l10n.exercisePickerTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _search,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.catalogSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                          tooltip: l10n.catalogSearchClear,
                          icon: const Icon(Icons.close),
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: switch (index) {
                AsyncData(value: final found) => _Results(
                  exercises: found.search(_query),
                  needsIdSuffix: found.needsIdSuffix,
                  controller: scrollController,
                ),
                AsyncLoading() => const Center(child: CircularProgressIndicator()),
                AsyncError() => Center(child: Text(l10n.catalogLoadFailed)),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.exercises,
    required this.needsIdSuffix,
    required this.controller,
  });

  final List<Exercise> exercises;
  final bool Function(Exercise exercise) needsIdSuffix;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(l10n.catalogEmptyTitle, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.builder(
      controller: controller,
      itemCount: exercises.length,
      itemBuilder: (context, position) {
        final exercise = exercises[position];

        return ExerciseListTile(
          exercise: exercise,
          showId: needsIdSuffix(exercise),
          onTap: () => Navigator.of(context).pop(exercise),
        );
      },
    );
  }
}
