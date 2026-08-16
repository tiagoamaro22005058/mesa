import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mesa/app/router.dart';
import 'package:mesa/core/formatters/weight_format.dart';
import 'package:mesa/core/validation/validators.dart';
import 'package:mesa/domain/models/program.dart';
import 'package:mesa/features/programs/providers/program_providers.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// Creates or edits a program's name, goal and sessions per week (F3).
///
/// [programId] is null when creating.
class ProgramFormScreen extends ConsumerWidget {
  const ProgramFormScreen({this.programId, super.key});

  final String? programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (programId == null) return const _Form(existing: null);

    final programs = ref.watch(programsProvider);
    final program = ref.watch(programByIdProvider(programId!));

    // Still loading is not the same as gone: showing "no longer exists" before
    // the first snapshot arrives would flash an error on every deep link.
    if (programs.isLoading && !programs.hasValue) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (program == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.programNotFound)),
      );
    }

    return _Form(existing: program);
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.existing});

  final Program? existing;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _goal;
  late final TextEditingController _daysPerWeek;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _name = TextEditingController(text: existing?.name ?? '');
    _goal = TextEditingController(text: existing?.goal ?? '');
    _daysPerWeek = TextEditingController(
      text: '${existing?.daysPerWeek ?? Program.defaultDaysPerWeek}',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    _daysPerWeek.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final saving = ref.watch(programControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null ? l10n.programNewTitle : l10n.programEditTitle,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                enabled: !saving,
                decoration: InputDecoration(
                  labelText: l10n.programNameLabel,
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) => Validators.displayName(l10n, value),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _goal,
                enabled: !saving,
                decoration: InputDecoration(
                  labelText: l10n.programGoalLabel,
                  helperText: l10n.programGoalHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _daysPerWeek,
                enabled: !saving,
                decoration: InputDecoration(
                  labelText: l10n.programDaysPerWeekLabel,
                  helperText: l10n.programDaysPerWeekHint,
                  helperMaxLines: 3,
                  border: const OutlineInputBorder(),
                ),
                // Comma and dot are both offered by the parser (§9.1), so the
                // keyboard may show either without the field lying about what
                // it accepts.
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                validator: (value) => Validators.positiveInt(l10n, value),
              ),
              const SizedBox(height: 24),

              // NFR4: the commit action in the bottom third, thumb-reachable.
              FilledButton(
                onPressed: saving ? null : _save,
                child: Text(l10n.commonSave),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final controller = ref.read(programControllerProvider.notifier);

    final name = _name.text.trim();
    final goal = _goal.text.trim();
    final daysPerWeek = parseCount(_daysPerWeek.text) ?? Program.defaultDaysPerWeek;

    final existing = widget.existing;
    final String? programId;

    if (existing == null) {
      final created = await controller.createProgram(
        name: name,
        goal: goal.isEmpty ? null : goal,
        daysPerWeek: daysPerWeek,
      );
      programId = created?.id;
    } else {
      await controller.saveProgram(
        existing.copyWith(
          name: name,
          // Explicitly null rather than omitted, so emptying the field clears
          // the stored goal instead of leaving the old one behind.
          goal: goal.isEmpty ? null : goal,
          daysPerWeek: daysPerWeek,
        ),
      );
      programId = existing.id;
    }

    if (!mounted || programId == null) return;

    messenger.showSnackBar(SnackBar(content: Text(l10n.programSaved)));
    router.goNamed(Routes.programDetail, pathParameters: {'programId': programId});
  }
}
