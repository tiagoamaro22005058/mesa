import 'package:mesa/domain/models/body_part.dart';
import 'package:mesa/domain/models/equipment.dart';
import 'package:mesa/domain/models/load_model.dart';
import 'package:mesa/domain/models/muscle.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// Localised display names for the catalogue enums (NFR7).
///
/// One switch per enum, exhaustive, so adding a member is a compile error here
/// rather than a blank chip on the screen. The enums themselves stay free of
/// display strings — they are wire values and nothing else, and `domain/`
/// imports nothing from Flutter (§9).
abstract final class ExerciseLabels {
  static String bodyPart(AppLocalizations l10n, BodyPart value) => switch (value) {
    BodyPart.back => l10n.bodyPartBack,
    BodyPart.chest => l10n.bodyPartChest,
    BodyPart.lowerArms => l10n.bodyPartLowerArms,
    BodyPart.lowerLegs => l10n.bodyPartLowerLegs,
    BodyPart.neck => l10n.bodyPartNeck,
    BodyPart.shoulders => l10n.bodyPartShoulders,
    BodyPart.upperArms => l10n.bodyPartUpperArms,
    BodyPart.upperLegs => l10n.bodyPartUpperLegs,
    BodyPart.waist => l10n.bodyPartWaist,
  };

  static String muscle(AppLocalizations l10n, Muscle value) => switch (value) {
    Muscle.chest => l10n.muscleChest,
    Muscle.delts => l10n.muscleDelts,
    Muscle.frontDelts => l10n.muscleFrontDelts,
    Muscle.sideDelts => l10n.muscleSideDelts,
    Muscle.rearDelts => l10n.muscleRearDelts,
    Muscle.lats => l10n.muscleLats,
    Muscle.upperBack => l10n.muscleUpperBack,
    Muscle.traps => l10n.muscleTraps,
    Muscle.biceps => l10n.muscleBiceps,
    Muscle.triceps => l10n.muscleTriceps,
    Muscle.forearms => l10n.muscleForearms,
    Muscle.quads => l10n.muscleQuads,
    Muscle.hamstrings => l10n.muscleHamstrings,
    Muscle.glutes => l10n.muscleGlutes,
    Muscle.calves => l10n.muscleCalves,
    Muscle.abs => l10n.muscleAbs,
    Muscle.obliques => l10n.muscleObliques,
    Muscle.lowerBack => l10n.muscleLowerBack,
    Muscle.hipFlexors => l10n.muscleHipFlexors,
    Muscle.adductors => l10n.muscleAdductors,
    Muscle.abductors => l10n.muscleAbductors,
    Muscle.core => l10n.muscleCore,
    Muscle.neck => l10n.muscleNeck,
    Muscle.other => l10n.muscleOther,
  };

  static String equipment(AppLocalizations l10n, Equipment value) => switch (value) {
    Equipment.barbell => l10n.equipmentBarbell,
    Equipment.ezBarbell => l10n.equipmentEzBarbell,
    Equipment.olympicBarbell => l10n.equipmentOlympicBarbell,
    Equipment.trapBar => l10n.equipmentTrapBar,
    Equipment.dumbbell => l10n.equipmentDumbbell,
    Equipment.kettlebell => l10n.equipmentKettlebell,
    Equipment.cable => l10n.equipmentCable,
    Equipment.leverageMachine => l10n.equipmentLeverageMachine,
    Equipment.smithMachine => l10n.equipmentSmithMachine,
    Equipment.sledMachine => l10n.equipmentSledMachine,
    Equipment.band => l10n.equipmentBand,
    Equipment.medicineBall => l10n.equipmentMedicineBall,
    Equipment.bodyWeight => l10n.equipmentBodyWeight,
    Equipment.weighted => l10n.equipmentWeighted,
    Equipment.assisted => l10n.equipmentAssisted,
    Equipment.other => l10n.equipmentOther,
  };

  static String loadModel(AppLocalizations l10n, LoadModel value) => switch (value) {
    LoadModel.externalLoad => l10n.loadModelExternal,
    LoadModel.bodyweight => l10n.loadModelBodyweight,
    LoadModel.bodyweightPlusLoad => l10n.loadModelBodyweightPlusLoad,
    LoadModel.assisted => l10n.loadModelAssisted,
  };
}
