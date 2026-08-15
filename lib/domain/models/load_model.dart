/// How an exercise is loaded (§5.6).
///
/// Absent upstream and derived from equipment at ingestion. The progression
/// maths in §7 depends on this entirely: [assisted] moves *inverse* to
/// progress, and [bodyweightPlusLoad] needs the bodyweight in force when the
/// set was performed. §5.6 names those two the most likely sources of silently
/// wrong numbers in the app.
///
/// Nothing in M2 computes with this — it is carried so M5 has it. The names are
/// §5.6's, verbatim.
enum LoadModel {
  /// Weight entered directly. Standard e1RM.
  externalLoad('externalLoad'),

  /// No weight field at all. Progress is reps at a target RPE.
  bodyweight('bodyweight'),

  /// Total load is bodyweight plus the added weight.
  bodyweightPlusLoad('bodyweightPlusLoad'),

  /// The load *is* assistance, so less of it is an improvement. Every
  /// comparison inverts.
  assisted('assisted');

  const LoadModel(this.wireValue);

  final String wireValue;

  static LoadModel? tryFromWire(Object? value) => _byWire[value];

  static final Map<Object?, LoadModel> _byWire = {
    for (final model in LoadModel.values) model.wireValue: model,
  };
}
