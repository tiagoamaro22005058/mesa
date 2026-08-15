/// The signed-in identity, stripped of anything provider-specific.
///
/// The data layer maps `firebase_auth`'s `User` onto this so that §9's rule
/// holds: nothing in `domain/` knows Firebase exists.
class AuthUser {
  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  @override
  bool operator ==(Object other) =>
      other is AuthUser &&
      other.uid == uid &&
      other.email == email &&
      other.displayName == displayName &&
      other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(uid, email, displayName, photoUrl);

  @override
  String toString() => 'AuthUser(uid: $uid, email: $email)';
}
