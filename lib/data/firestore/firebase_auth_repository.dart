import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mesa/core/failures/auth_failure.dart';
import 'package:mesa/data/firestore/auth_failure_mapper.dart';
import 'package:mesa/domain/models/auth_user.dart';
import 'package:mesa/domain/repositories/auth_repository.dart';

/// [AuthRepository] backed by Firebase Auth, with Google Sign-In layered on
/// top as a credential provider (F1).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._firestore, this._googleSignIn);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  /// `GoogleSignIn.initialize` must run exactly once, and only when Google
  /// Sign-In is actually used — it is a platform call, so doing it during
  /// bootstrap would put it on the cold-start path for no reason (NFR3).
  Future<void>? _googleInitialization;

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges().map(_toAuthUser);

  @override
  AuthUser? get currentUser => _toAuthUser(_auth.currentUser);

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return _guard(() async {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // The profile name is set after creation rather than passed in — Firebase
      // has no way to supply it at sign-up. Reload so the returned AuthUser and
      // the authStateChanges stream both carry it.
      await credential.user?.updateDisplayName(displayName);
      await _auth.currentUser?.reload();

      return _requireUser(_auth.currentUser);
    });
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _guard(() async {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _requireUser(credential.user);
    });
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    return _guard(() async {
      if (!_googleSignIn.supportsAuthenticate()) {
        throw const AuthFailure(
          AuthFailureKind.unknown,
          code: 'google-authenticate-unsupported',
        );
      }

      // On Android the server client id comes from google-services.json's web
      // OAuth client, which the Gradle plugin turns into a per-flavour string
      // resource — so this deliberately passes nothing and stays flavour-correct.
      _googleInitialization ??= _googleSignIn.initialize();
      await _googleInitialization;

      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure(
          AuthFailureKind.unknown,
          code: 'google-missing-id-token',
        );
      }

      final credential = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return _requireUser(credential.user);
    });
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    return _guard(() => _auth.sendPasswordResetEmail(email: email));
  }

  @override
  Future<void> signOut() async {
    await _guard(() async {
      // Google is signed out first so the next sign-in shows the account
      // picker rather than silently reusing the last account.
      try {
        await _googleSignIn.signOut();
      } on GoogleSignInException {
        // Never signed in with Google, or the plugin was never initialized.
        // Not a reason to fail the sign-out.
      }
      await _auth.signOut();
    });

    await _clearLocalCache();
  }

  /// Drops the local Firestore cache so the next account cannot read the
  /// previous one's documents off disk (F1).
  ///
  /// The order is load-bearing. `clearPersistence()` fails while the client is
  /// running, and `terminate()` is what stops it — the SDK documents the pair
  /// as the way to destroy all local state. `terminate()` also means only
  /// `clearPersistence()` may be called on this instance afterwards, but the
  /// Android plugin drops its cached native instance when terminating, so the
  /// next Firestore call builds a fresh client and signing back in works
  /// without restarting the app.
  ///
  /// A failure here is swallowed: the user is already signed out by this point,
  /// and a stale cache behind a signed-out account is a far smaller problem
  /// than a sign-out that appears to fail.
  Future<void> _clearLocalCache() async {
    try {
      await _firestore.terminate();
      await _firestore.clearPersistence();
    } on FirebaseException {
      // Best effort.
    }
  }

  /// Runs [action], normalising provider exceptions into [AuthFailure].
  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailureMapper.fromFirebase(e);
    } on GoogleSignInException catch (e) {
      throw AuthFailureMapper.fromGoogle(e);
    }
  }

  static AuthUser _requireUser(User? user) {
    final mapped = _toAuthUser(user);
    if (mapped == null) {
      throw const AuthFailure(AuthFailureKind.unknown, code: 'missing-user');
    }
    return mapped;
  }

  static AuthUser? _toAuthUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}
