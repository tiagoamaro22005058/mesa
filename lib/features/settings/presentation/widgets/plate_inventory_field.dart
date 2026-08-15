import 'package:flutter/material.dart';
import 'package:mesa/core/formatters/weight_format.dart';

/// Picks which plates the gym actually has (F1, §4).
///
/// A chip toggle rather than a free-form list: the standard kilogram set
/// covers every plate in §4's default inventory, and tapping chips beats typing
/// weights. Anything outside this set would need §4's vocabulary widened first.
class PlateInventoryField extends StatelessWidget {
  const PlateInventoryField({
    required this.selected,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final List<double> selected;
  final ValueChanged<List<double>> onChanged;
  final bool enabled;

  /// The plates offered, heaviest first. §4's default inventory is this list
  /// without the 0.5 kg fractional.
  static const List<double> standardPlates = [25, 20, 15, 10, 5, 2.5, 1.25, 0.5];

  void _toggle(double plate) {
    final next = selected.contains(plate)
        ? (selected.where((p) => p != plate).toList())
        : ([...selected, plate]..sort((a, b) => b.compareTo(a)));
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final plate in standardPlates)
          FilterChip(
            label: Text(formatWeight(plate)),
            selected: selected.contains(plate),
            onSelected: enabled ? (_) => _toggle(plate) : null,
          ),
      ],
    );
  }
}
