import 'package:mesa/domain/models/body_part.dart';
import 'package:mesa/domain/models/equipment.dart';
import 'package:mesa/domain/models/exercise.dart';
import 'package:mesa/domain/models/muscle.dart';

/// Maps `users/{uid}/customExercises/{exerciseId}` (§4) to and from [Exercise].
///
/// **Tolerant, unlike the catalogue converter.** The security rules
/// authenticate but do not validate (§4.3), so a client bug could write any
/// shape into this collection — and an exercise that refuses to parse would
/// take a program's blocks down with it in M3. Anything unrecognised falls back
/// to a visible default rather than throwing:
///
/// - an unknown muscle becomes [Muscle.other], which reads as "unclassified"
///   rather than as a wrong muscle;
/// - unknown equipment becomes [Equipment.other], and the load model is then
///   derived from it rather than trusted, so a corrupt `loadModel` cannot make
///   the progression maths in M5 compute against the wrong model.
abstract final class CustomExerciseConverter {
  static Exercise fromMap(String id, Map<String, dynamic> data) {
    final equipment = Equipment.tryFromWire(data['equipment']) ?? Equipment.other;

    return Exercise(
      id: id,
      name: (data['name'] as String?) ?? '',
      aliases: _strings(data['aliases']),
      bodyPart: BodyPart.tryFromWire(data['bodyPart']) ?? BodyPart.waist,
      primaryMuscle: Muscle.tryFromWire(data['primaryMuscle']) ?? Muscle.other,
      synergist: Muscle.tryFromWire(data['synergist']),
      secondaryMuscles: [
        for (final muscle in _strings(data['secondaryMuscles']))
          Muscle.tryFromWire(muscle) ?? Muscle.other,
      ],
      equipment: equipment,
      // Derived, never read back. §5.6 makes the load model the thing the
      // progression maths turns on, and it is a function of equipment — storing
      // it separately only creates a way for the two to disagree.
      loadModel: equipment.defaultLoadModel,
      steps: _strings(data['steps']),
      // No media and nothing to attribute: §5.1 covers Gym visual's images, and
      // a user-created exercise has none.
      source: ExerciseSource.custom,
    );
  }

  static Map<String, dynamic> toMap(Exercise exercise) {
    return <String, dynamic>{
      'name': exercise.name,
      'aliases': exercise.aliases,
      'bodyPart': exercise.bodyPart.wireValue,
      'primaryMuscle': exercise.primaryMuscle.wireValue,
      'synergist': exercise.synergist?.wireValue,
      'secondaryMuscles': [for (final m in exercise.secondaryMuscles) m.wireValue],
      'equipment': exercise.equipment.wireValue,
      'steps': exercise.steps,
      // §4 stores this, and it is what tells a custom exercise apart from a
      // catalogue one in a program block written in M3.
      'source': ExerciseSource.custom.wireValue,
    };
  }

  static List<String> _strings(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is String) item,
    ];
  }
}
