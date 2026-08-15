import 'package:mesa/core/failures/auth_failure.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// The message shown for a failed authentication attempt.
///
/// Returns `null` for failures with nothing worth saying — backing out of the
/// Google account picker is a decision, not an error, and an error bar for it
/// would be noise. Anything that is not an [AuthFailure] falls back to the
/// generic message rather than leaking an exception's `toString()` on screen.
String? authFailureMessage(AppLocalizations l10n, Object error) {
  if (error is! AuthFailure) return l10n.authErrorUnknown;

  return switch (error.kind) {
    AuthFailureKind.cancelled => null,
    AuthFailureKind.invalidCredentials => l10n.authErrorInvalidCredentials,
    AuthFailureKind.emailInUse => l10n.authErrorEmailInUse,
    AuthFailureKind.weakPassword => l10n.authErrorWeakPassword,
    AuthFailureKind.invalidEmail => l10n.authErrorInvalidEmail,
    AuthFailureKind.userNotFound => l10n.authErrorUserNotFound,
    AuthFailureKind.userDisabled => l10n.authErrorUserDisabled,
    AuthFailureKind.networkUnavailable => l10n.authErrorNetwork,
    AuthFailureKind.tooManyRequests => l10n.authErrorTooManyRequests,
    AuthFailureKind.unknown => l10n.authErrorUnknown,
  };
}
