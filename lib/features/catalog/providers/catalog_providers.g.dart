// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The bundled catalogue asset.
///
/// Overridden with a fake in widget tests, which is what keeps them off
/// `rootBundle` and off a 1.1 MB parse per test.

@ProviderFor(exerciseCatalog)
final exerciseCatalogProvider = ExerciseCatalogProvider._();

/// The bundled catalogue asset.
///
/// Overridden with a fake in widget tests, which is what keeps them off
/// `rootBundle` and off a 1.1 MB parse per test.

final class ExerciseCatalogProvider
    extends
        $FunctionalProvider<ExerciseCatalog, ExerciseCatalog, ExerciseCatalog>
    with $Provider<ExerciseCatalog> {
  /// The bundled catalogue asset.
  ///
  /// Overridden with a fake in widget tests, which is what keeps them off
  /// `rootBundle` and off a 1.1 MB parse per test.
  ExerciseCatalogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exerciseCatalogProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exerciseCatalogHash();

  @$internal
  @override
  $ProviderElement<ExerciseCatalog> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ExerciseCatalog create(Ref ref) {
    return exerciseCatalog(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExerciseCatalog value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExerciseCatalog>(value),
    );
  }
}

String _$exerciseCatalogHash() => r'4b284eb1f4ff43b4af8a17529410b7b2d83140be';

/// `users/{uid}/customExercises` (§4).

@ProviderFor(customExerciseRepository)
final customExerciseRepositoryProvider = CustomExerciseRepositoryProvider._();

/// `users/{uid}/customExercises` (§4).

final class CustomExerciseRepositoryProvider
    extends
        $FunctionalProvider<
          CustomExerciseRepository,
          CustomExerciseRepository,
          CustomExerciseRepository
        >
    with $Provider<CustomExerciseRepository> {
  /// `users/{uid}/customExercises` (§4).
  CustomExerciseRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customExerciseRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customExerciseRepositoryHash();

  @$internal
  @override
  $ProviderElement<CustomExerciseRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CustomExerciseRepository create(Ref ref) {
    return customExerciseRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CustomExerciseRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CustomExerciseRepository>(value),
    );
  }
}

String _$customExerciseRepositoryHash() =>
    r'633523fbffadaf7ed483bb1a53c016825c2659b1';

/// The 1,295 bundled exercises, parsed once per app session.
///
/// `keepAlive` because the parse is the expensive part and the data never
/// changes — leaving the catalogue screen and coming back must not re-read the
/// asset. Nothing reads this until something asks for the catalogue, so cold
/// start is untouched (NFR3).

@ProviderFor(bundledExercises)
final bundledExercisesProvider = BundledExercisesProvider._();

/// The 1,295 bundled exercises, parsed once per app session.
///
/// `keepAlive` because the parse is the expensive part and the data never
/// changes — leaving the catalogue screen and coming back must not re-read the
/// asset. Nothing reads this until something asks for the catalogue, so cold
/// start is untouched (NFR3).

final class BundledExercisesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Exercise>>,
          List<Exercise>,
          FutureOr<List<Exercise>>
        >
    with $FutureModifier<List<Exercise>>, $FutureProvider<List<Exercise>> {
  /// The 1,295 bundled exercises, parsed once per app session.
  ///
  /// `keepAlive` because the parse is the expensive part and the data never
  /// changes — leaving the catalogue screen and coming back must not re-read the
  /// asset. Nothing reads this until something asks for the catalogue, so cold
  /// start is untouched (NFR3).
  BundledExercisesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bundledExercisesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bundledExercisesHash();

  @$internal
  @override
  $FutureProviderElement<List<Exercise>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Exercise>> create(Ref ref) {
    return bundledExercises(ref);
  }
}

String _$bundledExercisesHash() => r'0cc723400005365478d92716f80837de7921f5f5';

/// The signed-in user's own exercises, or empty when signed out.

@ProviderFor(customExercises)
final customExercisesProvider = CustomExercisesProvider._();

/// The signed-in user's own exercises, or empty when signed out.

final class CustomExercisesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Exercise>>,
          List<Exercise>,
          Stream<List<Exercise>>
        >
    with $FutureModifier<List<Exercise>>, $StreamProvider<List<Exercise>> {
  /// The signed-in user's own exercises, or empty when signed out.
  CustomExercisesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'customExercisesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$customExercisesHash();

  @$internal
  @override
  $StreamProviderElement<List<Exercise>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Exercise>> create(Ref ref) {
    return customExercises(ref);
  }
}

String _$customExercisesHash() => r'b72380981ffdee5249f4d1a3f521f1e63802c86b';

/// Catalogue and custom exercises, merged and indexed for search (F2).
///
/// Rebuilt when the custom list changes — 1,295 normalisations take a few
/// milliseconds, and a custom exercise has to be searchable the moment it is
/// created.

@ProviderFor(exerciseIndex)
final exerciseIndexProvider = ExerciseIndexProvider._();

/// Catalogue and custom exercises, merged and indexed for search (F2).
///
/// Rebuilt when the custom list changes — 1,295 normalisations take a few
/// milliseconds, and a custom exercise has to be searchable the moment it is
/// created.

final class ExerciseIndexProvider
    extends
        $FunctionalProvider<
          AsyncValue<ExerciseSearchIndex>,
          ExerciseSearchIndex,
          FutureOr<ExerciseSearchIndex>
        >
    with
        $FutureModifier<ExerciseSearchIndex>,
        $FutureProvider<ExerciseSearchIndex> {
  /// Catalogue and custom exercises, merged and indexed for search (F2).
  ///
  /// Rebuilt when the custom list changes — 1,295 normalisations take a few
  /// milliseconds, and a custom exercise has to be searchable the moment it is
  /// created.
  ExerciseIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exerciseIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exerciseIndexHash();

  @$internal
  @override
  $FutureProviderElement<ExerciseSearchIndex> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ExerciseSearchIndex> create(Ref ref) {
    return exerciseIndex(ref);
  }
}

String _$exerciseIndexHash() => r'85cbdb857ea0248e8670410e99af284d331f1e32';

/// What is in the search box. Held here rather than in the widget so the
/// results provider can depend on it.

@ProviderFor(CatalogQuery)
final catalogQueryProvider = CatalogQueryProvider._();

/// What is in the search box. Held here rather than in the widget so the
/// results provider can depend on it.
final class CatalogQueryProvider
    extends $NotifierProvider<CatalogQuery, String> {
  /// What is in the search box. Held here rather than in the widget so the
  /// results provider can depend on it.
  CatalogQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogQueryHash();

  @$internal
  @override
  CatalogQuery create() => CatalogQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$catalogQueryHash() => r'01e83afc0d31a5ae22abaf845b2797c801ffc612';

/// What is in the search box. Held here rather than in the widget so the
/// results provider can depend on it.

abstract class _$CatalogQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Which body part, muscle and equipment the list is narrowed to (F2).

@ProviderFor(CatalogFilter)
final catalogFilterProvider = CatalogFilterProvider._();

/// Which body part, muscle and equipment the list is narrowed to (F2).
final class CatalogFilterProvider
    extends $NotifierProvider<CatalogFilter, ExerciseFilter> {
  /// Which body part, muscle and equipment the list is narrowed to (F2).
  CatalogFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogFilterHash();

  @$internal
  @override
  CatalogFilter create() => CatalogFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExerciseFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExerciseFilter>(value),
    );
  }
}

String _$catalogFilterHash() => r'18712cd0b11ddc128a1c78aedaf67ebb866889cd';

/// Which body part, muscle and equipment the list is narrowed to (F2).

abstract class _$CatalogFilter extends $Notifier<ExerciseFilter> {
  ExerciseFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ExerciseFilter, ExerciseFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExerciseFilter, ExerciseFilter>,
              ExerciseFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The ids the user starred (F2).
///
/// Read off the profile document, which is already being streamed for every
/// other setting — favourites cost no extra read (NFR2).

@ProviderFor(favouriteExerciseIds)
final favouriteExerciseIdsProvider = FavouriteExerciseIdsProvider._();

/// The ids the user starred (F2).
///
/// Read off the profile document, which is already being streamed for every
/// other setting — favourites cost no extra read (NFR2).

final class FavouriteExerciseIdsProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  /// The ids the user starred (F2).
  ///
  /// Read off the profile document, which is already being streamed for every
  /// other setting — favourites cost no extra read (NFR2).
  FavouriteExerciseIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favouriteExerciseIdsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favouriteExerciseIdsHash();

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    return favouriteExerciseIds(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$favouriteExerciseIdsHash() =>
    r'79177b9360d8585ed3c0a8484452281a552784ba';

/// What the catalogue screen shows: the query and filters applied to the index.

@ProviderFor(catalogResults)
final catalogResultsProvider = CatalogResultsProvider._();

/// What the catalogue screen shows: the query and filters applied to the index.

final class CatalogResultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Exercise>>,
          List<Exercise>,
          FutureOr<List<Exercise>>
        >
    with $FutureModifier<List<Exercise>>, $FutureProvider<List<Exercise>> {
  /// What the catalogue screen shows: the query and filters applied to the index.
  CatalogResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogResultsHash();

  @$internal
  @override
  $FutureProviderElement<List<Exercise>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Exercise>> create(Ref ref) {
    return catalogResults(ref);
  }
}

String _$catalogResultsHash() => r'21be7febafcf68babac81970cf97a21a1e51f918';

/// One exercise by id, from the merged catalogue.
///
/// Returns `null` when it does not exist, which is what a deep link to a
/// deleted custom exercise produces.

@ProviderFor(exerciseById)
final exerciseByIdProvider = ExerciseByIdFamily._();

/// One exercise by id, from the merged catalogue.
///
/// Returns `null` when it does not exist, which is what a deep link to a
/// deleted custom exercise produces.

final class ExerciseByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<Exercise?>,
          Exercise?,
          FutureOr<Exercise?>
        >
    with $FutureModifier<Exercise?>, $FutureProvider<Exercise?> {
  /// One exercise by id, from the merged catalogue.
  ///
  /// Returns `null` when it does not exist, which is what a deep link to a
  /// deleted custom exercise produces.
  ExerciseByIdProvider._({
    required ExerciseByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'exerciseByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$exerciseByIdHash();

  @override
  String toString() {
    return r'exerciseByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Exercise?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Exercise?> create(Ref ref) {
    final argument = this.argument as String;
    return exerciseById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ExerciseByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$exerciseByIdHash() => r'c589bf81494cb1662142f39f747637143b59e721';

/// One exercise by id, from the merged catalogue.
///
/// Returns `null` when it does not exist, which is what a deep link to a
/// deleted custom exercise produces.

final class ExerciseByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Exercise?>, String> {
  ExerciseByIdFamily._()
    : super(
        retry: null,
        name: r'exerciseByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One exercise by id, from the merged catalogue.
  ///
  /// Returns `null` when it does not exist, which is what a deep link to a
  /// deleted custom exercise produces.

  ExerciseByIdProvider call(String id) =>
      ExerciseByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'exerciseByIdProvider';
}

/// Creates, edits and deletes custom exercises, and toggles favourites (F2).
///
/// `keepAlive`, unlike `AuthController` and `ProfileController`. Those are
/// watched by the screen that drives them, which keeps them alive for as long
/// as their work takes. This one is called from a list row and from a
/// confirmation dialog — nothing watches it — so an auto-disposed version is
/// disposed at its first `await`, and every `ref.read` after that point runs
/// against a dead `Ref`. `AsyncValue.guard` then swallows the error, and the
/// second half of a two-step action silently does not happen.

@ProviderFor(CatalogController)
final catalogControllerProvider = CatalogControllerProvider._();

/// Creates, edits and deletes custom exercises, and toggles favourites (F2).
///
/// `keepAlive`, unlike `AuthController` and `ProfileController`. Those are
/// watched by the screen that drives them, which keeps them alive for as long
/// as their work takes. This one is called from a list row and from a
/// confirmation dialog — nothing watches it — so an auto-disposed version is
/// disposed at its first `await`, and every `ref.read` after that point runs
/// against a dead `Ref`. `AsyncValue.guard` then swallows the error, and the
/// second half of a two-step action silently does not happen.
final class CatalogControllerProvider
    extends $AsyncNotifierProvider<CatalogController, void> {
  /// Creates, edits and deletes custom exercises, and toggles favourites (F2).
  ///
  /// `keepAlive`, unlike `AuthController` and `ProfileController`. Those are
  /// watched by the screen that drives them, which keeps them alive for as long
  /// as their work takes. This one is called from a list row and from a
  /// confirmation dialog — nothing watches it — so an auto-disposed version is
  /// disposed at its first `await`, and every `ref.read` after that point runs
  /// against a dead `Ref`. `AsyncValue.guard` then swallows the error, and the
  /// second half of a two-step action silently does not happen.
  CatalogControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'catalogControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$catalogControllerHash();

  @$internal
  @override
  CatalogController create() => CatalogController();
}

String _$catalogControllerHash() => r'2106b9a666e9a37092c290af36e9f69af88c6630';

/// Creates, edits and deletes custom exercises, and toggles favourites (F2).
///
/// `keepAlive`, unlike `AuthController` and `ProfileController`. Those are
/// watched by the screen that drives them, which keeps them alive for as long
/// as their work takes. This one is called from a list row and from a
/// confirmation dialog — nothing watches it — so an auto-disposed version is
/// disposed at its first `await`, and every `ref.read` after that point runs
/// against a dead `Ref`. `AsyncValue.guard` then swallows the error, and the
/// second half of a two-step action silently does not happen.

abstract class _$CatalogController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
