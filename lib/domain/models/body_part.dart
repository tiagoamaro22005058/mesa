/// Upstream's `body_part`, which is the coarse grouping the catalogue filters
/// by (§5.3).
///
/// Byte-identical to upstream's `category` in all 1,324 records, which is why
/// `category` is dropped at ingestion. Cardio is not here: A1 was rejected and
/// the 29 cardio records are excluded outright (§5.4).
enum BodyPart {
  back('back'),
  chest('chest'),
  lowerArms('lower_arms'),
  lowerLegs('lower_legs'),
  neck('neck'),
  shoulders('shoulders'),
  upperArms('upper_arms'),
  upperLegs('upper_legs'),
  waist('waist');

  const BodyPart(this.wireValue);

  final String wireValue;

  static BodyPart? tryFromWire(Object? value) => _byWire[value];

  static final Map<Object?, BodyPart> _byWire = {
    for (final part in BodyPart.values) part.wireValue: part,
  };
}
