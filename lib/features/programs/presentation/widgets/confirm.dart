import 'package:flutter/material.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// Asks before doing something that cannot be undone (NFR5).
///
/// One implementation rather than a `showDialog` per screen: M3 has four
/// destructive or displacing actions, and four hand-rolled dialogs is four
/// chances for one of them to ship without a cancel button.
///
/// Returns false when dismissed by tapping outside, so a stray tap can never
/// be read as consent.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = true,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final colours = Theme.of(context).colorScheme;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destructive
              ? TextButton.styleFrom(foregroundColor: colours.error)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
