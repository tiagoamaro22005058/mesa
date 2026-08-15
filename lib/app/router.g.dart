// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The application router.
///
/// Auth state gates every route through [redirect]. The router itself is built
/// once and refreshed through a [Listenable] rather than rebuilt on each auth
/// change — recreating the `GoRouter` would throw away navigation state.

@ProviderFor(router)
final routerProvider = RouterProvider._();

/// The application router.
///
/// Auth state gates every route through [redirect]. The router itself is built
/// once and refreshed through a [Listenable] rather than rebuilt on each auth
/// change — recreating the `GoRouter` would throw away navigation state.

final class RouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// The application router.
  ///
  /// Auth state gates every route through [redirect]. The router itself is built
  /// once and refreshed through a [Listenable] rather than rebuilt on each auth
  /// change — recreating the `GoRouter` would throw away navigation state.
  RouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routerHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return router(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$routerHash() => r'8d3322003bd638232381eaca688636b02b3a2a02';
