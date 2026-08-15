import 'package:mesa/domain/models/load_model.dart';

/// What an exercise is performed with (§5.4, §5.6).
///
/// Finer-grained than §4's `Gym.equipment` vocabulary, deliberately. §5.4 asks
/// for the 28 upstream strings to collapse onto that vocabulary, but they
/// cannot collapse only that far: §5.6 needs `weighted` and `assisted` told
/// apart from everything else, and §7.2's load increment needs a kettlebell
/// told apart from a barbell. So the model keeps the fine-grained enum and
/// carries the gym tag alongside it, via [gymTag].
enum Equipment {
  barbell('barbell', LoadModel.externalLoad, GymEquipmentTag.barbell),
  ezBarbell('ez_barbell', LoadModel.externalLoad, GymEquipmentTag.barbell),
  olympicBarbell('olympic_barbell', LoadModel.externalLoad, GymEquipmentTag.barbell),
  trapBar('trap_bar', LoadModel.externalLoad, GymEquipmentTag.barbell),
  dumbbell('dumbbell', LoadModel.externalLoad, GymEquipmentTag.dumbbell),
  kettlebell('kettlebell', LoadModel.externalLoad, GymEquipmentTag.dumbbell),
  cable('cable', LoadModel.externalLoad, GymEquipmentTag.cable),
  leverageMachine('leverage_machine', LoadModel.externalLoad, GymEquipmentTag.machine),
  smithMachine('smith_machine', LoadModel.externalLoad, GymEquipmentTag.smith),
  sledMachine('sled_machine', LoadModel.externalLoad, GymEquipmentTag.machine),
  band('band', LoadModel.externalLoad, GymEquipmentTag.bands),
  medicineBall('medicine_ball', LoadModel.externalLoad, null),
  bodyWeight('body_weight', LoadModel.bodyweight, GymEquipmentTag.bodyweight),
  weighted('weighted', LoadModel.bodyweightPlusLoad, GymEquipmentTag.bodyweight),
  assisted('assisted', LoadModel.assisted, GymEquipmentTag.machine),

  /// The long tail §5.4 says must not survive as free text: stability and bosu
  /// balls, rollers, ropes, a sledge hammer, a tire. Kept rather than excluded
  /// (M2) so the catalogue stays at §5.2's 1,295, but with no equipment
  /// identity worth naming.
  ///
  /// Its [defaultLoadModel] is [LoadModel.bodyweight], which is right for the
  /// stretches and core work that make up almost all of it. The two records it
  /// is wrong for — a sledge hammer and a tire flip — are externally loaded,
  /// and ingestion assigns them that directly; this default only applies to a
  /// custom exercise the user creates.
  other('other', LoadModel.bodyweight, null);

  const Equipment(this.wireValue, this.defaultLoadModel, this.gymTag);

  final String wireValue;

  /// The load model ingestion derives for this equipment (§5.6), and the one a
  /// user-created exercise gets. Catalogue entries carry their own, so this
  /// stays a default rather than the authority — a test holds the two to each
  /// other across all 1,295 records.
  final LoadModel defaultLoadModel;

  /// §4's `Gym.equipment` tag, for M7's substitution.
  ///
  /// `null` means the requirement is not expressible in §4's seven tags — a
  /// stability ball is neither a machine nor bodyweight. Substitution will
  /// never flag those as missing at a gym, which is the honest outcome: the app
  /// has no way to record whether a gym has one.
  final GymEquipmentTag? gymTag;

  static Equipment? tryFromWire(Object? value) => _byWire[value];

  static final Map<Object?, Equipment> _byWire = {
    for (final equipment in Equipment.values) equipment.wireValue: equipment,
  };
}

/// §4's `Gym.equipment` vocabulary.
///
/// Nothing in M2 reads this — gyms arrive in M7. It lives here because the
/// mapping from equipment to tag is decided at ingestion and belongs next to
/// the thing it maps, not in the feature that eventually consumes it.
enum GymEquipmentTag {
  barbell('barbell'),
  dumbbell('dumbbell'),
  cable('cable'),
  machine('machine'),
  smith('smith'),
  bands('bands'),
  bodyweight('bodyweight');

  const GymEquipmentTag(this.wireValue);

  final String wireValue;

  static GymEquipmentTag? tryFromWire(Object? value) => _byWire[value];

  static final Map<Object?, GymEquipmentTag> _byWire = {
    for (final tag in GymEquipmentTag.values) tag.wireValue: tag,
  };
}
