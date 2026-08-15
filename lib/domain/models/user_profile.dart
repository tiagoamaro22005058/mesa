import 'package:collection/collection.dart';
import 'package:mesa/domain/models/unit_system.dart';

/// Marks a [UserProfile.copyWith] argument as "not supplied".
///
/// A plain `String?` parameter cannot tell "leave this alone" apart from "set
/// this to null", which is how an optional field quietly becomes impossible to
/// clear. Archiving a program has to be able to unset `activeProgramId`.
const Object _unset = Object();

/// The `users/{uid}` document (§4).
///
/// `bodyweight` and its dated log are §4 fields but arrive in M5, with the
/// `bodyweightPlusLoad` maths that consumes them (§5.6, §7.2). M1 has no use
/// for them and does not build ahead.
class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.createdAt,
    required this.updatedAt,
    this.units = UnitSystem.kg,
    this.barWeight = defaultBarWeight,
    this.plateInventory = defaultPlateInventory,
    this.dumbbellIncrement = defaultDumbbellIncrement,
    this.favouriteExerciseIds = const [],
    this.activeProgramId,
    this.activeGymId,
  });

  final String displayName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UnitSystem units;
  final double barWeight;
  final List<double> plateInventory;
  final double dumbbellIncrement;

  /// Catalogue and custom exercise ids the user starred (F2).
  ///
  /// On the profile rather than in a subcollection (M2): the document is
  /// already streamed for every other setting, so favourites cost no extra
  /// read and no extra listener (NFR2), and the list will never exceed a few
  /// dozen ids. §4 did not define anywhere for these to live; this is that
  /// amendment.
  final List<String> favouriteExerciseIds;

  final String? activeProgramId;
  final String? activeGymId;

  /// §4's defaults, verbatim. A standard Olympic bar and a commercial-gym
  /// plate set in kilograms.
  static const double defaultBarWeight = 20;
  static const List<double> defaultPlateInventory = [25, 20, 15, 10, 5, 2.5, 1.25];
  static const double defaultDumbbellIncrement = 2;

  static const ListEquality<double> _weights = ListEquality<double>();
  static const ListEquality<String> _ids = ListEquality<String>();

  bool isFavourite(String exerciseId) => favouriteExerciseIds.contains(exerciseId);

  /// Adds or removes [exerciseId], returning the updated profile.
  ///
  /// Order is preserved and newest goes last, so the favourites filter reads in
  /// the order they were starred rather than reshuffling on every toggle.
  UserProfile toggleFavourite(String exerciseId) {
    final updated = [...favouriteExerciseIds];
    if (!updated.remove(exerciseId)) updated.add(exerciseId);
    return copyWith(favouriteExerciseIds: updated);
  }

  /// Pass a nullable field explicitly — including as `null` — to change it;
  /// omit it to leave it as it is.
  UserProfile copyWith({
    String? displayName,
    DateTime? createdAt,
    DateTime? updatedAt,
    UnitSystem? units,
    double? barWeight,
    List<double>? plateInventory,
    double? dumbbellIncrement,
    List<String>? favouriteExerciseIds,
    Object? activeProgramId = _unset,
    Object? activeGymId = _unset,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      units: units ?? this.units,
      barWeight: barWeight ?? this.barWeight,
      plateInventory: plateInventory ?? this.plateInventory,
      dumbbellIncrement: dumbbellIncrement ?? this.dumbbellIncrement,
      favouriteExerciseIds: favouriteExerciseIds ?? this.favouriteExerciseIds,
      activeProgramId: identical(activeProgramId, _unset)
          ? this.activeProgramId
          : activeProgramId as String?,
      activeGymId: identical(activeGymId, _unset)
          ? this.activeGymId
          : activeGymId as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.displayName == displayName &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.units == units &&
      other.barWeight == barWeight &&
      // By value, not by identity — a profile read back from Firestore is a
      // different list object with the same plates in it.
      _weights.equals(other.plateInventory, plateInventory) &&
      other.dumbbellIncrement == dumbbellIncrement &&
      _ids.equals(other.favouriteExerciseIds, favouriteExerciseIds) &&
      other.activeProgramId == activeProgramId &&
      other.activeGymId == activeGymId;

  @override
  int get hashCode => Object.hash(
    displayName,
    createdAt,
    updatedAt,
    units,
    barWeight,
    _weights.hash(plateInventory),
    dumbbellIncrement,
    _ids.hash(favouriteExerciseIds),
    activeProgramId,
    activeGymId,
  );

  @override
  String toString() =>
      'UserProfile(displayName: $displayName, units: ${units.wireValue}, '
      'barWeight: $barWeight, plateInventory: $plateInventory, '
      'dumbbellIncrement: $dumbbellIncrement, '
      'activeProgramId: $activeProgramId, activeGymId: $activeGymId)';
}
