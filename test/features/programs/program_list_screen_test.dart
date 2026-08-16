// F3: "Create a program", and the list it lands in.
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/domain/models/auth_user.dart';
import 'package:mesa/domain/models/program.dart';
import 'package:mesa/domain/models/user_profile.dart';
import 'package:mesa/features/programs/presentation/program_list_screen.dart';

import '../../support/fakes.dart';
import '../../support/programs.dart';
import '../../support/pump_app.dart';

void main() {
  const user = AuthUser(uid: 'uid-a', email: 'a@example.com', displayName: 'Tiago');
  final now = DateTime.utc(2026, 8, 16);

  late FakeAuthRepository auth;
  late FakeUserProfileRepository profiles;
  late FakeProgramRepository programs;

  setUp(() {
    auth = FakeAuthRepository(initialUser: user);
    profiles = FakeUserProfileRepository();
    profiles.profiles['uid-a'] = UserProfile(
      displayName: 'Tiago',
      createdAt: now,
      updatedAt: now,
    );
    programs = FakeProgramRepository(profiles: profiles);
  });

  tearDown(() async {
    await auth.dispose();
    await profiles.dispose();
    await programs.dispose();
  });

  Future<void> pump(WidgetTester tester) => pumpRoutedScreen(
    tester,
    const ProgramListScreen(),
    auth: auth,
    profiles: profiles,
    programs: programs,
  );

  testWidgets('invites the user to build one when there are none', (tester) async {
    await pump(tester);

    expect(find.text('No programs yet'), findsOneWidget);
    expect(find.text('New program'), findsOneWidget);
  });

  testWidgets('lists the programs the user owns', (tester) async {
    programs.programs['uid-a'] = [
      program('program-1', 'PPL'),
      program('program-2', 'Upper/Lower'),
    ];

    await pump(tester);

    expect(find.text('PPL'), findsOneWidget);
    expect(find.text('Upper/Lower'), findsOneWidget);
  });

  testWidgets('shows another account none of this one\'s programs', (tester) async {
    // The same isolation the rules tests prove server-side, asserted here at
    // the repository boundary.
    programs.programs['uid-b'] = [program('program-1', 'Someone else\'s')];

    await pump(tester);

    expect(find.text('Someone else\'s'), findsNothing);
    expect(find.text('No programs yet'), findsOneWidget);
  });

  testWidgets('hides archived programs until asked for them', (tester) async {
    // F3 archives rather than deletes, so an archived program has to stay
    // reachable — just not in the way.
    programs.programs['uid-a'] = [
      program('program-1', 'PPL'),
      program('program-2', 'Old block', status: ProgramStatus.archived),
    ];

    await pump(tester);
    expect(find.text('Old block'), findsNothing);

    await tester.tap(find.byTooltip('Show archived'));
    await tester.pumpAndSettle();

    expect(find.text('Old block'), findsOneWidget);
  });

  testWidgets('marks which program is active', (tester) async {
    programs.programs['uid-a'] = [
      program('program-1', 'PPL', status: ProgramStatus.active),
    ];

    await pump(tester);

    // The subtitle joins the status with the week count, so this is a
    // substring match rather than an exact one.
    expect(find.textContaining('Active'), findsOneWidget);
  });

  testWidgets('sorts the most recently updated first', (tester) async {
    // The list is sorted client-side rather than with orderBy, so that it
    // works against the offline cache and needs no index (NFR1, NFR2).
    programs.programs['uid-a'] = [
      program('program-1', 'Older', updatedAt: now),
      program('program-2', 'Newer', updatedAt: now.add(const Duration(days: 1))),
    ];

    await pump(tester);

    expect(
      tester.getTopLeft(find.text('Newer')).dy,
      lessThan(tester.getTopLeft(find.text('Older')).dy),
    );
  });
}
