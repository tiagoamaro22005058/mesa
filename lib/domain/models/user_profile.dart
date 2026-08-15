import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mesa/domain/models/unit_system.dart';

part 'user_profile.freezed.dart';

/// The `users/{uid}` document (§4).
///
/// `bodyweight` is deliberately absent. §5.6 needs one for the ~36
/// `bodyweightPlusLoad` exercises, but §4 does not list it and open question 5
/// has not settled whether it should be a single value or a dated series.
/// It is added in M5, when the answer actually matters.
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String displayName,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(UnitSystem.kg) UnitSystem units,
    @Default(UserProfile.defaultBarWeight) double barWeight,
    @Default(UserProfile.defaultPlateInventory) List<double> plateInventory,
    @Default(UserProfile.defaultDumbbellIncrement) double dumbbellIncrement,
    String? activeProgramId,
    String? activeGymId,
  }) = _UserProfile;

  /// §4's defaults, verbatim. A standard Olympic bar and a commercial-gym
  /// plate set in kilograms.
  static const double defaultBarWeight = 20;
  static const List<double> defaultPlateInventory = [25, 20, 15, 10, 5, 2.5, 1.25];
  static const double defaultDumbbellIncrement = 2;
}
