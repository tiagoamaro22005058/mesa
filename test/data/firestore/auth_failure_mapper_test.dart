import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mesa/core/failures/auth_failure.dart';
import 'package:mesa/data/firestore/auth_failure_mapper.dart';

void main() {
  group('AuthFailureMapper.fromFirebase', () {
    const cases = <String, AuthFailureKind>{
      'invalid-credential': AuthFailureKind.invalidCredentials,
      'wrong-password': AuthFailureKind.invalidCredentials,
      'invalid-login-credentials': AuthFailureKind.invalidCredentials,
      'email-already-in-use': AuthFailureKind.emailInUse,
      'weak-password': AuthFailureKind.weakPassword,
      'invalid-email': AuthFailureKind.invalidEmail,
      'user-not-found': AuthFailureKind.userNotFound,
      'user-disabled': AuthFailureKind.userDisabled,
      'network-request-failed': AuthFailureKind.networkUnavailable,
      'too-many-requests': AuthFailureKind.tooManyRequests,
    };

    cases.forEach((code, expected) {
      test('maps $code to ${expected.name}', () {
        final failure = AuthFailureMapper.fromFirebase(
          FirebaseAuthException(code: code),
        );

        expect(failure.kind, expected);
        expect(failure.code, isNull, reason: 'only unknown failures keep the code');
      });
    });

    test('keeps the original code for anything unmapped', () {
      final failure = AuthFailureMapper.fromFirebase(
        FirebaseAuthException(code: 'operation-not-allowed'),
      );

      expect(failure.kind, AuthFailureKind.unknown);
      expect(failure.code, 'operation-not-allowed');
    });
  });

  group('AuthFailureMapper.fromGoogle', () {
    test('treats backing out of the picker as cancellation', () {
      final failure = AuthFailureMapper.fromGoogle(
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      );

      expect(failure.kind, AuthFailureKind.cancelled);
    });

    test('treats an interruption as a connectivity problem', () {
      final failure = AuthFailureMapper.fromGoogle(
        const GoogleSignInException(code: GoogleSignInExceptionCode.interrupted),
      );

      expect(failure.kind, AuthFailureKind.networkUnavailable);
    });

    test('keeps the code for a misconfigured client', () {
      final failure = AuthFailureMapper.fromGoogle(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        ),
      );

      expect(failure.kind, AuthFailureKind.unknown);
      expect(failure.code, 'clientConfigurationError');
    });
  });
}
