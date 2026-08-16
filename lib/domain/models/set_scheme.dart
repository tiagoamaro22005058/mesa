/// What a [Block] prescribes: how many sets, of how many reps, how hard, and
/// how long to rest between them (§3, §4).
class SetScheme {
  const SetScheme({
    this.sets = defaultSets,
    this.repMin = defaultRepMin,
    this.repMax = defaultRepMax,
    this.rpeTarget = defaultRpeTarget,
    this.restSec = defaultRestSec,
  });

  final int sets;

  /// The bottom and top of the rep range. `repMin == repMax` is a fixed rep
  /// count, which is a normal prescription rather than a degenerate one.
  final int repMin;
  final int repMax;

  /// The baseline RPE for this block, independent of which week it falls in.
  ///
  /// **Not the only RPE in play, and §7.2 does not yet say how the two combine.**
  /// `WeekRole.rpeTarget` is the other, and reading it as a straight replacement
  /// would put an isolation block prescribed at 8 up at 9.5 in a peak week —
  /// which loses the gap between compound and isolation work on purpose. §12
  /// carries this as a question §7.2 must answer before M5; M3 only stores both.
  final double rpeTarget;

  final int restSec;

  /// §4's own example, used as the starting point for a new block.
  static const int defaultSets = 4;
  static const int defaultRepMin = 6;
  static const int defaultRepMax = 8;
  static const double defaultRpeTarget = 8;
  static const int defaultRestSec = 150;

  SetScheme copyWith({
    int? sets,
    int? repMin,
    int? repMax,
    double? rpeTarget,
    int? restSec,
  }) {
    return SetScheme(
      sets: sets ?? this.sets,
      repMin: repMin ?? this.repMin,
      repMax: repMax ?? this.repMax,
      rpeTarget: rpeTarget ?? this.rpeTarget,
      restSec: restSec ?? this.restSec,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SetScheme &&
      other.sets == sets &&
      other.repMin == repMin &&
      other.repMax == repMax &&
      other.rpeTarget == rpeTarget &&
      other.restSec == restSec;

  @override
  int get hashCode => Object.hash(sets, repMin, repMax, rpeTarget, restSec);

  @override
  String toString() =>
      'SetScheme($sets × $repMin-$repMax @ RPE $rpeTarget, rest ${restSec}s)';
}
