import 'package:collection/collection.dart';
import 'package:mesa/domain/models/set_scheme.dart';

/// Marks a [Block.copyWith] argument as "not supplied", so a nullable field can
/// be cleared rather than only replaced. Same sentinel, same reason, as
/// `UserProfile`.
const Object _unset = Object();

/// One exercise slot in a [Day]: an exercise, what it prescribes, and the
/// alternatives to reach for when the gym cannot supply it (§3, §4).
///
/// **Carries no `order` field, deliberately.** §4's document shape has one and
/// the converter still writes it, but position in `Day.blocks` is what the app
/// reads — storing the sequence twice only creates a way for the array and the
/// field to disagree, and the one that renders would win silently. This is the
/// same reasoning §5.5 used to keep the gym tag off `Exercise`.
class Block {
  const Block({
    required this.blockId,
    required this.exerciseId,
    this.setScheme = const SetScheme(),
    this.isCustom = false,
    this.alternativeExerciseIds = const [],
    this.notes,
  });

  /// Identifies the block within its day. Blocks live in an array rather than
  /// their own documents (§4.1), so they need an id of their own — M4's
  /// `SetLog.blockId` points back at it.
  final String blockId;

  /// A catalogue id (`0043`) or a custom exercise's, per [isCustom].
  final String exerciseId;

  /// Whether [exerciseId] resolves against `users/{uid}/customExercises`
  /// rather than the bundled catalogue.
  ///
  /// Derived from the picked exercise and never typed by the user. Not merely
  /// redundant with a merged catalogue lookup: when a custom exercise has been
  /// deleted, this is what tells "yours, and gone" apart from "not a catalogue
  /// id", which are different things to say. It also lets a day document be
  /// read without loading the catalogue first.
  final bool isCustom;

  final SetScheme setScheme;

  /// Substitutes in the user's own order of preference (F3).
  ///
  /// §F7 will also *compute* suggestions, in M7 — this list is the manual one,
  /// which §F7 says always outranks it.
  final List<String> alternativeExerciseIds;

  final String? notes;

  static const ListEquality<String> _ids = ListEquality<String>();

  /// Pass a nullable field explicitly — including as `null` — to change it;
  /// omit it to leave it alone.
  Block copyWith({
    String? blockId,
    String? exerciseId,
    bool? isCustom,
    SetScheme? setScheme,
    List<String>? alternativeExerciseIds,
    Object? notes = _unset,
  }) {
    return Block(
      blockId: blockId ?? this.blockId,
      exerciseId: exerciseId ?? this.exerciseId,
      isCustom: isCustom ?? this.isCustom,
      setScheme: setScheme ?? this.setScheme,
      alternativeExerciseIds: alternativeExerciseIds ?? this.alternativeExerciseIds,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Block &&
      other.blockId == blockId &&
      other.exerciseId == exerciseId &&
      other.isCustom == isCustom &&
      other.setScheme == setScheme &&
      // By value, not identity — a block read back from Firestore holds a
      // different list object with the same ids in it.
      _ids.equals(other.alternativeExerciseIds, alternativeExerciseIds) &&
      other.notes == notes;

  @override
  int get hashCode => Object.hash(
    blockId,
    exerciseId,
    isCustom,
    setScheme,
    _ids.hash(alternativeExerciseIds),
    notes,
  );

  @override
  String toString() =>
      'Block($blockId: $exerciseId${isCustom ? ' (custom)' : ''}, $setScheme)';
}
