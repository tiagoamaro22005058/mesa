import 'package:mesa/core/formatters/weight_format.dart';
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
    final parsed = parseWeight(value);
    if (parsed == null) return l10n.validationNumberRequired;
    if (parsed <= 0) return l10n.validationNumberPositive;
    return null;
  }

  /// A count: sets, reps, sessions per week. Whole and above zero.
  static String? positiveInt(AppLocalizations l10n, String? value) {
    final parsed = parseCount(value);
    if (parsed == null) return l10n.validationWholeNumberRequired;
    if (parsed <= 0) return l10n.validationNumberPositive;
    return null;
  }

  /// Rest between sets, in seconds. Zero is allowed — a superset has no rest.
  static String? restSeconds(AppLocalizations l10n, String? value) {
    final parsed = parseCount(value);
    if (parsed == null) return l10n.validationWholeNumberRequired;
    if (parsed < 0) return l10n.validationNumberNotNegative;
    return null;
  }

  /// The top of a rep range, checked against the bottom of it.
  ///
  /// Takes the other field's text the way [passwordConfirmation] does — a
  /// `TextFormField.validator` only ever sees its own value, so the pair has to
  /// be compared from one side. `repMin == repMax` is a fixed rep count and
  /// perfectly valid; only an inverted range is rejected.
  static String? repMax(AppLocalizations l10n, String? value, String? repMin) {
    final invalid = positiveInt(l10n, value);
    if (invalid != null) return invalid;

    final min = parseCount(repMin);
    final max = parseCount(value);
    if (min != null && max != null && max < min) {
      return l10n.validationRepRangeInverted;
    }
    return null;
  }
}
