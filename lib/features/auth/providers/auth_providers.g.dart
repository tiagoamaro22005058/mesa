// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The auth backend.
///
/// Overridden with a fake in tests, which is what keeps widget tests free of
/// Firebase plugin channels — `FirebaseAuth.instance` is never constructed
/// unless something actually reads this.

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

/// The auth backend.
///
/// Overridden with a fake in tests, which is what keeps widget tests free of
/// Firebase plugin channels — `FirebaseAuth.instance` is never constructed
/// unless something actually reads this.

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// The auth backend.
  ///
  /// Overridden with a fake in tests, which is what keeps widget tests free of
  /// Firebase plugin channels — `FirebaseAuth.instance` is never constructed
  /// unless something actually reads this.
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'5bac5b8aeb7741d343291be7203d2a8df8e018b2';

/// The `users/{uid}` document store (§4).

@ProviderFor(userProfileRepository)
final userProfileRepositoryProvider = UserProfileRepositoryProvider._();

/// The `users/{uid}` document store (§4).

final class UserProfileRepositoryProvider
    extends
        $FunctionalProvider<
          UserProfileRepository,
          UserProfileRepository,
          UserProfileRepository
        >
    with $Provider<UserProfileRepository> {
  /// The `users/{uid}` document store (§4).
  UserProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProfileRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userProfileRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserProfileRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UserProfileRepository create(Ref ref) {
    return userProfileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserProfileRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserProfileRepository>(value),
    );
  }
}

String _$userProfileRepositoryHash() =>
    r'4986c508181a171aae58bf7f1bbf40d21ed23ca5';

/// The signed-in identity, or `null` when signed out.
///
/// Stays `AsyncLoading` until Firebase has restored any persisted session, so
/// the router can show a splash rather than flashing the sign-in screen on a
/// cold start (F1).

@ProviderFor(authState)
final authStateProvider = AuthStateProvider._();

/// The signed-in identity, or `null` when signed out.
///
/// Stays `AsyncLoading` until Firebase has restored any persisted session, so
/// the router can show a splash rather than flashing the sign-in screen on a
/// cold start (F1).

final class AuthStateProvider
    extends
        $FunctionalProvider<AsyncValue<AuthUser?>, AuthUser?, Stream<AuthUser?>>
    with $FutureModifier<AuthUser?>, $StreamProvider<AuthUser?> {
  /// The signed-in identity, or `null` when signed out.
  ///
  /// Stays `AsyncLoading` until Firebase has restored any persisted session, so
  /// the router can show a splash rather than flashing the sign-in screen on a
  /// cold start (F1).
  AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<AuthUser?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AuthUser?> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'77a1bfaaf734442d65c4e40dc4ac34ec55b85f7f';

/// Creates the `users/{uid}` document the first time an account authenticates.
///
/// Hangs off the auth state rather than the sign-up call because Google
/// Sign-In creates accounts implicitly — there is no sign-up path to hook. It
/// is idempotent, so running again on every restored session is harmless.
///
/// Activated by [MesaApp]; nothing else needs to read it.

@ProviderFor(profileBootstrap)
final profileBootstrapProvider = ProfileBootstrapProvider._();

/// Creates the `users/{uid}` document the first time an account authenticates.
///
/// Hangs off the auth state rather than the sign-up call because Google
/// Sign-In creates accounts implicitly — there is no sign-up path to hook. It
/// is idempotent, so running again on every restored session is harmless.
///
/// Activated by [MesaApp]; nothing else needs to read it.

final class ProfileBootstrapProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Creates the `users/{uid}` document the first time an account authenticates.
  ///
  /// Hangs off the auth state rather than the sign-up call because Google
  /// Sign-In creates accounts implicitly — there is no sign-up path to hook. It
  /// is idempotent, so running again on every restored session is harmless.
  ///
  /// Activated by [MesaApp]; nothing else needs to read it.
  ProfileBootstrapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileBootstrapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileBootstrapHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return profileBootstrap(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$profileBootstrapHash() => r'6594b8e62d1d96a98b0c5ccb134aa845f4ad8634';

/// Drives the auth screens. Its [AsyncValue] carries the in-flight and failed
/// states that the forms render.

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// Drives the auth screens. Its [AsyncValue] carries the in-flight and failed
/// states that the forms render.
final class AuthControllerProvider
    extends $AsyncNotifierProvider<AuthController, void> {
  /// Drives the auth screens. Its [AsyncValue] carries the in-flight and failed
  /// states that the forms render.
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();
}

String _$authControllerHash() => r'4dc4669c71b3d708d389513ca5c8eab3635637b0';

/// Drives the auth screens. Its [AsyncValue] carries the in-flight and failed
/// states that the forms render.

abstract class _$AuthController extends $AsyncNotifier<void> {
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
