// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserProfile {

 String get displayName; DateTime get createdAt; DateTime get updatedAt; UnitSystem get units; double get barWeight; List<double> get plateInventory; double get dumbbellIncrement; String? get activeProgramId; String? get activeGymId;
/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProfileCopyWith<UserProfile> get copyWith => _$UserProfileCopyWithImpl<UserProfile>(this as UserProfile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProfile&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.units, units) || other.units == units)&&(identical(other.barWeight, barWeight) || other.barWeight == barWeight)&&const DeepCollectionEquality().equals(other.plateInventory, plateInventory)&&(identical(other.dumbbellIncrement, dumbbellIncrement) || other.dumbbellIncrement == dumbbellIncrement)&&(identical(other.activeProgramId, activeProgramId) || other.activeProgramId == activeProgramId)&&(identical(other.activeGymId, activeGymId) || other.activeGymId == activeGymId));
}


@override
int get hashCode => Object.hash(runtimeType,displayName,createdAt,updatedAt,units,barWeight,const DeepCollectionEquality().hash(plateInventory),dumbbellIncrement,activeProgramId,activeGymId);

@override
String toString() {
  return 'UserProfile(displayName: $displayName, createdAt: $createdAt, updatedAt: $updatedAt, units: $units, barWeight: $barWeight, plateInventory: $plateInventory, dumbbellIncrement: $dumbbellIncrement, activeProgramId: $activeProgramId, activeGymId: $activeGymId)';
}


}

/// @nodoc
abstract mixin class $UserProfileCopyWith<$Res>  {
  factory $UserProfileCopyWith(UserProfile value, $Res Function(UserProfile) _then) = _$UserProfileCopyWithImpl;
@useResult
$Res call({
 String displayName, DateTime createdAt, DateTime updatedAt, UnitSystem units, double barWeight, List<double> plateInventory, double dumbbellIncrement, String? activeProgramId, String? activeGymId
});




}
/// @nodoc
class _$UserProfileCopyWithImpl<$Res>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._self, this._then);

  final UserProfile _self;
  final $Res Function(UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? displayName = null,Object? createdAt = null,Object? updatedAt = null,Object? units = null,Object? barWeight = null,Object? plateInventory = null,Object? dumbbellIncrement = null,Object? activeProgramId = freezed,Object? activeGymId = freezed,}) {
  return _then(UserProfile(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as UnitSystem,barWeight: null == barWeight ? _self.barWeight : barWeight // ignore: cast_nullable_to_non_nullable
as double,plateInventory: null == plateInventory ? _self.plateInventory : plateInventory // ignore: cast_nullable_to_non_nullable
as List<double>,dumbbellIncrement: null == dumbbellIncrement ? _self.dumbbellIncrement : dumbbellIncrement // ignore: cast_nullable_to_non_nullable
as double,activeProgramId: freezed == activeProgramId ? _self.activeProgramId : activeProgramId // ignore: cast_nullable_to_non_nullable
as String?,activeGymId: freezed == activeGymId ? _self.activeGymId : activeGymId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProfile].
extension UserProfilePatterns on UserProfile {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProfile value)  $default,){
final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProfile value)?  $default,){
final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String displayName,  DateTime createdAt,  DateTime updatedAt,  UnitSystem units,  double barWeight,  List<double> plateInventory,  double dumbbellIncrement,  String? activeProgramId,  String? activeGymId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.displayName,_that.createdAt,_that.updatedAt,_that.units,_that.barWeight,_that.plateInventory,_that.dumbbellIncrement,_that.activeProgramId,_that.activeGymId);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String displayName,  DateTime createdAt,  DateTime updatedAt,  UnitSystem units,  double barWeight,  List<double> plateInventory,  double dumbbellIncrement,  String? activeProgramId,  String? activeGymId)  $default,) {final _that = this;
switch (_that) {
case _UserProfile():
return $default(_that.displayName,_that.createdAt,_that.updatedAt,_that.units,_that.barWeight,_that.plateInventory,_that.dumbbellIncrement,_that.activeProgramId,_that.activeGymId);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String displayName,  DateTime createdAt,  DateTime updatedAt,  UnitSystem units,  double barWeight,  List<double> plateInventory,  double dumbbellIncrement,  String? activeProgramId,  String? activeGymId)?  $default,) {final _that = this;
switch (_that) {
case _UserProfile() when $default != null:
return $default(_that.displayName,_that.createdAt,_that.updatedAt,_that.units,_that.barWeight,_that.plateInventory,_that.dumbbellIncrement,_that.activeProgramId,_that.activeGymId);case _:
  return null;

}
}

}

/// @nodoc


class _UserProfile implements UserProfile {
  const _UserProfile({required this.displayName, required this.createdAt, required this.updatedAt, this.units = UnitSystem.kg, this.barWeight = UserProfile.defaultBarWeight,  List<double> plateInventory = UserProfile.defaultPlateInventory, this.dumbbellIncrement = UserProfile.defaultDumbbellIncrement, this.activeProgramId, this.activeGymId}): _plateInventory = plateInventory;
  

@override final  String displayName;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override@JsonKey() final  UnitSystem units;
@override@JsonKey() final  double barWeight;
 final  List<double> _plateInventory;
@override@JsonKey() List<double> get plateInventory {
  if (_plateInventory is EqualUnmodifiableListView) return _plateInventory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_plateInventory);
}

@override@JsonKey() final  double dumbbellIncrement;
@override final  String? activeProgramId;
@override final  String? activeGymId;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProfileCopyWith<_UserProfile> get copyWith => __$UserProfileCopyWithImpl<_UserProfile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProfile&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.units, units) || other.units == units)&&(identical(other.barWeight, barWeight) || other.barWeight == barWeight)&&const DeepCollectionEquality().equals(other._plateInventory, _plateInventory)&&(identical(other.dumbbellIncrement, dumbbellIncrement) || other.dumbbellIncrement == dumbbellIncrement)&&(identical(other.activeProgramId, activeProgramId) || other.activeProgramId == activeProgramId)&&(identical(other.activeGymId, activeGymId) || other.activeGymId == activeGymId));
}


@override
int get hashCode => Object.hash(runtimeType,displayName,createdAt,updatedAt,units,barWeight,const DeepCollectionEquality().hash(_plateInventory),dumbbellIncrement,activeProgramId,activeGymId);

@override
String toString() {
  return 'UserProfile(displayName: $displayName, createdAt: $createdAt, updatedAt: $updatedAt, units: $units, barWeight: $barWeight, plateInventory: $plateInventory, dumbbellIncrement: $dumbbellIncrement, activeProgramId: $activeProgramId, activeGymId: $activeGymId)';
}


}

/// @nodoc
abstract mixin class _$UserProfileCopyWith<$Res> implements $UserProfileCopyWith<$Res> {
  factory _$UserProfileCopyWith(_UserProfile value, $Res Function(_UserProfile) _then) = __$UserProfileCopyWithImpl;
@override @useResult
$Res call({
 String displayName, DateTime createdAt, DateTime updatedAt, UnitSystem units, double barWeight, List<double> plateInventory, double dumbbellIncrement, String? activeProgramId, String? activeGymId
});




}
/// @nodoc
class __$UserProfileCopyWithImpl<$Res>
    implements _$UserProfileCopyWith<$Res> {
  __$UserProfileCopyWithImpl(this._self, this._then);

  final _UserProfile _self;
  final $Res Function(_UserProfile) _then;

/// Create a copy of UserProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? displayName = null,Object? createdAt = null,Object? updatedAt = null,Object? units = null,Object? barWeight = null,Object? plateInventory = null,Object? dumbbellIncrement = null,Object? activeProgramId = freezed,Object? activeGymId = freezed,}) {
  return _then(_UserProfile(
displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,units: null == units ? _self.units : units // ignore: cast_nullable_to_non_nullable
as UnitSystem,barWeight: null == barWeight ? _self.barWeight : barWeight // ignore: cast_nullable_to_non_nullable
as double,plateInventory: null == plateInventory ? _self._plateInventory : plateInventory // ignore: cast_nullable_to_non_nullable
as List<double>,dumbbellIncrement: null == dumbbellIncrement ? _self.dumbbellIncrement : dumbbellIncrement // ignore: cast_nullable_to_non_nullable
as double,activeProgramId: freezed == activeProgramId ? _self.activeProgramId : activeProgramId // ignore: cast_nullable_to_non_nullable
as String?,activeGymId: freezed == activeGymId ? _self.activeGymId : activeGymId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
