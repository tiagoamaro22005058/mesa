import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesa/domain/models/program.dart';
import 'package:mesa/domain/models/week_role.dart';

/// Maps `users/{uid}/programs/{programId}` (§4) to and from [Program].
///
/// Kept out of the repository so it can be unit-tested as a pure function over
/// maps, with no Firestore instance in sight (§11).
///
/// Tolerant on read, like every other converter here: the rules authenticate
/// but do not validate (§4.3), so a client bug could write any shape, and a
/// program that refuses to parse would take the whole builder down with it.
abstract final class ProgramConverter {
  static Program fromMap(String id, Map<String, dynamic> data) {
    return Program(
      id: id,
      name: _string(data['name']) ?? '',
      goal: _string(data['goal']),
      // An unrecognised status reads as a draft rather than as active. Guessing
      // "active" would give the user two active programs, which is the one
      // thing F3 says cannot happen.
      status: ProgramStatus.tryFromWire(data['status']) ?? ProgramStatus.draft,
      weekRoles: _weekRoles(data['weekRoles']),
      currentMesocycle: _int(data['currentMesocycle']) ?? 1,
      currentWeekIndex: _int(data['currentWeekIndex']) ?? 0,
      daysPerWeek: _int(data['daysPerWeek']) ?? Program.defaultDaysPerWeek,
      createdAt: _dateTime(data['createdAt']) ?? _epoch,
      updatedAt: _dateTime(data['updatedAt']) ?? _epoch,
    );
  }

  static Map<String, dynamic> toMap(Program program) {
    return <String, dynamic>{
      'name': program.name,
      'goal': program.goal,
      'status': program.status.wireValue,
      'weekRoles': [
        for (final role in program.weekRoles)
          <String, dynamic>{
            'role': role.role.wireValue,
            'rpeTarget': role.rpeTarget,
            'volumeMultiplier': role.volumeMultiplier,
          },
      ],
      'currentMesocycle': program.currentMesocycle,
      'currentWeekIndex': program.currentWeekIndex,
      'daysPerWeek': program.daysPerWeek,
      // Client clocks, not FieldValue.serverTimestamp(). A server timestamp
      // reads back as null from the offline cache until it syncs, which would
      // show an empty "last updated" to a user with no signal — against NFR1.
      'createdAt': Timestamp.fromDate(program.createdAt),
      'updatedAt': Timestamp.fromDate(program.updatedAt),
    };
  }

  /// An entry whose role is unrecognised is **dropped, not defaulted**.
  ///
  /// The rest of this file substitutes a default for anything malformed, and
  /// here that would be wrong: a week silently renamed to `base` keeps its
  /// position in the mesocycle and prescribes the wrong RPE for it, which is
  /// invisible. A missing week is at least visible in the list.
  ///
  /// An empty or absent list falls back to §4's defaults rather than leaving a
  /// program with no mesocycle at all.
  static List<WeekRole> _weekRoles(Object? value) {
    if (value is! List) return WeekRole.defaults;

    final roles = <WeekRole>[];
    for (final entry in value) {
      if (entry is! Map) continue;
      final kind = WeekRoleKind.tryFromWire(entry['role']);
      if (kind == null) continue;

      roles.add(
        WeekRole(
          role: kind,
          rpeTarget: _double(entry['rpeTarget']) ?? 7,
          volumeMultiplier: _double(entry['volumeMultiplier']) ?? 1,
        ),
      );
    }

    return roles.isEmpty ? WeekRole.defaults : roles;
  }

  static final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  static String? _string(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return value;
  }

  /// Firestore hands back `int` for whole numbers written as doubles, so every
  /// numeric read has to widen rather than cast.
  static double? _double(Object? value) => value is num ? value.toDouble() : null;

  static int? _int(Object? value) => value is num ? value.toInt() : null;

  static DateTime? _dateTime(Object? value) =>
      value is Timestamp ? value.toDate().toUtc() : null;
}
