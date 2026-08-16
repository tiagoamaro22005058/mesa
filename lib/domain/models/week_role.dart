/// Which week of a mesocycle a [WeekRole] is (§3).
///
/// The four names §3's glossary fixes. The wire value is the spec's, never
/// derived from `name`, so renaming a member cannot rewrite stored data.
enum WeekRoleKind {
  base('base'),
  intensification('intensification'),
  peak('peak'),
  deload('deload');

  const WeekRoleKind(this.wireValue);

  final String wireValue;

  static WeekRoleKind? tryFromWire(Object? value) => _byWire[value];

  static final Map<Object?, WeekRoleKind> _byWire = {
    for (final kind in WeekRoleKind.values) kind.wireValue: kind,
  };
}

/// One week of a [Program]'s mesocycle: what it is called, how hard it is, and
/// how much of the prescribed volume it keeps (§3, §4).
///
/// A2 makes the roles and their order **user-configurable**, which is why this
/// is a value class in an ordered list rather than data hung off [WeekRoleKind].
/// Two entries may share a [role] — a mesocycle with two base weeks is a
/// perfectly ordinary one — so a week's identity is its position in
/// `Program.weekRoles`, not its name.
class WeekRole {
  const WeekRole({
    required this.role,
    required this.rpeTarget,
    required this.volumeMultiplier,
  });

  final WeekRoleKind role;

  /// The RPE this week's sets aim for. Consumed by §7.2 in M5.
  final double rpeTarget;

  /// What fraction of each block's prescribed sets this week keeps. §7.2
  /// rounds the product down, minimum 1, which is how a deload drops a 4-set
  /// block to 2.
  final double volumeMultiplier;

  /// §4's sample mesocycle, verbatim: build, intensify, peak, then recover.
  ///
  /// §3's glossary and §12's first open question both wrote these in a
  /// different order (Base / Deload / Intensification / Peak). §4's is the one
  /// that ships, confirmed by the owner in M3 — a deload in week two would
  /// interrupt the build rather than recover from it. §3 was corrected to
  /// match; the roles stay user-configurable either way (A2).
  static const List<WeekRole> defaults = [
    WeekRole(role: WeekRoleKind.base, rpeTarget: 7, volumeMultiplier: 1),
    WeekRole(role: WeekRoleKind.intensification, rpeTarget: 8.5, volumeMultiplier: 1),
    WeekRole(role: WeekRoleKind.peak, rpeTarget: 9.5, volumeMultiplier: 0.9),
    WeekRole(role: WeekRoleKind.deload, rpeTarget: 5.5, volumeMultiplier: 0.5),
  ];

  WeekRole copyWith({
    WeekRoleKind? role,
    double? rpeTarget,
    double? volumeMultiplier,
  }) {
    return WeekRole(
      role: role ?? this.role,
      rpeTarget: rpeTarget ?? this.rpeTarget,
      volumeMultiplier: volumeMultiplier ?? this.volumeMultiplier,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is WeekRole &&
      other.role == role &&
      other.rpeTarget == rpeTarget &&
      other.volumeMultiplier == volumeMultiplier;

  @override
  int get hashCode => Object.hash(role, rpeTarget, volumeMultiplier);

  @override
  String toString() =>
      'WeekRole(${role.wireValue}, rpe: $rpeTarget, volume: $volumeMultiplier)';
}
