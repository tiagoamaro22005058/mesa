/// The canonical muscle vocabulary (§5.4).
///
/// The upstream dataset carries 49 distinct muscle strings across three fields,
/// with synonym pairs (`traps`/`trapezius`, `quads`/`quadriceps`) that would
/// silently split every per-muscle total if they reached the app. Ingestion
/// collapses all of them onto this enum through one mapping table, and any
/// value absent from that table fails the build rather than passing through.
///
/// Two members exist that §5.4's original list did not have (M2):
///
/// - [delts] — the dataset never distinguishes the three deltoid heads, so
///   [frontDelts] and [sideDelts] are produced by nothing in the mapping table.
///   They arrive only through `tools/build_catalog/delt_heads.json`, a
///   hand-maintained per-exercise override, which is what lets M6 answer "is my
///   side delt volume enough" for the exercises that have been classified.
///   [rearDelts] is the exception: upstream does say `rear deltoids`, and the
///   rotator-cuff exercises map here too.
/// - [other] — the long tail with no honest home (ankles, feet, shins,
///   serratus anterior). One visibly-unclassified bucket beats six muscles
///   filed under near neighbours.
enum Muscle {
  chest('chest'),
  delts('delts'),
  frontDelts('front_delts'),
  sideDelts('side_delts'),
  rearDelts('rear_delts'),
  lats('lats'),
  upperBack('upper_back'),
  traps('traps'),
  biceps('biceps'),
  triceps('triceps'),
  forearms('forearms'),
  quads('quads'),
  hamstrings('hamstrings'),
  glutes('glutes'),
  calves('calves'),
  abs('abs'),
  obliques('obliques'),
  lowerBack('lower_back'),
  hipFlexors('hip_flexors'),
  adductors('adductors'),
  abductors('abductors'),
  core('core'),
  neck('neck'),
  other('other');

  const Muscle(this.wireValue);

  /// The value in the catalogue asset and in Firestore. Fixed by §5.4 — never
  /// derived from [name], so renaming a member cannot rewrite stored data.
  final String wireValue;

  /// Reads a stored value, or `null` if it is not one of ours.
  ///
  /// Nullable rather than defaulting, unlike [UnitSystem.fromWire]: an
  /// unrecognised muscle means either a corrupt asset or a mapping table that
  /// got ahead of this enum, and quietly substituting a default would hide
  /// both. Callers decide — the catalogue treats it as a failure, a custom
  /// exercise read back from Firestore falls back to [Muscle.other] rather than
  /// locking the user out of their own data.
  static Muscle? tryFromWire(Object? value) => _byWire[value];

  static final Map<Object?, Muscle> _byWire = {
    for (final muscle in Muscle.values) muscle.wireValue: muscle,
  };
}
