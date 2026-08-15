import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The application name, shown in the task switcher and app bars.
  ///
  /// In en, this message translates to:
  /// **'Mesa'**
  String get appTitle;

  /// Label of the button that commits an edited form.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Label of the button that dismisses a form without saving.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Label of the button that re-runs a failed action.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// Title of the sign-in screen and its submit button.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignInTitle;

  /// Title of the sign-up screen and its submit button.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authSignUpTitle;

  /// Title of the password reset screen and its submit button.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetTitle;

  /// Label of the email address field on the auth forms.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// Label of the password field on the auth forms.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// Label of the second password field on the sign-up form.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordLabel;

  /// Label of the display name field on the sign-up form.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get authDisplayNameLabel;

  /// Label of the button that starts the Google Sign-In flow.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authGoogleButton;

  /// Link from the sign-in screen to the sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'No account? Create one'**
  String get authNoAccountPrompt;

  /// Link from the sign-up screen back to the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccountPrompt;

  /// Link from the sign-in screen to the password reset screen.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get authForgotPasswordPrompt;

  /// Explanatory text above the password reset form.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we will send you a link to set a new password.'**
  String get authResetInstructions;

  /// Confirmation after requesting a password reset. Deliberately non-committal so the screen does not reveal whether an account exists.
  ///
  /// In en, this message translates to:
  /// **'If that address has an account, a reset link is on its way.'**
  String get authResetSent;

  /// Shown when sign-in is rejected. Covers both a wrong password and an unknown address, which Firebase reports identically.
  ///
  /// In en, this message translates to:
  /// **'That email and password do not match an account.'**
  String get authErrorInvalidCredentials;

  /// Shown when sign-up targets an existing account.
  ///
  /// In en, this message translates to:
  /// **'That email address already has an account.'**
  String get authErrorEmailInUse;

  /// Shown when the chosen password is too weak.
  ///
  /// In en, this message translates to:
  /// **'Pick a longer password — at least six characters.'**
  String get authErrorWeakPassword;

  /// Shown when the server rejects the email format.
  ///
  /// In en, this message translates to:
  /// **'That does not look like an email address.'**
  String get authErrorInvalidEmail;

  /// Shown when the account cannot be found.
  ///
  /// In en, this message translates to:
  /// **'No account exists for that email address.'**
  String get authErrorUserNotFound;

  /// Shown when the account exists but is disabled.
  ///
  /// In en, this message translates to:
  /// **'That account has been disabled.'**
  String get authErrorUserDisabled;

  /// Shown when auth fails for lack of connectivity. NFR1 exempts sign-in and sign-up from working offline.
  ///
  /// In en, this message translates to:
  /// **'No connection. Signing in is the one thing that needs it.'**
  String get authErrorNetwork;

  /// Shown when the provider rate-limits sign-in attempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and try again.'**
  String get authErrorTooManyRequests;

  /// Fallback for an unmapped authentication error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get authErrorUnknown;

  /// Field validation message for an empty email field.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get validationEmailRequired;

  /// Field validation message for a malformed email address.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get validationEmailInvalid;

  /// Field validation message for an empty password field.
  ///
  /// In en, this message translates to:
  /// **'Enter a password'**
  String get validationPasswordRequired;

  /// Field validation message for a password below the minimum length.
  ///
  /// In en, this message translates to:
  /// **'Use at least six characters'**
  String get validationPasswordTooShort;

  /// Field validation message when the confirmation does not match the password.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordsDoNotMatch;

  /// Field validation message for an empty display name field.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get validationNameRequired;

  /// Field validation message for an empty or non-numeric field.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get validationNumberRequired;

  /// Field validation message for a number that must be greater than zero.
  ///
  /// In en, this message translates to:
  /// **'Enter a number above zero'**
  String get validationNumberPositive;

  /// Line on the home screen naming the signed-in account.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String homeGreeting(String name);

  /// Body text on the home screen explaining what is and is not built yet.
  ///
  /// In en, this message translates to:
  /// **'Auth and your profile are wired up. The exercise catalogue arrives in M2.'**
  String get homePlaceholderBody;

  /// Label of the button opening the profile screen.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get homeProfileAction;

  /// Label of the button that signs the current account out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get homeSignOutAction;

  /// Title of the profile settings screen.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Label of the display name field on the profile screen.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileDisplayNameLabel;

  /// Label of the unit system selector on the profile screen.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get profileUnitsLabel;

  /// Option label for the metric unit system.
  ///
  /// In en, this message translates to:
  /// **'Kilograms'**
  String get profileUnitsKg;

  /// Option label for the imperial unit system.
  ///
  /// In en, this message translates to:
  /// **'Pounds'**
  String get profileUnitsLb;

  /// Label of the barbell weight field on the profile screen.
  ///
  /// In en, this message translates to:
  /// **'Bar weight'**
  String get profileBarWeightLabel;

  /// Label of the smallest dumbbell step field on the profile screen.
  ///
  /// In en, this message translates to:
  /// **'Dumbbell increment'**
  String get profileDumbbellIncrementLabel;

  /// Label of the plate inventory selector on the profile screen.
  ///
  /// In en, this message translates to:
  /// **'Plate inventory'**
  String get profilePlateInventoryLabel;

  /// Explanatory text under the plate inventory selector.
  ///
  /// In en, this message translates to:
  /// **'The plates your gym actually has. Load suggestions round to what you can build.'**
  String get profilePlateInventoryHint;

  /// Confirmation shown after the profile is saved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// Shown while the profile document is being read for the first time.
  ///
  /// In en, this message translates to:
  /// **'Loading your profile…'**
  String get profileLoading;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
