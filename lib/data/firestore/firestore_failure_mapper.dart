import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesa/core/failures/firestore_failure.dart';

/// Translates `cloud_firestore` errors into [FirestoreFailure].
///
/// Isolated from the repositories so every branch can be unit-tested without a
/// Firestore instance, the same way `AuthFailureMapper` is (§11).
abstract final class FirestoreFailureMapper {
  static FirestoreFailure from(FirebaseException exception) {
    final kind = switch (exception.code) {
      'permission-denied' => FirestoreFailureKind.permissionDenied,
      'not-found' => FirestoreFailureKind.notFound,
      _ => FirestoreFailureKind.unknown,
    };

    return kind == FirestoreFailureKind.unknown
        ? FirestoreFailure(kind, code: exception.code)
        : FirestoreFailure(kind);
  }
}
