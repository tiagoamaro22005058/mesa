/// The ways a Firestore write can fail, as the app understands them.
///
/// A sibling of `AuthFailure`, following §9.1's shape rather than inventing a
/// second error style: a closed set of kinds, translated once at the `data/`
/// boundary, each mapping to exactly one localised string.
///
/// The list is short on purpose, and one absence is deliberate: there is no
/// `networkUnavailable`. Firestore applies a write to its local cache
/// synchronously and syncs it later, so losing connectivity is not a failure
/// the user should ever be told about (NFR1). A write that has not reached the
/// server yet is a write that succeeded.
enum FirestoreFailureKind {
  /// The security rules rejected it. In a single-user app this means a stale
  /// auth token or a write aimed at another account's subtree — a bug, not
  /// something the user can fix.
  permissionDenied,

  /// The document was gone by the time the write landed.
  notFound,

  /// Anything unmapped. Keeps the provider's original code, so an unmapped
  /// failure is still diagnosable from a bug report rather than vanishing into
  /// a generic message (§9.1).
  unknown,
}

final class FirestoreFailure implements Exception {
  const FirestoreFailure(this.kind, {this.code});

  final FirestoreFailureKind kind;

  /// The provider's original error code, retained only for
  /// [FirestoreFailureKind.unknown].
  final String? code;

  @override
  String toString() => code == null
      ? 'FirestoreFailure(${kind.name})'
      : 'FirestoreFailure(${kind.name}, code: $code)';

  @override
  bool operator ==(Object other) =>
      other is FirestoreFailure && other.kind == kind && other.code == code;

  @override
  int get hashCode => Object.hash(kind, code);
}
