/// Unit system for every weight the app displays or stores.
///
/// Kilograms are the default (§2, A4). Imperial is a stored preference from M1
/// onward but converts nothing yet — there are no weights on screen until
/// session logging lands, so conversion has no surface to act on.
enum UnitSystem {
  kg('kg'),
  lb('lb');

  const UnitSystem(this.wireValue);

  /// The value written to Firestore. Fixed by §4 — do not derive it from
  /// [name], so renaming the enum can never rewrite stored documents.
  final String wireValue;

  /// Reads a stored value, falling back to [UnitSystem.kg] for anything
  /// absent or unrecognised.
  static UnitSystem fromWire(Object? value) => switch (value) {
    'lb' => UnitSystem.lb,
    _ => UnitSystem.kg,
  };
}
