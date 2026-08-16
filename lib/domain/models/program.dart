import 'package:collection/collection.dart';
import 'package:mesa/domain/models/week_role.dart';

/// Marks a [Program.copyWith] argument as "not supplied", so a nullable field
/// can be cleared rather than only replaced. Same sentinel, same reason, as
/// `UserProfile`.
const Object _unset = Object();

/// Where a program sits in its life (§4).
///
/// Exactly one program may be [active] at a time (F3). That invariant is held
/// by the repository, which writes the newly active program, the one it
/// displaces and the profile's `activeProgramId` in a single batch.
enum ProgramStatus {
  draft('draft'),
  active('active'),
  archived('archived');

  const ProgramStatus(this.wireValue);

  final String wireValue;

  static ProgramStatus? tryFromWire(Object? value) => _byWire[value];

  static final Map<Object?, ProgramStatus> _byWire = {
    for (final status in ProgramStatus.values) status.wireValue: status,
  };
}

/// A training plan: `users/{uid}/programs/{programId}` (§3, §4).
///
/// Owns the week roles and the mesocycle counters; its days are separate
/// documents in a subcollection, because a program is edited a day at a time
/// and a day is read as a unit (§4.1).
class Program {
  const Program({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.goal,
    this.status = ProgramStatus.draft,
    this.weekRoles = WeekRole.defaults,
    this.currentMesocycle = 1,
    this.currentWeekIndex = 0,
    this.daysPerWeek = defaultDaysPerWeek,
  });

  final String id;
  final String name;

  /// Free text — "hypertrophy", "strength", whatever the user writes. §4 gives
  /// it no vocabulary and nothing computes against it.
  final String? goal;

  final ProgramStatus status;

  /// One pass through these is a mesocycle (§3). Ordered, user-configurable,
  /// and free to repeat a role (A2).
  final List<WeekRole> weekRoles;

  /// Which mesocycle is being run, counted from one, and which week within it,
  /// counted from zero. Advanced by M4 on session completion; M3 only
  /// initialises them.
  final int currentMesocycle;
  final int currentWeekIndex;

  /// Training **sessions** per week, which is not the same as the number of
  /// [Day] templates: a Push/Pull/Legs split run twice over is three days and
  /// `daysPerWeek` 6.
  ///
  /// Set by the user and read by nothing in M3. It is stored for M4's
  /// scheduling, so nothing should assume it is already load-bearing.
  final int daysPerWeek;

  final DateTime createdAt;
  final DateTime updatedAt;

  static const int defaultDaysPerWeek = 3;

  bool get isActive => status == ProgramStatus.active;

  static const ListEquality<WeekRole> _roles = ListEquality<WeekRole>();

  /// Pass a nullable field explicitly — including as `null` — to change it;
  /// omit it to leave it alone.
  Program copyWith({
    String? id,
    String? name,
    Object? goal = _unset,
    ProgramStatus? status,
    List<WeekRole>? weekRoles,
    int? currentMesocycle,
    int? currentWeekIndex,
    int? daysPerWeek,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Program(
      id: id ?? this.id,
      name: name ?? this.name,
      goal: identical(goal, _unset) ? this.goal : goal as String?,
      status: status ?? this.status,
      weekRoles: weekRoles ?? this.weekRoles,
      currentMesocycle: currentMesocycle ?? this.currentMesocycle,
      currentWeekIndex: currentWeekIndex ?? this.currentWeekIndex,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Program &&
      other.id == id &&
      other.name == name &&
      other.goal == goal &&
      other.status == status &&
      // By value, not identity — a program read back from Firestore holds a
      // different list object with the same roles in it.
      _roles.equals(other.weekRoles, weekRoles) &&
      other.currentMesocycle == currentMesocycle &&
      other.currentWeekIndex == currentWeekIndex &&
      other.daysPerWeek == daysPerWeek &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    goal,
    status,
    _roles.hash(weekRoles),
    currentMesocycle,
    currentWeekIndex,
    daysPerWeek,
    createdAt,
    updatedAt,
  );

  @override
  String toString() =>
      'Program($id: $name, ${status.wireValue}, ${weekRoles.length} week roles, '
      'meso $currentMesocycle week $currentWeekIndex)';
}
