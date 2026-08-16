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
  String get commonDelete => 'Delete';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonDuplicate => 'Duplicate';

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
  String get validationWholeNumberRequired => 'Enter a whole number';

  @override
  String get validationNumberNotNegative => 'Enter zero or more';

  @override
  String get validationRepRangeInverted =>
      'The top of the range must not be below the bottom';

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

  @override
  String get catalogTitle => 'Exercises';

  @override
  String get catalogSearchHint => 'Search exercises';

  @override
  String get catalogSearchClear => 'Clear search';

  @override
  String catalogResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
      zero: 'No exercises',
    );
    return '$_temp0';
  }

  @override
  String get catalogEmptyTitle => 'Nothing matches';

  @override
  String get catalogEmptyBody => 'Try a shorter search, or clear the filters.';

  @override
  String get catalogClearFilters => 'Clear filters';

  @override
  String get catalogFiltersTitle => 'Filters';

  @override
  String get catalogFiltersAction => 'Filter';

  @override
  String get catalogFilterBodyPart => 'Body part';

  @override
  String get catalogFilterMuscle => 'Primary muscle';

  @override
  String get catalogFilterEquipment => 'Equipment';

  @override
  String get catalogFilterFavourites => 'Favourites only';

  @override
  String get catalogFilterDone => 'Show results';

  @override
  String get catalogCustomBadge => 'Custom';

  @override
  String get catalogNewExercise => 'New exercise';

  @override
  String get catalogLoadFailed => 'The exercise catalogue could not be loaded.';

  @override
  String get catalogFavouriteAdd => 'Add to favourites';

  @override
  String get catalogFavouriteRemove => 'Remove from favourites';

  @override
  String get catalogHomeAction => 'Browse exercises';

  @override
  String get exerciseInstructionsHeading => 'Instructions';

  @override
  String get exerciseNoInstructions => 'No instructions for this exercise.';

  @override
  String get exerciseMusclesHeading => 'Muscles';

  @override
  String get exercisePrimaryMuscle => 'Primary';

  @override
  String get exerciseSynergist => 'Synergist';

  @override
  String get exerciseSecondaryMuscles => 'Also works';

  @override
  String get exerciseEquipmentHeading => 'Equipment';

  @override
  String get exerciseMediaUnavailable => 'Image unavailable offline';

  @override
  String get exerciseNotFound => 'That exercise no longer exists.';

  @override
  String get exerciseEdit => 'Edit';

  @override
  String get exerciseDelete => 'Delete';

  @override
  String get exerciseDeleteTitle => 'Delete this exercise?';

  @override
  String exerciseDeleteBody(String name) {
    return '$name will be removed. This cannot be undone.';
  }

  @override
  String get exerciseDeleted => 'Exercise deleted';

  @override
  String get customExerciseNewTitle => 'New exercise';

  @override
  String get customExerciseEditTitle => 'Edit exercise';

  @override
  String get customExerciseNameLabel => 'Name';

  @override
  String get customExerciseStepsLabel => 'Instructions';

  @override
  String get customExerciseStepsHint => 'One step per line. Optional.';

  @override
  String get customExerciseLoadModelLabel => 'Logged as';

  @override
  String get customExerciseSaved => 'Exercise saved';

  @override
  String get loadModelExternal => 'Weight you enter';

  @override
  String get loadModelBodyweight => 'Bodyweight, tracked by reps';

  @override
  String get loadModelBodyweightPlusLoad => 'Bodyweight plus added weight';

  @override
  String get loadModelAssisted => 'Assistance, less is better';

  @override
  String get bodyPartBack => 'Back';

  @override
  String get bodyPartChest => 'Chest';

  @override
  String get bodyPartLowerArms => 'Lower arms';

  @override
  String get bodyPartLowerLegs => 'Lower legs';

  @override
  String get bodyPartNeck => 'Neck';

  @override
  String get bodyPartShoulders => 'Shoulders';

  @override
  String get bodyPartUpperArms => 'Upper arms';

  @override
  String get bodyPartUpperLegs => 'Upper legs';

  @override
  String get bodyPartWaist => 'Waist';

  @override
  String get muscleChest => 'Chest';

  @override
  String get muscleDelts => 'Delts';

  @override
  String get muscleFrontDelts => 'Front delts';

  @override
  String get muscleSideDelts => 'Side delts';

  @override
  String get muscleRearDelts => 'Rear delts';

  @override
  String get muscleLats => 'Lats';

  @override
  String get muscleUpperBack => 'Upper back';

  @override
  String get muscleTraps => 'Traps';

  @override
  String get muscleBiceps => 'Biceps';

  @override
  String get muscleTriceps => 'Triceps';

  @override
  String get muscleForearms => 'Forearms';

  @override
  String get muscleQuads => 'Quads';

  @override
  String get muscleHamstrings => 'Hamstrings';

  @override
  String get muscleGlutes => 'Glutes';

  @override
  String get muscleCalves => 'Calves';

  @override
  String get muscleAbs => 'Abs';

  @override
  String get muscleObliques => 'Obliques';

  @override
  String get muscleLowerBack => 'Lower back';

  @override
  String get muscleHipFlexors => 'Hip flexors';

  @override
  String get muscleAdductors => 'Adductors';

  @override
  String get muscleAbductors => 'Abductors';

  @override
  String get muscleCore => 'Core';

  @override
  String get muscleNeck => 'Neck';

  @override
  String get muscleOther => 'Unclassified';

  @override
  String get equipmentBarbell => 'Barbell';

  @override
  String get equipmentEzBarbell => 'EZ barbell';

  @override
  String get equipmentOlympicBarbell => 'Olympic barbell';

  @override
  String get equipmentTrapBar => 'Trap bar';

  @override
  String get equipmentDumbbell => 'Dumbbell';

  @override
  String get equipmentKettlebell => 'Kettlebell';

  @override
  String get equipmentCable => 'Cable';

  @override
  String get equipmentLeverageMachine => 'Machine';

  @override
  String get equipmentSmithMachine => 'Smith machine';

  @override
  String get equipmentSledMachine => 'Sled machine';

  @override
  String get equipmentBand => 'Band';

  @override
  String get equipmentMedicineBall => 'Medicine ball';

  @override
  String get equipmentBodyWeight => 'Bodyweight';

  @override
  String get equipmentWeighted => 'Weighted';

  @override
  String get equipmentAssisted => 'Assisted';

  @override
  String get equipmentOther => 'Other';

  @override
  String get homeProgramsAction => 'Programs';

  @override
  String get programsTitle => 'Programs';

  @override
  String get programsNewAction => 'New program';

  @override
  String get programsEmptyTitle => 'No programs yet';

  @override
  String get programsEmptyBody =>
      'Build one, then start your sessions from it.';

  @override
  String get programsShowArchived => 'Show archived';

  @override
  String get programsArchivedHeading => 'Archived';

  @override
  String get programStatusDraft => 'Draft';

  @override
  String get programStatusActive => 'Active';

  @override
  String get programStatusArchived => 'Archived';

  @override
  String get programNewTitle => 'New program';

  @override
  String get programEditTitle => 'Edit program';

  @override
  String get programNameLabel => 'Name';

  @override
  String get programGoalLabel => 'Goal';

  @override
  String get programGoalHint =>
      'Optional — hypertrophy, strength, whatever you are chasing';

  @override
  String get programDaysPerWeekLabel => 'Sessions per week';

  @override
  String get programDaysPerWeekHint =>
      'How often you train. A Push/Pull/Legs split run twice over is three days and six sessions.';

  @override
  String get programSaved => 'Program saved';

  @override
  String get programNotFound => 'That program no longer exists.';

  @override
  String get programEditAction => 'Edit details';

  @override
  String get programActivate => 'Make active';

  @override
  String programActivated(String name) {
    return '$name is now your active program';
  }

  @override
  String programActivateReplaces(String name) {
    return '$name will go back to draft.';
  }

  @override
  String get programActivateTitle => 'Make this the active program?';

  @override
  String get programArchive => 'Archive';

  @override
  String get programArchiveTitle => 'Archive this program?';

  @override
  String programArchiveBody(String name) {
    return '$name moves out of your programs list. Nothing you have logged against it is lost, and you can still open it from Show archived.';
  }

  @override
  String programArchived(String name) {
    return '$name archived';
  }

  @override
  String programDuplicated(String name) {
    return '$name created';
  }

  @override
  String programCopyName(String name) {
    return '$name (copy)';
  }

  @override
  String get programDaysHeading => 'Days';

  @override
  String get programDaysHint => 'Drag to reorder. Sessions follow this order.';

  @override
  String get programAddDay => 'Add day';

  @override
  String programDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
      zero: 'No days',
    );
    return '$_temp0';
  }

  @override
  String programBlockCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
      zero: 'No exercises',
    );
    return '$_temp0';
  }

  @override
  String get weekRolesTitle => 'Week roles';

  @override
  String get weekRolesAction => 'Week roles';

  @override
  String get weekRolesHint =>
      'One pass through these is a mesocycle. Drag to reorder.';

  @override
  String get weekRolesEmptyTitle => 'No weeks yet';

  @override
  String get weekRolesEmptyBody =>
      'Add at least one week so the program has something to prescribe.';

  @override
  String get weekRoleAdd => 'Add week';

  @override
  String get weekRoleSaved => 'Week roles saved';

  @override
  String weekRoleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
      zero: 'No weeks',
    );
    return '$_temp0';
  }

  @override
  String weekRoleWeekNumber(int number) {
    return 'Week $number';
  }

  @override
  String get weekRoleRpeLabel => 'Target RPE';

  @override
  String get weekRoleVolumeLabel => 'Volume';

  @override
  String weekRoleSummary(String rpe, String volume) {
    return 'RPE $rpe · $volume volume';
  }

  @override
  String get weekRoleBase => 'Base';

  @override
  String get weekRoleIntensification => 'Intensification';

  @override
  String get weekRolePeak => 'Peak';

  @override
  String get weekRoleDeload => 'Deload';

  @override
  String get dayNewName => 'New day';

  @override
  String get dayNameLabel => 'Name';

  @override
  String get dayRename => 'Rename day';

  @override
  String get dayDeleteTitle => 'Delete this day?';

  @override
  String dayDeleteBody(String name) {
    return '$name and its exercises will be removed from this program. This cannot be undone.';
  }

  @override
  String get dayDeleted => 'Day deleted';

  @override
  String dayDuplicated(String name) {
    return '$name created';
  }

  @override
  String get dayEmptyTitle => 'No exercises yet';

  @override
  String get dayEmptyBody => 'Add the exercises you work through on this day.';

  @override
  String get dayBlocksHint =>
      'Drag to reorder. This is the order you work through them.';

  @override
  String get dayAddBlock => 'Add exercise';

  @override
  String get dayNotFound => 'That day no longer exists.';

  @override
  String get blockNewTitle => 'Add exercise';

  @override
  String get blockEditTitle => 'Edit exercise';

  @override
  String get blockExerciseLabel => 'Exercise';

  @override
  String get blockChooseExercise => 'Choose an exercise';

  @override
  String get blockSchemeHeading => 'Set scheme';

  @override
  String get blockSetsLabel => 'Sets';

  @override
  String get blockRepMinLabel => 'Reps from';

  @override
  String get blockRepMaxLabel => 'to';

  @override
  String get blockRpeLabel => 'Target RPE';

  @override
  String get blockRpeHint =>
      'The baseline for this exercise, before the week role is applied.';

  @override
  String get blockRestLabel => 'Rest (seconds)';

  @override
  String get blockNotesLabel => 'Notes';

  @override
  String get blockAlternativesHeading => 'Alternatives';

  @override
  String get blockAlternativesHint =>
      'In your order of preference, for when the gym cannot supply this one.';

  @override
  String get blockAddAlternative => 'Add alternative';

  @override
  String get blockSaved => 'Exercise saved';

  @override
  String get blockDeleteTitle => 'Remove this exercise?';

  @override
  String blockDeleteBody(String name) {
    return '$name will be removed from this day. This cannot be undone.';
  }

  @override
  String get blockDeleted => 'Exercise removed';

  @override
  String blockSchemeSummary(int sets, int repMin, int repMax, String rpe) {
    return '$sets × $repMin-$repMax @ RPE $rpe';
  }

  @override
  String blockRestSummary(int seconds) {
    return '${seconds}s rest';
  }

  @override
  String blockAlternativeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alternatives',
      one: '1 alternative',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String get blockExerciseMissing => 'Exercise no longer available';

  @override
  String get exercisePickerTitle => 'Choose an exercise';
}
