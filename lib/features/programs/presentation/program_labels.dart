import 'package:mesa/core/formatters/weight_format.dart';
import 'package:mesa/domain/models/program.dart';
import 'package:mesa/domain/models/set_scheme.dart';
import 'package:mesa/domain/models/week_role.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// Localised names for the program vocabulary, in one place rather than a
/// switch per screen — the same shape as `ExerciseLabels`.
abstract final class ProgramLabels {
  static String status(AppLocalizations l10n, ProgramStatus status) =>
      switch (status) {
        ProgramStatus.draft => l10n.programStatusDraft,
        ProgramStatus.active => l10n.programStatusActive,
        ProgramStatus.archived => l10n.programStatusArchived,
      };

  static String weekRole(AppLocalizations l10n, WeekRoleKind kind) =>
      switch (kind) {
        WeekRoleKind.base => l10n.weekRoleBase,
        WeekRoleKind.intensification => l10n.weekRoleIntensification,
        WeekRoleKind.peak => l10n.weekRolePeak,
        WeekRoleKind.deload => l10n.weekRoleDeload,
      };

  /// "RPE 7 · 0.9 volume".
  ///
  /// Both numbers go through [formatWeight], which is the app's only renderer
  /// for a decimal — so a multiplier of exactly 1 reads as `1`, not `1.0`
  /// (§9.1).
  static String weekRoleSummary(AppLocalizations l10n, WeekRole role) =>
      l10n.weekRoleSummary(
        formatWeight(role.rpeTarget),
        formatWeight(role.volumeMultiplier),
      );

  /// "4 × 6-8 @ RPE 8".
  static String setScheme(AppLocalizations l10n, SetScheme scheme) =>
      l10n.blockSchemeSummary(
        scheme.sets,
        scheme.repMin,
        scheme.repMax,
        formatWeight(scheme.rpeTarget),
      );
}
