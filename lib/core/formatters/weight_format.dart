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
