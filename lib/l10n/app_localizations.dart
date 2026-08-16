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

  /// Label of the button that confirms removing something.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// Label of the action that takes an item out of a list it belongs to.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// Label of the action that copies an item.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get commonDuplicate;

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

  /// Field validation message for a count — sets, reps, seconds — that must not be a fraction.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number'**
  String get validationWholeNumberRequired;

  /// Field validation message for a number that may be zero but not negative, such as rest seconds.
  ///
  /// In en, this message translates to:
  /// **'Enter zero or more'**
  String get validationNumberNotNegative;

  /// Field validation message when a block's maximum reps is lower than its minimum (F3).
  ///
  /// In en, this message translates to:
  /// **'The top of the range must not be below the bottom'**
  String get validationRepRangeInverted;

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

  /// Title of the exercise catalogue screen.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get catalogTitle;

  /// Placeholder in the catalogue search field.
  ///
  /// In en, this message translates to:
  /// **'Search exercises'**
  String get catalogSearchHint;

  /// Accessibility label of the button that empties the search field.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get catalogSearchClear;

  /// How many exercises the current search and filters match.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No exercises} =1{1 exercise} other{{count} exercises}}'**
  String catalogResultCount(int count);

  /// Heading shown when a search returns no exercises.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches'**
  String get catalogEmptyTitle;

  /// Body text shown when a search returns no exercises.
  ///
  /// In en, this message translates to:
  /// **'Try a shorter search, or clear the filters.'**
  String get catalogEmptyBody;

  /// Label of the button that removes every active catalogue filter.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get catalogClearFilters;

  /// Title of the catalogue filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get catalogFiltersTitle;

  /// Label of the button that opens the catalogue filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get catalogFiltersAction;

  /// Heading of the body part filter group.
  ///
  /// In en, this message translates to:
  /// **'Body part'**
  String get catalogFilterBodyPart;

  /// Heading of the primary muscle filter group.
  ///
  /// In en, this message translates to:
  /// **'Primary muscle'**
  String get catalogFilterMuscle;

  /// Heading of the equipment filter group.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get catalogFilterEquipment;

  /// Toggle that narrows the catalogue to starred exercises.
  ///
  /// In en, this message translates to:
  /// **'Favourites only'**
  String get catalogFilterFavourites;

  /// Label of the button that closes the filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Show results'**
  String get catalogFilterDone;

  /// Badge marking an exercise the user created rather than a catalogue one.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get catalogCustomBadge;

  /// Label of the button that creates a custom exercise.
  ///
  /// In en, this message translates to:
  /// **'New exercise'**
  String get catalogNewExercise;

  /// Shown when the bundled catalogue asset is missing or unreadable. A build fault, not something the user can fix.
  ///
  /// In en, this message translates to:
  /// **'The exercise catalogue could not be loaded.'**
  String get catalogLoadFailed;

  /// Accessibility label of the unfilled star button.
  ///
  /// In en, this message translates to:
  /// **'Add to favourites'**
  String get catalogFavouriteAdd;

  /// Accessibility label of the filled star button.
  ///
  /// In en, this message translates to:
  /// **'Remove from favourites'**
  String get catalogFavouriteRemove;

  /// Label of the home screen button that opens the exercise catalogue.
  ///
  /// In en, this message translates to:
  /// **'Browse exercises'**
  String get catalogHomeAction;

  /// Heading above an exercise's instruction steps.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get exerciseInstructionsHeading;

  /// Shown on the detail screen when an exercise has no steps.
  ///
  /// In en, this message translates to:
  /// **'No instructions for this exercise.'**
  String get exerciseNoInstructions;

  /// Heading above the muscle breakdown on the detail screen.
  ///
  /// In en, this message translates to:
  /// **'Muscles'**
  String get exerciseMusclesHeading;

  /// Label of the primary muscle on the detail screen.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get exercisePrimaryMuscle;

  /// Label of the synergist muscle on the detail screen.
  ///
  /// In en, this message translates to:
  /// **'Synergist'**
  String get exerciseSynergist;

  /// Label of the secondary muscles on the detail screen.
  ///
  /// In en, this message translates to:
  /// **'Also works'**
  String get exerciseSecondaryMuscles;

  /// Heading above the equipment and load model on the detail screen.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get exerciseEquipmentHeading;

  /// Placeholder shown when exercise media cannot be fetched. Never an error — the rest of the screen works without it (NFR1).
  ///
  /// In en, this message translates to:
  /// **'Image unavailable offline'**
  String get exerciseMediaUnavailable;

  /// Shown when a link points at an exercise that has been deleted.
  ///
  /// In en, this message translates to:
  /// **'That exercise no longer exists.'**
  String get exerciseNotFound;

  /// Label of the button that edits a custom exercise.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get exerciseEdit;

  /// Label of the button that deletes a custom exercise.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get exerciseDelete;

  /// Title of the confirmation dialog before deleting a custom exercise (NFR5).
  ///
  /// In en, this message translates to:
  /// **'Delete this exercise?'**
  String get exerciseDeleteTitle;

  /// Body of the delete confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed. This cannot be undone.'**
  String exerciseDeleteBody(String name);

  /// Confirmation shown after a custom exercise is deleted.
  ///
  /// In en, this message translates to:
  /// **'Exercise deleted'**
  String get exerciseDeleted;

  /// Title of the form that creates a custom exercise.
  ///
  /// In en, this message translates to:
  /// **'New exercise'**
  String get customExerciseNewTitle;

  /// Title of the form that edits a custom exercise.
  ///
  /// In en, this message translates to:
  /// **'Edit exercise'**
  String get customExerciseEditTitle;

  /// Label of the name field on the custom exercise form.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get customExerciseNameLabel;

  /// Label of the instructions field on the custom exercise form.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get customExerciseStepsLabel;

  /// Helper text under the instructions field on the custom exercise form.
  ///
  /// In en, this message translates to:
  /// **'One step per line. Optional.'**
  String get customExerciseStepsHint;

  /// Label above the load model, which is derived from the chosen equipment rather than picked.
  ///
  /// In en, this message translates to:
  /// **'Logged as'**
  String get customExerciseLoadModelLabel;

  /// Confirmation shown after a custom exercise is created or edited.
  ///
  /// In en, this message translates to:
  /// **'Exercise saved'**
  String get customExerciseSaved;

  /// Display name of the externalLoad load model (§5.6).
  ///
  /// In en, this message translates to:
  /// **'Weight you enter'**
  String get loadModelExternal;

  /// Display name of the bodyweight load model (§5.6).
  ///
  /// In en, this message translates to:
  /// **'Bodyweight, tracked by reps'**
  String get loadModelBodyweight;

  /// Display name of the bodyweightPlusLoad load model (§5.6).
  ///
  /// In en, this message translates to:
  /// **'Bodyweight plus added weight'**
  String get loadModelBodyweightPlusLoad;

  /// Display name of the assisted load model, whose load moves inverse to progress (§5.6).
  ///
  /// In en, this message translates to:
  /// **'Assistance, less is better'**
  String get loadModelAssisted;

  /// Body part filter label.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get bodyPartBack;

  /// Body part filter label.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get bodyPartChest;

  /// Body part filter label.
  ///
  /// In en, this message translates to:
  /// **'Lower arms'**
  String get bodyPartLowerArms;

  /// Body part filter label.
  ///
  /// In en, this message translates to:
  /// **'Lower legs'**
  String get bodyPartLowerLegs;

  /// Body part filter label.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get bodyPartNeck;

  /// Body part filter label.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get bodyPartShoulders;

  /// Body part filter label.
  ///
  /// In en, this message translates to:
  /// **'Upper arms'**
  String get bodyPartUpperArms;

  /// Body part filter label.
  ///
  /// In en, this message translates to:
  /// **'Upper legs'**
  String get bodyPartUpperLegs;

  /// Body part filter label.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get bodyPartWaist;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get muscleChest;

  /// Muscle name. The dataset does not distinguish the three heads (§5.4).
  ///
  /// In en, this message translates to:
  /// **'Delts'**
  String get muscleDelts;

  /// Muscle name. Only reachable through the hand-maintained delt head override.
  ///
  /// In en, this message translates to:
  /// **'Front delts'**
  String get muscleFrontDelts;

  /// Muscle name. Only reachable through the hand-maintained delt head override.
  ///
  /// In en, this message translates to:
  /// **'Side delts'**
  String get muscleSideDelts;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Rear delts'**
  String get muscleRearDelts;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Lats'**
  String get muscleLats;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Upper back'**
  String get muscleUpperBack;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Traps'**
  String get muscleTraps;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Biceps'**
  String get muscleBiceps;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Triceps'**
  String get muscleTriceps;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Forearms'**
  String get muscleForearms;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Quads'**
  String get muscleQuads;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Hamstrings'**
  String get muscleHamstrings;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Glutes'**
  String get muscleGlutes;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Calves'**
  String get muscleCalves;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Abs'**
  String get muscleAbs;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Obliques'**
  String get muscleObliques;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Lower back'**
  String get muscleLowerBack;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Hip flexors'**
  String get muscleHipFlexors;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Adductors'**
  String get muscleAdductors;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Abductors'**
  String get muscleAbductors;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get muscleCore;

  /// Muscle name.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get muscleNeck;

  /// Muscle name for the long tail with no home in the enum (§5.4). Deliberately reads as unclassified rather than naming a muscle it is not.
  ///
  /// In en, this message translates to:
  /// **'Unclassified'**
  String get muscleOther;

  /// Equipment name.
  ///
  /// In en, this message translates to:
  /// **'Barbell'**
  String get equipmentBarbell;

  /// Equipment name.
  ///
  /// In en, this message translates to:
  /// **'EZ barbell'**
  String get equipmentEzBarbell;

  /// Equipment name.
  ///
  /// In en, this message translates to:
  /// **'Olympic barbell'**
  String get equipmentOlympicBarbell;

  /// Equipment name.
  ///
  /// In en, this message translates to:
  /// **'Trap bar'**
  String get equipmentTrapBar;

  /// Equipment name.
  ///
  /// In en, this message translates to:
  /// **'Dumbbell'**
  String get equipmentDumbbell;

  /// Equipment name.
  ///
  /// In en, this message translates to:
  /// **'Kettlebell'**
  String get equipmentKettlebell;

  /// Equipment name.
  ///
  /// In en, this message translates to:
  /// **'Cable'**
  String get equipmentCable;

  /// Equipment name.
  ///
  /// In en, this message translates to:
  /// **'Machine'**
  String get equipmentLeverageMachine;

  /// Equipment name.
  ///
  /// In en, this message translates to:
  /// **'Smith machine'**
  String get equipmentSmithMachine;

  /// Equipment name.
  ///
  /// In en, this message translates to:
  /// **'Sled machine'**
  String get equipmentSledMachine;

  /// Equipment name.
  ///
  /// In en, this message translates to:
  /// **'Band'**
  String get equipmentBand;

  /// Equipment name.
  ///
  /// In en, this message translates to:
  /// **'Medicine ball'**
  String get equipmentMedicineBall;

  /// Equipment name.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight'**
  String get equipmentBodyWeight;

  /// Equipment name.
  ///
  /// In en, this message translates to:
  /// **'Weighted'**
  String get equipmentWeighted;

  /// Equipment name.
  ///
  /// In en, this message translates to:
  /// **'Assisted'**
  String get equipmentAssisted;

  /// Equipment name for the long tail: balls, rollers, ropes (§5.4).
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get equipmentOther;

  /// Home screen action opening the program list (F3).
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get homeProgramsAction;

  /// Title of the program list screen (F3).
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get programsTitle;

  /// Action that starts building a new program.
  ///
  /// In en, this message translates to:
  /// **'New program'**
  String get programsNewAction;

  /// Empty state title on the program list.
  ///
  /// In en, this message translates to:
  /// **'No programs yet'**
  String get programsEmptyTitle;

  /// Empty state body on the program list.
  ///
  /// In en, this message translates to:
  /// **'Build one, then start your sessions from it.'**
  String get programsEmptyBody;

  /// Toggle revealing archived programs in the list.
  ///
  /// In en, this message translates to:
  /// **'Show archived'**
  String get programsShowArchived;

  /// Section heading above archived programs.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get programsArchivedHeading;

  /// Program status: built but not in use.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get programStatusDraft;

  /// Program status: the one being trained right now.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get programStatusActive;

  /// Program status: retired, kept for its history.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get programStatusArchived;

  /// Title of the create-program form.
  ///
  /// In en, this message translates to:
  /// **'New program'**
  String get programNewTitle;

  /// Title of the edit-program form.
  ///
  /// In en, this message translates to:
  /// **'Edit program'**
  String get programEditTitle;

  /// Program name field label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get programNameLabel;

  /// Program goal field label.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get programGoalLabel;

  /// Helper text under the program goal field. Free text; nothing computes against it.
  ///
  /// In en, this message translates to:
  /// **'Optional — hypertrophy, strength, whatever you are chasing'**
  String get programGoalHint;

  /// Program daysPerWeek field label (§4).
  ///
  /// In en, this message translates to:
  /// **'Sessions per week'**
  String get programDaysPerWeekLabel;

  /// Helper text explaining that daysPerWeek is sessions, not the number of day templates (§4).
  ///
  /// In en, this message translates to:
  /// **'How often you train. A Push/Pull/Legs split run twice over is three days and six sessions.'**
  String get programDaysPerWeekHint;

  /// Confirmation after saving a program.
  ///
  /// In en, this message translates to:
  /// **'Program saved'**
  String get programSaved;

  /// Shown when a link points at a program that has been removed.
  ///
  /// In en, this message translates to:
  /// **'That program no longer exists.'**
  String get programNotFound;

  /// Action opening the program name/goal form from the detail screen.
  ///
  /// In en, this message translates to:
  /// **'Edit details'**
  String get programEditAction;

  /// Action making this the one active program (F3).
  ///
  /// In en, this message translates to:
  /// **'Make active'**
  String get programActivate;

  /// Confirmation after activating a program.
  ///
  /// In en, this message translates to:
  /// **'{name} is now your active program'**
  String programActivated(String name);

  /// Warning in the activate dialog naming the program that will be displaced, since only one may be active.
  ///
  /// In en, this message translates to:
  /// **'{name} will go back to draft.'**
  String programActivateReplaces(String name);

  /// Title of the activation confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Make this the active program?'**
  String get programActivateTitle;

  /// Action retiring a program (F3).
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get programArchive;

  /// Title of the archive confirmation dialog (NFR5).
  ///
  /// In en, this message translates to:
  /// **'Archive this program?'**
  String get programArchiveTitle;

  /// Body of the archive confirmation dialog, making clear the action is not destructive.
  ///
  /// In en, this message translates to:
  /// **'{name} moves out of your programs list. Nothing you have logged against it is lost, and you can still open it from Show archived.'**
  String programArchiveBody(String name);

  /// Confirmation after archiving a program.
  ///
  /// In en, this message translates to:
  /// **'{name} archived'**
  String programArchived(String name);

  /// Confirmation after duplicating a program.
  ///
  /// In en, this message translates to:
  /// **'{name} created'**
  String programDuplicated(String name);

  /// Name given to a duplicated program or day.
  ///
  /// In en, this message translates to:
  /// **'{name} (copy)'**
  String programCopyName(String name);

  /// Section heading above a program's day templates.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get programDaysHeading;

  /// Helper text above the reorderable day list.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder. Sessions follow this order.'**
  String get programDaysHint;

  /// Action appending a new day template to a program.
  ///
  /// In en, this message translates to:
  /// **'Add day'**
  String get programAddDay;

  /// How many day templates a program holds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No days} =1{1 day} other{{count} days}}'**
  String programDayCount(int count);

  /// How many blocks a day holds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No exercises} =1{1 exercise} other{{count} exercises}}'**
  String programBlockCount(int count);

  /// Title of the week-role editor (F3).
  ///
  /// In en, this message translates to:
  /// **'Week roles'**
  String get weekRolesTitle;

  /// Action opening the week-role editor from the program detail screen.
  ///
  /// In en, this message translates to:
  /// **'Week roles'**
  String get weekRolesAction;

  /// Helper text above the reorderable week-role list (§3).
  ///
  /// In en, this message translates to:
  /// **'One pass through these is a mesocycle. Drag to reorder.'**
  String get weekRolesHint;

  /// Empty state title in the week-role editor.
  ///
  /// In en, this message translates to:
  /// **'No weeks yet'**
  String get weekRolesEmptyTitle;

  /// Empty state body in the week-role editor.
  ///
  /// In en, this message translates to:
  /// **'Add at least one week so the program has something to prescribe.'**
  String get weekRolesEmptyBody;

  /// Action appending a week role.
  ///
  /// In en, this message translates to:
  /// **'Add week'**
  String get weekRoleAdd;

  /// Confirmation after saving the week roles.
  ///
  /// In en, this message translates to:
  /// **'Week roles saved'**
  String get weekRoleSaved;

  /// How many weeks are in a program's mesocycle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No weeks} =1{1 week} other{{count} weeks}}'**
  String weekRoleCount(int count);

  /// Position of a week in the mesocycle, counted from one. The position is the week's identity, not its role name, which may repeat.
  ///
  /// In en, this message translates to:
  /// **'Week {number}'**
  String weekRoleWeekNumber(int number);

  /// Week role RPE target field label (§7.2).
  ///
  /// In en, this message translates to:
  /// **'Target RPE'**
  String get weekRoleRpeLabel;

  /// Week role volume multiplier field label (§7.2).
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get weekRoleVolumeLabel;

  /// One-line summary of a week role's targets.
  ///
  /// In en, this message translates to:
  /// **'RPE {rpe} · {volume} volume'**
  String weekRoleSummary(String rpe, String volume);

  /// Week role name.
  ///
  /// In en, this message translates to:
  /// **'Base'**
  String get weekRoleBase;

  /// Week role name.
  ///
  /// In en, this message translates to:
  /// **'Intensification'**
  String get weekRoleIntensification;

  /// Week role name.
  ///
  /// In en, this message translates to:
  /// **'Peak'**
  String get weekRolePeak;

  /// Week role name.
  ///
  /// In en, this message translates to:
  /// **'Deload'**
  String get weekRoleDeload;

  /// Default name given to a freshly added day template.
  ///
  /// In en, this message translates to:
  /// **'New day'**
  String get dayNewName;

  /// Day name field label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get dayNameLabel;

  /// Action opening the rename dialog for a day.
  ///
  /// In en, this message translates to:
  /// **'Rename day'**
  String get dayRename;

  /// Title of the delete-day confirmation dialog (NFR5).
  ///
  /// In en, this message translates to:
  /// **'Delete this day?'**
  String get dayDeleteTitle;

  /// Body of the delete-day confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'{name} and its exercises will be removed from this program. This cannot be undone.'**
  String dayDeleteBody(String name);

  /// Confirmation after deleting a day.
  ///
  /// In en, this message translates to:
  /// **'Day deleted'**
  String get dayDeleted;

  /// Confirmation after duplicating a day.
  ///
  /// In en, this message translates to:
  /// **'{name} created'**
  String dayDuplicated(String name);

  /// Empty state title in the day editor.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet'**
  String get dayEmptyTitle;

  /// Empty state body in the day editor.
  ///
  /// In en, this message translates to:
  /// **'Add the exercises you work through on this day.'**
  String get dayEmptyBody;

  /// Helper text above the reorderable block list (F3).
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder. This is the order you work through them.'**
  String get dayBlocksHint;

  /// Action adding a block to a day.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get dayAddBlock;

  /// Shown when a link points at a day that has been removed.
  ///
  /// In en, this message translates to:
  /// **'That day no longer exists.'**
  String get dayNotFound;

  /// Title of the create-block form.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get blockNewTitle;

  /// Title of the edit-block form.
  ///
  /// In en, this message translates to:
  /// **'Edit exercise'**
  String get blockEditTitle;

  /// Label above the chosen exercise in the block form.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get blockExerciseLabel;

  /// Prompt shown when a block has no exercise picked yet.
  ///
  /// In en, this message translates to:
  /// **'Choose an exercise'**
  String get blockChooseExercise;

  /// Section heading above the sets/reps/RPE/rest fields (§3).
  ///
  /// In en, this message translates to:
  /// **'Set scheme'**
  String get blockSchemeHeading;

  /// Set scheme field label.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get blockSetsLabel;

  /// Bottom of the rep range.
  ///
  /// In en, this message translates to:
  /// **'Reps from'**
  String get blockRepMinLabel;

  /// Top of the rep range.
  ///
  /// In en, this message translates to:
  /// **'to'**
  String get blockRepMaxLabel;

  /// Block RPE target field label.
  ///
  /// In en, this message translates to:
  /// **'Target RPE'**
  String get blockRpeLabel;

  /// Helper text distinguishing the block's RPE target from the week role's (§7.2).
  ///
  /// In en, this message translates to:
  /// **'The baseline for this exercise, before the week role is applied.'**
  String get blockRpeHint;

  /// Block rest field label.
  ///
  /// In en, this message translates to:
  /// **'Rest (seconds)'**
  String get blockRestLabel;

  /// Block free-text notes field label (F3).
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get blockNotesLabel;

  /// Section heading above a block's substitute exercises (F3).
  ///
  /// In en, this message translates to:
  /// **'Alternatives'**
  String get blockAlternativesHeading;

  /// Helper text above the alternatives list. §F7's computed ranking arrives in M7; this list always outranks it.
  ///
  /// In en, this message translates to:
  /// **'In your order of preference, for when the gym cannot supply this one.'**
  String get blockAlternativesHint;

  /// Action adding a substitute exercise to a block.
  ///
  /// In en, this message translates to:
  /// **'Add alternative'**
  String get blockAddAlternative;

  /// Confirmation after saving a block.
  ///
  /// In en, this message translates to:
  /// **'Exercise saved'**
  String get blockSaved;

  /// Title of the remove-block confirmation dialog (NFR5).
  ///
  /// In en, this message translates to:
  /// **'Remove this exercise?'**
  String get blockDeleteTitle;

  /// Body of the remove-block confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'{name} will be removed from this day. This cannot be undone.'**
  String blockDeleteBody(String name);

  /// Confirmation after removing a block.
  ///
  /// In en, this message translates to:
  /// **'Exercise removed'**
  String get blockDeleted;

  /// One-line summary of a block's prescription.
  ///
  /// In en, this message translates to:
  /// **'{sets} × {repMin}-{repMax} @ RPE {rpe}'**
  String blockSchemeSummary(int sets, int repMin, int repMax, String rpe);

  /// Rest interval shown alongside a block's scheme.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s rest'**
  String blockRestSummary(int seconds);

  /// How many substitutes a block carries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{} =1{1 alternative} other{{count} alternatives}}'**
  String blockAlternativeCount(int count);

  /// Shown in place of a block's exercise name when the id resolves to nothing — a custom exercise the user deleted.
  ///
  /// In en, this message translates to:
  /// **'Exercise no longer available'**
  String get blockExerciseMissing;

  /// Title of the modal exercise picker used by the program builder.
  ///
  /// In en, this message translates to:
  /// **'Choose an exercise'**
  String get exercisePickerTitle;
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
