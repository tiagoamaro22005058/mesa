import 'package:mesa/l10n/app_localizations.dart';

/// Form validators shared by the auth and profile forms.
///
/// Each returns `null` when the value is acceptable and a localised message
/// otherwise, matching `TextFormField.validator`'s contract (NFR7).
abstract final class Validators {
  /// Firebase's own minimum. Enforced client-side too so the user finds out
  /// before a round-trip.
  static const int minPasswordLength = 6;

  /// Deliberately loose. The server is the authority on whether an address is
  /// real; this only catches obvious typos before a round-trip.
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(AppLocalizations l10n, String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return l10n.validationEmailRequired;
    if (!_email.hasMatch(trimmed)) return l10n.validationEmailInvalid;
    return null;
  }

  static String? password(AppLocalizations l10n, String? value) {
    final password = value ?? '';
    if (password.isEmpty) return l10n.validationPasswordRequired;
    if (password.length < minPasswordLength) return l10n.validationPasswordTooShort;
    return null;
  }

  static String? passwordConfirmation(
    AppLocalizations l10n,
    String? value,
    String password,
  ) {
    if (value != password) return l10n.validationPasswordsDoNotMatch;
    return null;
  }

  static String? displayName(AppLocalizations l10n, String? value) {
    if ((value?.trim() ?? '').isEmpty) return l10n.validationNameRequired;
    return null;
  }

  /// A weight or increment. Must parse and be above zero.
  static String? positiveNumber(AppLocalizations l10n, String? value) {
    final parsed = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (parsed == null) return l10n.validationNumberRequired;
    if (parsed <= 0) return l10n.validationNumberPositive;
    return null;
  }
}
