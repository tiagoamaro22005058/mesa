import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mesa/app/router.dart';
import 'package:mesa/domain/models/exercise.dart';
import 'package:mesa/features/catalog/presentation/widgets/exercise_filters_sheet.dart';
import 'package:mesa/features/catalog/presentation/widgets/exercise_list_tile.dart';
import 'package:mesa/features/catalog/providers/catalog_providers.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// Browse, search and filter the exercise catalogue (F2).
///
/// Every byte of this screen comes from the bundled asset and the offline
/// Firestore cache, so it works identically in aeroplane mode — which is F2's
/// acceptance criterion and NFR1's whole point.
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    // Seeded from the provider so the query survives leaving the screen and
    // coming back — a search typed one-handed is not worth retyping.
    _search = TextEditingController(text: ref.read(catalogQueryProvider));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final results = ref.watch(catalogResultsProvider);
    final filter = ref.watch(catalogFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.catalogTitle),
        actions: [
          IconButton(
            onPressed: () => ExerciseFiltersSheet.show(context),
            tooltip: l10n.catalogFiltersAction,
            icon: Badge.count(
              count: filter.activeCount,
              isLabelVisible: filter.activeCount > 0,
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: ref.read(catalogQueryProvider.notifier).update,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.catalogSearchHint,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            ref.read(catalogQueryProvider.notifier).update('');
                          },
                          tooltip: l10n.catalogSearchClear,
                          icon: const Icon(Icons.close),
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: results.when(
                data: (exercises) => _Results(exercises: exercises),
                // Only ever the very first frame: the catalogue is kept alive
                // once parsed, so returning to this screen never spins again.
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => _LoadFailed(message: l10n.catalogLoadFailed),
              ),
            ),
          ],
        ),
      ),
      // NFR4: within thumb reach, not in the app bar.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goNamed(Routes.customExerciseNew),
        icon: const Icon(Icons.add),
        label: Text(l10n.catalogNewExercise),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.exercises});

  final List<Exercise> exercises;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (exercises.isEmpty) return const _NoResults();

    final favourites = ref.watch(favouriteExerciseIdsProvider);
    final index = ref.watch(exerciseIndexProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.catalogResultCount(exercises.length),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            // Room for the FAB to sit over, so the last row is still reachable.
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: exercises.length,
            itemBuilder: (context, position) {
              final exercise = exercises[position];
              return ExerciseListTile(
                exercise: exercise,
                isFavourite: favourites.contains(exercise.id),
                showId: index?.needsIdSuffix(exercise) ?? false,
                onToggleFavourite: () =>
                    ref.read(catalogControllerProvider.notifier).toggleFavourite(exercise.id),
                onTap: () => context.goNamed(
                  Routes.exerciseDetail,
                  pathParameters: {'id': exercise.id},
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NoResults extends ConsumerWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final filter = ref.watch(catalogFilterProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(l10n.catalogEmptyTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              l10n.catalogEmptyBody,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (!filter.isEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: ref.read(catalogFilterProvider.notifier).clear,
                child: Text(l10n.catalogClearFilters),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The asset is committed and validated by the ingestion build, so this is a
/// packaging fault rather than anything the user did — and never a network
/// problem, which is why there is no retry (NFR1).
class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
