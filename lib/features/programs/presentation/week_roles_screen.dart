import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mesa/core/formatters/weight_format.dart';
import 'package:mesa/core/validation/validators.dart';
import 'package:mesa/domain/models/program.dart';
import 'package:mesa/domain/models/week_role.dart';
import 'package:mesa/features/programs/presentation/program_labels.dart';
import 'package:mesa/features/programs/presentation/widgets/rpe_dropdown.dart';
import 'package:mesa/features/programs/providers/program_providers.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// Add, remove, reorder and edit a program's week roles (F3).
///
/// One pass through the list is a mesocycle (§3). The list is ordered and a
/// role may repeat, so a week's identity is its position, not its name (A2).
class WeekRolesScreen extends ConsumerWidget {
  const WeekRolesScreen({required this.programId, super.key});

  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final programs = ref.watch(programsProvider);
    final program = ref.watch(programByIdProvider(programId));

    if (programs.isLoading && !programs.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (program == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.programNotFound)),
      );
    }

    return _Editor(
      // Rebuilt when the program identity changes, so the local draft is never
      // carried across to a different program.
      key: ValueKey(program.id),
      program: program,
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.program, super.key});

  final Program program;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  /// Edited locally and written once on save, rather than a document write per
  /// keystroke. Reordering four weeks would otherwise cost four writes (NFR2).
  late List<WeekRole> _roles;

  @override
  void initState() {
    super.initState();
    _roles = [...widget.program.weekRoles];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final busy = ref.watch(programControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.weekRolesTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(l10n.weekRolesHint, style: theme.textTheme.bodySmall),
            ),
            Expanded(
              child: _roles.isEmpty
                  ? _Empty()
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _roles.length,
                      // `onReorderItem` reports the destination already
                      // adjusted for the item having left its old slot, unlike
                      // the deprecated `onReorder`. Correcting it again here
                      // would move a week one place short.
                      onReorderItem: (oldIndex, newIndex) {
                        setState(() {
                          _roles.insert(newIndex, _roles.removeAt(oldIndex));
                        });
                      },
                      itemBuilder: (context, position) => _Row(
                        // Position, not role — the same role may appear twice,
                        // so keying on it would confuse two identical weeks.
                        key: ValueKey('week-$position'),
                        index: position,
                        role: _roles[position],
                        onEdit: () => _edit(position),
                        onRemove: () => setState(() => _roles.removeAt(position)),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: OutlinedButton.icon(
                onPressed: busy ? null : _add,
                icon: const Icon(Icons.add),
                label: Text(l10n.weekRoleAdd),
              ),
            ),
            // NFR4: the commit action in the bottom third, thumb-reachable.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy ? null : _save,
                  child: Text(l10n.commonSave),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _add() {
    setState(() {
      _roles.add(
        const WeekRole(role: WeekRoleKind.base, rpeTarget: 7, volumeMultiplier: 1),
      );
    });
  }

  Future<void> _edit(int index) async {
    final edited = await showModalBottomSheet<WeekRole>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _RoleSheet(index: index, role: _roles[index]),
    );
    if (edited == null) return;

    setState(() => _roles[index] = edited);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    await ref
        .read(programControllerProvider.notifier)
        .saveProgram(widget.program.copyWith(weekRoles: [..._roles]));
    if (!mounted) return;

    messenger.showSnackBar(SnackBar(content: Text(l10n.weekRoleSaved)));
    if (router.canPop()) router.pop();
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.index,
    required this.role,
    required this.onEdit,
    required this.onRemove,
    super.key,
  });

  final int index;
  final WeekRole role;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListTile(
      title: Text(ProgramLabels.weekRole(l10n, role.role)),
      subtitle: Text(
        '${l10n.weekRoleWeekNumber(index + 1)} · '
        '${ProgramLabels.weekRoleSummary(l10n, role)}',
      ),
      minTileHeight: 64,
      onTap: onEdit,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onRemove,
            tooltip: l10n.commonRemove,
            icon: const Icon(Icons.close),
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.drag_handle),
            ),
          ),
        ],
      ),
    );
  }
}

/// Edits one week's role, RPE target and volume multiplier.
class _RoleSheet extends StatefulWidget {
  const _RoleSheet({required this.index, required this.role});

  final int index;
  final WeekRole role;

  @override
  State<_RoleSheet> createState() => _RoleSheetState();
}

class _RoleSheetState extends State<_RoleSheet> {
  final _formKey = GlobalKey<FormState>();

  late WeekRoleKind _kind;
  late double _rpeTarget;
  late final TextEditingController _volume;

  @override
  void initState() {
    super.initState();
    _kind = widget.role.role;
    _rpeTarget = widget.role.rpeTarget;
    _volume = TextEditingController(
      text: formatWeight(widget.role.volumeMultiplier),
    );
  }

  @override
  void dispose() {
    _volume.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.weekRoleWeekNumber(widget.index + 1),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<WeekRoleKind>(
              initialValue: _kind,
              decoration: InputDecoration(
                labelText: l10n.weekRolesTitle,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final kind in WeekRoleKind.values)
                  DropdownMenuItem<WeekRoleKind>(
                    value: kind,
                    child: Text(ProgramLabels.weekRole(l10n, kind)),
                  ),
              ],
              onChanged: (selected) {
                if (selected != null) setState(() => _kind = selected);
              },
            ),
            const SizedBox(height: 16),

            RpeDropdown(
              label: l10n.weekRoleRpeLabel,
              value: _rpeTarget,
              onChanged: (value) => setState(() => _rpeTarget = value),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _volume,
              decoration: InputDecoration(
                labelText: l10n.weekRoleVolumeLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              validator: (value) => Validators.positiveNumber(l10n, value),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _done, child: Text(l10n.commonSave)),
            ),
          ],
        ),
      ),
    );
  }

  void _done() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      WeekRole(
        role: _kind,
        rpeTarget: _rpeTarget,
        volumeMultiplier: parseWeight(_volume.text) ?? 1,
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.weekRolesEmptyTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              l10n.weekRolesEmptyBody,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
