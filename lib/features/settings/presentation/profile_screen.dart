import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mesa/core/formatters/weight_format.dart';
import 'package:mesa/core/validation/validators.dart';
import 'package:mesa/domain/models/unit_system.dart';
import 'package:mesa/domain/models/user_profile.dart';
import 'package:mesa/features/settings/presentation/widgets/plate_inventory_field.dart';
import 'package:mesa/features/settings/providers/profile_providers.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// Profile settings (F1): display name, units, bar weight, plate inventory and
/// dumbbell increment.
///
/// F8 folds this into a wider settings screen in M7. Everything here feeds the
/// progression maths in §7.2, which is why the numbers are editable at all.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: switch (profile) {
        AsyncData(value: final UserProfile profile) => _ProfileForm(
          key: ValueKey(profile.createdAt),
          profile: profile,
        ),
        // Null means the bootstrap write has not landed yet — a moment on a
        // fresh account, not an error.
        AsyncData() || AsyncLoading() => _Centred(child: Text(l10n.profileLoading)),
        AsyncError() => _Centred(child: Text(l10n.authErrorUnknown)),
      },
    );
  }
}

class _Centred extends StatelessWidget {
  const _Centred({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Center(child: Padding(padding: const EdgeInsets.all(24), child: child));
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.profile, super.key});

  final UserProfile profile;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayName;
  late final TextEditingController _barWeight;
  late final TextEditingController _dumbbellIncrement;
  late UnitSystem _units;
  late List<double> _plateInventory;

  @override
  void initState() {
    super.initState();
    _displayName = TextEditingController(text: widget.profile.displayName);
    _barWeight = TextEditingController(text: formatWeight(widget.profile.barWeight));
    _dumbbellIncrement = TextEditingController(
      text: formatWeight(widget.profile.dumbbellIncrement),
    );
    _units = widget.profile.units;
    _plateInventory = widget.profile.plateInventory;
  }

  @override
  void dispose() {
    _displayName.dispose();
    _barWeight.dispose();
    _dumbbellIncrement.dispose();
    super.dispose();
  }

  static double _parse(String value) =>
      double.parse(value.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(profileControllerProvider.notifier)
        .save(
          widget.profile.copyWith(
            displayName: _displayName.text.trim(),
            units: _units,
            barWeight: _parse(_barWeight.text),
            dumbbellIncrement: _parse(_dumbbellIncrement.text),
            plateInventory: _plateInventory,
          ),
        );

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.profileSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final busy = ref.watch(profileControllerProvider).isLoading;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextFormField(
            controller: _displayName,
            enabled: !busy,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.profileDisplayNameLabel,
              border: const OutlineInputBorder(),
            ),
            validator: (value) => Validators.displayName(l10n, value),
          ),
          const SizedBox(height: 24),
          Text(l10n.profileUnitsLabel, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<UnitSystem>(
            segments: [
              ButtonSegment(value: UnitSystem.kg, label: Text(l10n.profileUnitsKg)),
              ButtonSegment(value: UnitSystem.lb, label: Text(l10n.profileUnitsLb)),
            ],
            selected: {_units},
            onSelectionChanged: busy
                ? null
                : (selection) => setState(() => _units = selection.first),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _barWeight,
            enabled: !busy,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.profileBarWeightLabel,
              suffixText: _units.wireValue,
              border: const OutlineInputBorder(),
            ),
            validator: (value) => Validators.positiveNumber(l10n, value),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _dumbbellIncrement,
            enabled: !busy,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.profileDumbbellIncrementLabel,
              suffixText: _units.wireValue,
              border: const OutlineInputBorder(),
            ),
            validator: (value) => Validators.positiveNumber(l10n, value),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.profilePlateInventoryLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.profilePlateInventoryHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          PlateInventoryField(
            selected: _plateInventory,
            enabled: !busy,
            onChanged: (plates) => setState(() => _plateInventory = plates),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: busy ? null : _save,
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }
}
