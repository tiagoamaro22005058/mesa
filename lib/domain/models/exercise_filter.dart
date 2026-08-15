import 'package:mesa/domain/models/body_part.dart';
import 'package:mesa/domain/models/equipment.dart';
import 'package:mesa/domain/models/muscle.dart';

/// Marks an [ExerciseFilter.copyWith] argument as "not supplied", so a filter
/// can be cleared rather than only replaced.
const Object _unset = Object();

/// What the catalogue list is currently narrowed to (F2).
///
/// All four narrow independently and combine with AND. A null field is "no
/// constraint" rather than a wildcard match, which is the difference between
/// clearing a chip and selecting every value on it.
class ExerciseFilter {
  const ExerciseFilter({
    this.bodyPart,
    this.primaryMuscle,
    this.equipment,
    this.favouritesOnly = false,
  });

  static const ExerciseFilter none = ExerciseFilter();

  final BodyPart? bodyPart;
  final Muscle? primaryMuscle;
  final Equipment? equipment;
  final bool favouritesOnly;

  bool get isEmpty =>
      bodyPart == null && primaryMuscle == null && equipment == null && !favouritesOnly;

  /// How many chips are lit, for the badge on the filter button.
  int get activeCount => [
    bodyPart != null,
    primaryMuscle != null,
    equipment != null,
    favouritesOnly,
  ].where((active) => active).length;

  ExerciseFilter copyWith({
    Object? bodyPart = _unset,
    Object? primaryMuscle = _unset,
    Object? equipment = _unset,
    bool? favouritesOnly,
  }) {
    return ExerciseFilter(
      bodyPart: identical(bodyPart, _unset) ? this.bodyPart : bodyPart as BodyPart?,
      primaryMuscle:
          identical(primaryMuscle, _unset) ? this.primaryMuscle : primaryMuscle as Muscle?,
      equipment: identical(equipment, _unset) ? this.equipment : equipment as Equipment?,
      favouritesOnly: favouritesOnly ?? this.favouritesOnly,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ExerciseFilter &&
      other.bodyPart == bodyPart &&
      other.primaryMuscle == primaryMuscle &&
      other.equipment == equipment &&
      other.favouritesOnly == favouritesOnly;

  @override
  int get hashCode => Object.hash(bodyPart, primaryMuscle, equipment, favouritesOnly);

  @override
  String toString() =>
      'ExerciseFilter(bodyPart: ${bodyPart?.wireValue}, muscle: ${primaryMuscle?.wireValue}, '
      'equipment: ${equipment?.wireValue}, favouritesOnly: $favouritesOnly)';
}
