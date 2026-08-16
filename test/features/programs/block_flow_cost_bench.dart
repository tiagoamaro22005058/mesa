// Instrumentation, not an assertion. Walks the real add-a-block flow through
// the real router and prices each step separately, so a change to the flow can
// be costed from measured primitives rather than from arithmetic.
//
// Measures per block: taps, text fields touched, characters typed, and
// milliseconds of animation the user cannot act during (frames × 16 ms).
//
// The day modelled below is the owner's real Legs day, reported 2026-08-16:
// 7 blocks, 6 distinct schemes with one exact repeat, `sets` constant after the
// first block, `rest` constant throughout, and consecutive blocks differing in
// 1–2 rep fields.
//
// Run: flutter test test/features/programs/block_flow_cost_bench.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/domain/models/auth_user.dart';
import 'package:mesa/domain/models/user_profile.dart';

import '../../support/exercises.dart';
import '../../support/fakes.dart';
import '../../support/programs.dart';
import '../../support/pump_app.dart';

class Step {
  Step(this.name);

  final String name;
  int taps = 0;
  int fields = 0;
  int chars = 0;
  int animMs = 0;

  String per(int blocks) =>
      '${name.padRight(13)} taps=${(taps / blocks).toStringAsFixed(2)}'
      '  fields=${(fields / blocks).toStringAsFixed(2)}'
      '  chars=${(chars / blocks).toStringAsFixed(2)}'
      '  animMs=${(animMs / blocks).round()}';
}

/// One block of the modelled day: what to search for, what to pick, which
/// scheme fields actually change from the block before it, and its RPE.
class Row {
  const Row(this.query, this.name, this.edits, {this.rpe});

  final String query;
  final String name;

  /// Ordered so the rep range is never transiently inverted — raising `repMin`
  /// above the carried `repMax` trips the validator and blocks the save.
  final List<(String, String)> edits;
  final String? rpe;
}

void main() {
  const user = AuthUser(uid: 'uid-a', email: 'a@example.com', displayName: 'Tiago');
  final now = DateTime.utc(2026, 8, 16);

  // squat 4×6-8 @8 · press 3×6-8 @8 · RDL 3×8-10 @7 · extension 3×8-15 @7
  // curl 3×10-15 @7 · calf 3×10-15 @7 (exact repeat) · abduction 3×12-20 @8
  const rows = <Row>[
    Row('squat', 'Barbell Full Squat', [
      ('Sets', '4'),
      ('Reps from', '6'),
      ('to', '8'),
      ('Rest (seconds)', '150'),
    ], rpe: '8'),
    Row('press', 'Leg Press', [('Sets', '3')]),
    Row('romanian', 'Barbell Romanian Deadlift', [
      ('Reps from', '8'),
      ('to', '10'),
    ], rpe: '7'),
    Row('extension', 'Leg Extension', [('to', '15')]),
    Row('curl', 'Lying Leg Curl', [('Reps from', '10')]),
    Row('calf', 'Standing Calf Raise', []),
    Row('abduction', 'Hip Abduction', [
      ('Reps from', '12'),
      ('to', '20'),
    ], rpe: '8'),
  ];

  testWidgets('bench', (tester) async {
    final auth = FakeAuthRepository(initialUser: user);
    final profiles = FakeUserProfileRepository();
    profiles.profiles['uid-a'] = UserProfile(
      displayName: 'Tiago',
      createdAt: now,
      updatedAt: now,
      // Starred once in F2. The picker then leads with them, so a block costs
      // a tap instead of a typed query.
      favouriteExerciseIds: const [
        '0043', '0739', '0085', '0585', '0599', '0417', '0995',
      ],
    );
    final programs = FakeProgramRepository(profiles: profiles);
    programs.programs['uid-a'] = [program('program-1', 'PPL')];
    programs.days['uid-a/program-1'] = [day('day-1', 'Legs')];

    final catalog = FakeExerciseCatalog(
      exercises: [
        exercise('0043', 'barbell full squat'),
        exercise('0739', 'leg press'),
        exercise('0085', 'barbell romanian deadlift'),
        exercise('0585', 'leg extension'),
        exercise('0599', 'lying leg curl'),
        exercise('0417', 'standing calf raise'),
        exercise('0995', 'hip abduction'),
      ],
    );

    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final navIn = Step('navIn');
    final pickerOpen = Step('pickerOpen');
    final pickerType = Step('pickerType');
    final pickerSelect = Step('pickerSelect');
    final schemeText = Step('schemeText');
    final schemeRpe = Step('schemeRpe');
    final saveAndBack = Step('saveAndBack');
    final all = [
      navIn,
      pickerOpen,
      pickerType,
      pickerSelect,
      schemeText,
      schemeRpe,
      saveAndBack,
    ];

    late Step current;

    Future<void> settle() async {
      final frames = await tester.pumpAndSettle(const Duration(milliseconds: 16));
      current.animMs += frames * 16;
    }

    Future<void> tap(Finder finder) async {
      current.taps++;
      await tester.tap(finder);
      await settle();
    }

    Future<void> type(Finder finder, String value) async {
      current.fields++;
      current.chars += value.length;
      // A tap to focus the field, which the user pays even with the keyboard
      // already up. Select-on-focus is why this is a type and not a
      // clear-then-type.
      current.taps++;
      await tester.tap(finder);
      await tester.pump();
      await tester.enterText(finder, value);
      await settle();
    }

    await pumpApp(
      tester,
      auth: auth,
      profiles: profiles,
      programs: programs,
      catalog: catalog,
    );

    // Setup: reach the day editor. Paid once per day, not per block.
    await tester.tap(find.text('Programs'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PPL'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Legs'));
    await tester.pumpAndSettle();

    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];

      // Only the first block of a day pays these: every later save reopens the
      // picker itself.
      if (index == 0) {
        current = navIn;
        await tap(find.widgetWithText(FloatingActionButton, 'Add exercise'));

        current = pickerOpen;
        await tap(find.widgetWithText(OutlinedButton, 'Choose an exercise'));
      }

      // No typed query: the exercise is already on screen, starred.
      current = pickerSelect;
      await tap(find.text(row.name).last);

      current = schemeText;
      for (final (label, value) in row.edits) {
        await type(find.widgetWithText(TextFormField, label), value);
      }

      if (row.rpe != null) {
        current = schemeRpe;
        await tap(find.byType(DropdownButtonFormField<double>));
        await tap(find.text(row.rpe!).last);
      }

      current = saveAndBack;
      await tap(find.widgetWithText(FilledButton, 'Save'));

      final stored = programs.days['uid-a/program-1']!.single.blocks.length;
      if (stored != index + 1) {
        throw StateError('block ${index + 1} did not save (stored=$stored)');
      }
    }

    // Dismissing the reopened picker is how the user says they are done.
    current = saveAndBack;
    current.taps++;
    await tester.tapAt(const Offset(500, 20));
    await settle();

    final blocks = rows.length;
    debugPrint('BENCH ==== per block, averaged over $blocks ====');
    for (final step in all) {
      debugPrint('BENCH ${step.per(blocks)}');
    }

    final totalTaps = all.fold(0, (sum, s) => sum + s.taps);
    final totalFields = all.fold(0, (sum, s) => sum + s.fields);
    final totalChars = all.fold(0, (sum, s) => sum + s.chars);
    final totalAnim = all.fold(0, (sum, s) => sum + s.animMs);

    debugPrint(
      'BENCH ${'TOTAL'.padRight(13)} taps=${(totalTaps / blocks).toStringAsFixed(2)}'
      '  fields=${(totalFields / blocks).toStringAsFixed(2)}'
      '  chars=${(totalChars / blocks).toStringAsFixed(2)}'
      '  animMs=${(totalAnim / blocks).round()}',
    );
    debugPrint('BENCH DAY TOTALS   taps=$totalTaps  fields=$totalFields  '
        'chars=$totalChars  animMs=$totalAnim');
    debugPrint(
      'BENCH stored=${programs.days['uid-a/program-1']!.single.blocks.length}',
    );

    // Deliberately no dispose(): closing the fakes' controllers while the live
    // router still has providers listening hangs the test's finalisation, and
    // this file measures rather than asserts.
  });
}
