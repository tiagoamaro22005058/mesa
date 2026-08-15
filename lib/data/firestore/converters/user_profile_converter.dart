import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mesa/domain/models/unit_system.dart';
import 'package:mesa/domain/models/user_profile.dart';

/// Maps the `users/{uid}` document (§4) to and from [UserProfile].
///
/// Kept out of the repository so it can be unit-tested as a pure function over
/// maps, with no Firestore instance in sight (§11).
abstract final class UserProfileConverter {
  /// Reads a stored document, substituting §4's defaults for anything absent.
  ///
  /// Tolerant by design: the security rules permit any shape (§4.3 validates
  /// nothing), and a profile that fails to parse would lock the user out of
  /// their own app.
  static UserProfile fromMap(Map<String, dynamic> data) {
    return UserProfile(
      displayName: _string(data['displayName']) ?? '',
      units: UnitSystem.fromWire(data['units']),
      barWeight: _double(data['barWeight']) ?? UserProfile.defaultBarWeight,
      plateInventory:
          _doubleList(data['plateInventory']) ?? UserProfile.defaultPlateInventory,
      dumbbellIncrement:
          _double(data['dumbbellIncrement']) ?? UserProfile.defaultDumbbellIncrement,
      favouriteExerciseIds: _stringList(data['favouriteExerciseIds']) ?? const [],
      activeProgramId: _string(data['activeProgramId']),
      activeGymId: _string(data['activeGymId']),
      createdAt: _dateTime(data['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      updatedAt: _dateTime(data['updatedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  static Map<String, dynamic> toMap(UserProfile profile) {
    return <String, dynamic>{
      'displayName': profile.displayName,
      'units': profile.units.wireValue,
      'barWeight': profile.barWeight,
      'plateInventory': profile.plateInventory,
      'dumbbellIncrement': profile.dumbbellIncrement,
      'favouriteExerciseIds': profile.favouriteExerciseIds,
      'activeProgramId': profile.activeProgramId,
      'activeGymId': profile.activeGymId,
      // Client clocks, not FieldValue.serverTimestamp(). A server timestamp
      // reads back as null from the offline cache until it syncs, which would
      // show an empty "last updated" to a user with no signal — against NFR1.
      'createdAt': Timestamp.fromDate(profile.createdAt),
      'updatedAt': Timestamp.fromDate(profile.updatedAt),
    };
  }

  static String? _string(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return value;
  }

  /// Firestore hands back `int` for whole numbers written as doubles, so every
  /// numeric read has to widen rather than cast.
  static double? _double(Object? value) => value is num ? value.toDouble() : null;

  /// Drops anything that is not a string rather than rejecting the whole list:
  /// one malformed favourite should cost that favourite, not all of them.
  static List<String>? _stringList(Object? value) {
    if (value is! List) return null;
    return [
      for (final item in value)
        if (item is String && item.isNotEmpty) item,
    ];
  }

  static List<double>? _doubleList(Object? value) {
    if (value is! List) return null;
    final parsed = value.whereType<num>().map((n) => n.toDouble()).toList();
    return parsed.length == value.length ? parsed : null;
  }

  static DateTime? _dateTime(Object? value) =>
      value is Timestamp ? value.toDate().toUtc() : null;
}
