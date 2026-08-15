import 'package:collection/collection.dart';
import 'package:mesa/domain/models/body_part.dart';
import 'package:mesa/domain/models/equipment.dart';
import 'package:mesa/domain/models/load_model.dart';
import 'package:mesa/domain/models/muscle.dart';

/// Marks an [Exercise.copyWith] argument as "not supplied", so a nullable field
/// can be cleared rather than only replaced. Same sentinel, same reason, as
/// `UserProfile`.
const Object _unset = Object();

/// Where an exercise came from.
///
/// §5.5's model has no such field, but §4 stores `source: 'custom'` and F2
/// needs user-created exercises to appear inline in search results, visually
/// marked. One merged list beats a parallel type, so §3's `CustomExercise` is
/// an [Exercise] whose source is [ExerciseSource.custom] rather than a class of
/// its own.
enum ExerciseSource {
  catalogue('catalogue'),
  custom('custom');

  const ExerciseSource(this.wireValue);

  final String wireValue;

  static ExerciseSource? tryFromWire(Object? value) => _byWire[value];

  static final Map<Object?, ExerciseSource> _byWire = {
    for (final source in ExerciseSource.values) source.wireValue: source,
  };
}

/// A catalogue entry (§5.5).
///
/// Either one of the 1,295 bundled exercises or one the user created; [source]
/// says which. Immutable, no Firebase types, and hand-written `copyWith` /
/// `==` / `hashCode` per §2.
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.primaryMuscle,
    required this.equipment,
    required this.loadModel,
    this.aliases = const [],
    this.synergist,
    this.secondaryMuscles = const [],
    this.steps = const [],
    this.thumbnailUrl,
    this.gifUrl,
    this.attribution,
    this.source = ExerciseSource.catalogue,
  });

  /// The upstream id, e.g. `0001`. Used verbatim — §5.3 warns against slugging
  /// the name, because six names are duplicated.
  final String id;

  /// Lowercase, as upstream writes it. Title-cased at render, not here (§5.3).
  final String name;

  /// Hand-maintained, and the only way Portuguese search finds anything — the
  /// dataset ships ten languages and Portuguese is not one of them (§5.4).
  final List<String> aliases;

  final BodyPart bodyPart;

  /// Upstream's `target`, which is the real primary-muscle field.
  final Muscle primaryMuscle;

  /// Upstream's `muscle_group`, which is misleadingly named there — it is a
  /// synergist, not the primary (§5.3).
  final Muscle? synergist;

  /// Never contains [primaryMuscle]: after synonym collapse a record could
  /// carry the same muscle twice, which would double-count it in M6's volume.
  final List<Muscle> secondaryMuscles;

  final Equipment equipment;

  /// Derived from [equipment] at ingestion (§5.6), not present upstream.
  final LoadModel loadModel;

  final List<String> steps;

  /// Absolute once loaded — the asset stores a path relative to the pinned
  /// upstream commit and the catalogue loader resolves it (§5.1).
  final String? thumbnailUrl;
  final String? gifUrl;

  /// © Gym visual. Must be displayed wherever the media is (§5.1). `null` for
  /// user-created exercises, which have no media and nothing to attribute.
  final String? attribution;

  final ExerciseSource source;

  bool get isCustom => source == ExerciseSource.custom;

  static const ListEquality<Object?> _list = ListEquality<Object?>();

  /// Pass a nullable field explicitly — including as `null` — to change it;
  /// omit it to leave it alone.
  Exercise copyWith({
    String? id,
    String? name,
    List<String>? aliases,
    BodyPart? bodyPart,
    Muscle? primaryMuscle,
    Object? synergist = _unset,
    List<Muscle>? secondaryMuscles,
    Equipment? equipment,
    LoadModel? loadModel,
    List<String>? steps,
    Object? thumbnailUrl = _unset,
    Object? gifUrl = _unset,
    Object? attribution = _unset,
    ExerciseSource? source,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      aliases: aliases ?? this.aliases,
      bodyPart: bodyPart ?? this.bodyPart,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      synergist: identical(synergist, _unset) ? this.synergist : synergist as Muscle?,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipment: equipment ?? this.equipment,
      loadModel: loadModel ?? this.loadModel,
      steps: steps ?? this.steps,
      thumbnailUrl: identical(thumbnailUrl, _unset) ? this.thumbnailUrl : thumbnailUrl as String?,
      gifUrl: identical(gifUrl, _unset) ? this.gifUrl : gifUrl as String?,
      attribution: identical(attribution, _unset) ? this.attribution : attribution as String?,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Exercise &&
      other.id == id &&
      other.name == name &&
      // By value, not identity — an exercise decoded twice from the same JSON
      // holds different list objects with the same contents.
      _list.equals(other.aliases, aliases) &&
      other.bodyPart == bodyPart &&
      other.primaryMuscle == primaryMuscle &&
      other.synergist == synergist &&
      _list.equals(other.secondaryMuscles, secondaryMuscles) &&
      other.equipment == equipment &&
      other.loadModel == loadModel &&
      _list.equals(other.steps, steps) &&
      other.thumbnailUrl == thumbnailUrl &&
      other.gifUrl == gifUrl &&
      other.attribution == attribution &&
      other.source == source;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    _list.hash(aliases),
    bodyPart,
    primaryMuscle,
    synergist,
    _list.hash(secondaryMuscles),
    equipment,
    loadModel,
    _list.hash(steps),
    thumbnailUrl,
    gifUrl,
    attribution,
    source,
  );

  @override
  String toString() =>
      'Exercise(${source.wireValue} $id: $name, ${bodyPart.wireValue}, '
      '${primaryMuscle.wireValue}, ${equipment.wireValue}, ${loadModel.wireValue})';
}
