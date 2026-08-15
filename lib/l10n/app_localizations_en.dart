// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mesa';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRetry => 'Try again';

  @override
  String get authSignInTitle => 'Sign in';

  @override
  String get authSignUpTitle => 'Create account';

  @override
  String get authResetTitle => 'Reset password';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authDisplayNameLabel => 'Name';

  @override
  String get authGoogleButton => 'Continue with Google';

  @override
  String get authNoAccountPrompt => 'No account? Create one';

  @override
  String get authHaveAccountPrompt => 'Already have an account? Sign in';

  @override
  String get authForgotPasswordPrompt => 'Forgot your password?';

  @override
  String get authResetInstructions =>
      'Enter your email address and we will send you a link to set a new password.';

  @override
  String get authResetSent =>
      'If that address has an account, a reset link is on its way.';

  @override
  String get authErrorInvalidCredentials =>
      'That email and password do not match an account.';

  @override
  String get authErrorEmailInUse =>
      'That email address already has an account.';

  @override
  String get authErrorWeakPassword =>
      'Pick a longer password — at least six characters.';

  @override
  String get authErrorInvalidEmail =>
      'That does not look like an email address.';

  @override
  String get authErrorUserNotFound =>
      'No account exists for that email address.';

  @override
  String get authErrorUserDisabled => 'That account has been disabled.';

  @override
  String get authErrorNetwork =>
      'No connection. Signing in is the one thing that needs it.';

  @override
  String get authErrorTooManyRequests =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get authErrorUnknown => 'Something went wrong. Try again.';

  @override
  String get validationEmailRequired => 'Enter your email address';

  @override
  String get validationEmailInvalid => 'Enter a valid email address';

  @override
  String get validationPasswordRequired => 'Enter a password';

  @override
  String get validationPasswordTooShort => 'Use at least six characters';

  @override
  String get validationPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get validationNameRequired => 'Enter your name';

  @override
  String get validationNumberRequired => 'Enter a number';

  @override
  String get validationNumberPositive => 'Enter a number above zero';

  @override
  String homeGreeting(String name) {
    return 'Signed in as $name';
  }

  @override
  String get homePlaceholderBody =>
      'Auth and your profile are wired up. The exercise catalogue arrives in M2.';

  @override
  String get homeProfileAction => 'Profile';

  @override
  String get homeSignOutAction => 'Sign out';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileDisplayNameLabel => 'Display name';

  @override
  String get profileUnitsLabel => 'Units';

  @override
  String get profileUnitsKg => 'Kilograms';

  @override
  String get profileUnitsLb => 'Pounds';

  @override
  String get profileBarWeightLabel => 'Bar weight';

  @override
  String get profileDumbbellIncrementLabel => 'Dumbbell increment';

  @override
  String get profilePlateInventoryLabel => 'Plate inventory';

  @override
  String get profilePlateInventoryHint =>
      'The plates your gym actually has. Load suggestions round to what you can build.';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profileLoading => 'Loading your profile…';
}
