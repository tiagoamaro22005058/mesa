// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in user's profile document (§4), or `null` while it does not
/// exist yet.
///
/// Auto-disposed and scoped to the current uid, which is what lets sign-out
/// drop every Firestore listener before the cache is cleared — see
/// `FirebaseAuthRepository.signOut`.

@ProviderFor(userProfile)
final userProfileProvider = UserProfileProvider._();

/// The signed-in user's profile document (§4), or `null` while it does not
/// exist yet.
///
/// Auto-disposed and scoped to the current uid, which is what lets sign-out
/// drop every Firestore listener before the cache is cleared — see
/// `FirebaseAuthRepository.signOut`.

final class UserProfileProvider
    extends
        $FunctionalProvider<
          AsyncValue<UserProfile?>,
          UserProfile?,
          Stream<UserProfile?>
        >
    with $FutureModifier<UserProfile?>, $StreamProvider<UserProfile?> {
  /// The signed-in user's profile document (§4), or `null` while it does not
  /// exist yet.
  ///
  /// Auto-disposed and scoped to the current uid, which is what lets sign-out
  /// drop every Firestore listener before the cache is cleared — see
  /// `FirebaseAuthRepository.signOut`.
  UserProfileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userProfileProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userProfileHash();

  @$internal
  @override
  $StreamProviderElement<UserProfile?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<UserProfile?> create(Ref ref) {
    return userProfile(ref);
  }
}

String _$userProfileHash() => r'73653483d3559af70037cec49ff028cce04fe8ee';

/// Writes profile edits (F1).

@ProviderFor(ProfileController)
final profileControllerProvider = ProfileControllerProvider._();

/// Writes profile edits (F1).
final class ProfileControllerProvider
    extends $AsyncNotifierProvider<ProfileController, void> {
  /// Writes profile edits (F1).
  ProfileControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileControllerHash();

  @$internal
  @override
  ProfileController create() => ProfileController();
}

String _$profileControllerHash() => r'b8702553f495238c5c5b85e26e25bee6f7f495e3';

/// Writes profile edits (F1).

abstract class _$ProfileController extends $AsyncNotifier<void> {
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
