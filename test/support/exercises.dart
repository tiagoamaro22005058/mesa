import 'package:mesa/domain/models/body_part.dart';
import 'package:mesa/domain/models/equipment.dart';
import 'package:mesa/domain/models/exercise.dart';
import 'package:mesa/domain/models/load_model.dart';
import 'package:mesa/domain/models/muscle.dart';

/// One exercise, with everything the test does not care about filled in.
///
/// Keeps the tests readable: a search test says what the name and aliases are
/// and stays silent about body parts.
Exercise exercise(
  String id,
  String name, {
  List<String> aliases = const [],
  BodyPart bodyPart = BodyPart.chest,
  Muscle primaryMuscle = Muscle.chest,
  Muscle? synergist,
  List<Muscle> secondaryMuscles = const [],
  Equipment equipment = Equipment.barbell,
  LoadModel? loadModel,
  List<String> steps = const ['Do the thing.'],
  String? thumbnailUrl,
  String? gifUrl,
  String? attribution = '© Gym visual — https://gymvisual.com/',
  ExerciseSource source = ExerciseSource.catalogue,
}) {
  return Exercise(
    id: id,
    name: name,
    aliases: aliases,
    bodyPart: bodyPart,
    primaryMuscle: primaryMuscle,
    synergist: synergist,
    secondaryMuscles: secondaryMuscles,
    equipment: equipment,
    loadModel: loadModel ?? equipment.defaultLoadModel,
    steps: steps,
    thumbnailUrl: thumbnailUrl,
    gifUrl: gifUrl,
    attribution: source == ExerciseSource.custom ? null : attribution,
    source: source,
  );
}

/// A user-created exercise (F2).
Exercise customExercise(
  String id,
  String name, {
  BodyPart bodyPart = BodyPart.chest,
  Muscle primaryMuscle = Muscle.chest,
  Equipment equipment = Equipment.barbell,
  List<String> steps = const [],
}) {
  return exercise(
    id,
    name,
    bodyPart: bodyPart,
    primaryMuscle: primaryMuscle,
    equipment: equipment,
    steps: steps,
    source: ExerciseSource.custom,
  );
}
