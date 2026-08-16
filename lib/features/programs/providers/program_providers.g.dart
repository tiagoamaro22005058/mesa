// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `users/{uid}/programs` and the days beneath it (§4).

@ProviderFor(programRepository)
final programRepositoryProvider = ProgramRepositoryProvider._();

/// `users/{uid}/programs` and the days beneath it (§4).

final class ProgramRepositoryProvider
    extends
        $FunctionalProvider<
          ProgramRepository,
          ProgramRepository,
          ProgramRepository
        >
    with $Provider<ProgramRepository> {
  /// `users/{uid}/programs` and the days beneath it (§4).
  ProgramRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'programRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$programRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProgramRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProgramRepository create(Ref ref) {
    return programRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProgramRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProgramRepository>(value),
    );
  }
}

String _$programRepositoryHash() => r'f64b87bedbe430b0f7ae0900e281c3d2caf1a0c1';

/// Every program the user owns, or empty when signed out.

@ProviderFor(programs)
final programsProvider = ProgramsProvider._();

/// Every program the user owns, or empty when signed out.

final class ProgramsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Program>>,
          List<Program>,
          Stream<List<Program>>
        >
    with $FutureModifier<List<Program>>, $StreamProvider<List<Program>> {
  /// Every program the user owns, or empty when signed out.
  ProgramsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'programsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$programsHash();

  @$internal
  @override
  $StreamProviderElement<List<Program>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Program>> create(Ref ref) {
    return programs(ref);
  }
}

String _$programsHash() => r'8dbde7bb96d42b09f321b51859436df4b4a74dd3';

/// One program by id.
///
/// Derived from [programsProvider] rather than opening a second listener: the
/// list is already streamed and a user has a handful of programs, so filtering
/// it costs nothing and saves a read (NFR2). Returns `null` when the program
/// does not exist, which is what a deep link to a deleted one produces.

@ProviderFor(programById)
final programByIdProvider = ProgramByIdFamily._();

/// One program by id.
///
/// Derived from [programsProvider] rather than opening a second listener: the
/// list is already streamed and a user has a handful of programs, so filtering
/// it costs nothing and saves a read (NFR2). Returns `null` when the program
/// does not exist, which is what a deep link to a deleted one produces.

final class ProgramByIdProvider
    extends $FunctionalProvider<Program?, Program?, Program?>
    with $Provider<Program?> {
  /// One program by id.
  ///
  /// Derived from [programsProvider] rather than opening a second listener: the
  /// list is already streamed and a user has a handful of programs, so filtering
  /// it costs nothing and saves a read (NFR2). Returns `null` when the program
  /// does not exist, which is what a deep link to a deleted one produces.
  ProgramByIdProvider._({
    required ProgramByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'programByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$programByIdHash();

  @override
  String toString() {
    return r'programByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Program?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Program? create(Ref ref) {
    final argument = this.argument as String;
    return programById(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Program? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Program?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$programByIdHash() => r'0526ab1240619d44122c79b966099c82f711725a';

/// One program by id.
///
/// Derived from [programsProvider] rather than opening a second listener: the
/// list is already streamed and a user has a handful of programs, so filtering
/// it costs nothing and saves a read (NFR2). Returns `null` when the program
/// does not exist, which is what a deep link to a deleted one produces.

final class ProgramByIdFamily extends $Family
    with $FunctionalFamilyOverride<Program?, String> {
  ProgramByIdFamily._()
    : super(
        retry: null,
        name: r'programByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One program by id.
  ///
  /// Derived from [programsProvider] rather than opening a second listener: the
  /// list is already streamed and a user has a handful of programs, so filtering
  /// it costs nothing and saves a read (NFR2). Returns `null` when the program
  /// does not exist, which is what a deep link to a deleted one produces.

  ProgramByIdProvider call(String programId) =>
      ProgramByIdProvider._(argument: programId, from: this);

  @override
  String toString() => r'programByIdProvider';
}

/// One program's day templates, in order.

@ProviderFor(programDays)
final programDaysProvider = ProgramDaysFamily._();

/// One program's day templates, in order.

final class ProgramDaysProvider
    extends
        $FunctionalProvider<AsyncValue<List<Day>>, List<Day>, Stream<List<Day>>>
    with $FutureModifier<List<Day>>, $StreamProvider<List<Day>> {
  /// One program's day templates, in order.
  ProgramDaysProvider._({
    required ProgramDaysFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'programDaysProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$programDaysHash();

  @override
  String toString() {
    return r'programDaysProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Day>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Day>> create(Ref ref) {
    final argument = this.argument as String;
    return programDays(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramDaysProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$programDaysHash() => r'a0e25fd72928da546e1ac475d6dc9272f4fdb233';

/// One program's day templates, in order.

final class ProgramDaysFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Day>>, String> {
  ProgramDaysFamily._()
    : super(
        retry: null,
        name: r'programDaysProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One program's day templates, in order.

  ProgramDaysProvider call(String programId) =>
      ProgramDaysProvider._(argument: programId, from: this);

  @override
  String toString() => r'programDaysProvider';
}

/// One day by id, from the program's already-streamed list.

@ProviderFor(dayById)
final dayByIdProvider = DayByIdFamily._();

/// One day by id, from the program's already-streamed list.

final class DayByIdProvider extends $FunctionalProvider<Day?, Day?, Day?>
    with $Provider<Day?> {
  /// One day by id, from the program's already-streamed list.
  DayByIdProvider._({
    required DayByIdFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'dayByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dayByIdHash();

  @override
  String toString() {
    return r'dayByIdProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<Day?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Day? create(Ref ref) {
    final argument = this.argument as (String, String);
    return dayById(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Day? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Day?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DayByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dayByIdHash() => r'afa68090c28041f8804c258eef6011d84db4b86d';

/// One day by id, from the program's already-streamed list.

final class DayByIdFamily extends $Family
    with $FunctionalFamilyOverride<Day?, (String, String)> {
  DayByIdFamily._()
    : super(
        retry: null,
        name: r'dayByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One day by id, from the program's already-streamed list.

  DayByIdProvider call(String programId, String dayId) =>
      DayByIdProvider._(argument: (programId, dayId), from: this);

  @override
  String toString() => r'dayByIdProvider';
}

/// The program currently marked active, if there is one (F3).

@ProviderFor(activeProgram)
final activeProgramProvider = ActiveProgramProvider._();

/// The program currently marked active, if there is one (F3).

final class ActiveProgramProvider
    extends $FunctionalProvider<Program?, Program?, Program?>
    with $Provider<Program?> {
  /// The program currently marked active, if there is one (F3).
  ActiveProgramProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeProgramProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeProgramHash();

  @$internal
  @override
  $ProviderElement<Program?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Program? create(Ref ref) {
    return activeProgram(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Program? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Program?>(value),
    );
  }
}

String _$activeProgramHash() => r'2a553dcc871510e5046b58f4c9478cd225079d9e';

/// Builds and edits programs, days and blocks (F3).
///
/// `keepAlive`, for the reason `CatalogController` documents: this is called
/// from list rows and confirmation dialogs, which nothing watches, so an
/// auto-disposed version is disposed at its first `await` and every `ref.read`
/// after that point runs against a dead `Ref`.

@ProviderFor(ProgramController)
final programControllerProvider = ProgramControllerProvider._();

/// Builds and edits programs, days and blocks (F3).
///
/// `keepAlive`, for the reason `CatalogController` documents: this is called
/// from list rows and confirmation dialogs, which nothing watches, so an
/// auto-disposed version is disposed at its first `await` and every `ref.read`
/// after that point runs against a dead `Ref`.
final class ProgramControllerProvider
    extends $AsyncNotifierProvider<ProgramController, void> {
  /// Builds and edits programs, days and blocks (F3).
  ///
  /// `keepAlive`, for the reason `CatalogController` documents: this is called
  /// from list rows and confirmation dialogs, which nothing watches, so an
  /// auto-disposed version is disposed at its first `await` and every `ref.read`
  /// after that point runs against a dead `Ref`.
  ProgramControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'programControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$programControllerHash();

  @$internal
  @override
  ProgramController create() => ProgramController();
}

String _$programControllerHash() => r'bb3de0a0e086054b2d39100936c77dcdb315f518';

/// Builds and edits programs, days and blocks (F3).
///
/// `keepAlive`, for the reason `CatalogController` documents: this is called
/// from list rows and confirmation dialogs, which nothing watches, so an
/// auto-disposed version is disposed at its first `await` and every `ref.read`
/// after that point runs against a dead `Ref`.

abstract class _$ProgramController extends $AsyncNotifier<void> {
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
