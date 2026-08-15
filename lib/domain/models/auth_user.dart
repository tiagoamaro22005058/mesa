import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';

/// The signed-in identity, stripped of anything provider-specific.
///
/// The data layer maps `firebase_auth`'s `User` onto this so that §9's rule
/// holds: nothing in `domain/` knows Firebase exists.
@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String uid,
    String? email,
    String? displayName,
    String? photoUrl,
  }) = _AuthUser;
}
