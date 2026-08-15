/// Renders a weight without trailing noise: `20`, not `20.0`, and `2.5`
/// rather than `2.50`.
///
/// Unit-agnostic on purpose — it formats the number, and the caller decides
/// whether a `kg`/`lb` suffix belongs next to it.
String formatWeight(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// Reads a weight the user typed, accepting either decimal separator.
///
/// The Portuguese keyboard — and most non-English ones — offer a comma where
/// Dart's parser wants a dot. Refusing `17,5` reads as the app being broken
/// rather than fussy, and a gym app is used by someone with chalk on their
/// hands who will not go hunting for the right key. Every numeric input goes
/// through here so the behaviour cannot drift between screens (§9.1).
///
/// Returns `null` for anything that is not a number, which is what makes it
/// usable directly from a form validator.
///
/// Thousands separators are deliberately not handled: `1.234` is genuinely
/// ambiguous between locales, and no weight in this app needs four digits.
double? parseWeight(String? input) {
  final normalised = (input ?? '').trim().replaceAll(',', '.');
  if (normalised.isEmpty) return null;
  return double.tryParse(normalised);
}
