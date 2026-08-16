import 'package:flutter/material.dart';
import 'package:mesa/core/formatters/weight_format.dart';

/// Picks a target RPE from the half-point scale.
///
/// A dropdown rather than a text field: RPE is a closed vocabulary in half
/// steps, so there is nothing to parse, nothing to validate, and nothing for a
/// chalky thumb to mistype (NFR4). It also sidesteps the decimal-separator
/// problem entirely — there is no keyboard involved (§9.1, NFR7).
///
/// The scale starts at 5: §4's own deload sits at 5.5, and anything below that
/// is a warm-up rather than a prescription.
class RpeDropdown extends StatelessWidget {
  const RpeDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
    this.helperText,
    this.enabled = true,
    super.key,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final String? helperText;
  final bool enabled;

  static const List<double> values = [
    5, 5.5, 6, 6.5, 7, 7.5, 8, 8.5, 9, 9.5, 10,
  ];

  @override
  Widget build(BuildContext context) {
    // A stored value off the scale — hand-edited, or written by a later
    // version — is shown rather than silently snapped to a neighbour.
    //
    // The parentheses are load-bearing: a cascade binds looser than `?:`, so
    // `a ? b : c..sort()` sorts whichever branch was chosen — including the
    // const `values`, which throws on the spot.
    final options = values.contains(value) ? values : ([...values, value]..sort());

    return DropdownButtonFormField<double>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        helperMaxLines: 2,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final option in options)
          DropdownMenuItem<double>(
            value: option,
            child: Text(formatWeight(option)),
          ),
      ],
      onChanged: enabled
          ? (selected) {
              if (selected != null) onChanged(selected);
            }
          : null,
    );
  }
}
