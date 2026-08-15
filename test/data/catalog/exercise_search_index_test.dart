import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/data/catalog/bundled_exercise_catalog.dart';
import 'package:mesa/data/catalog/exercise_search_index.dart';
import 'package:mesa/domain/models/body_part.dart';
import 'package:mesa/domain/models/equipment.dart';
import 'package:mesa/domain/models/exercise.dart';
import 'package:mesa/domain/models/exercise_filter.dart';
import 'package:mesa/domain/models/muscle.dart';

import '../../support/exercises.dart';

/// F2: "fuzzy search across name + aliases, sub-100 ms across all 1,295
/// entries" and "filter by body part, primary muscle and equipment".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<String> idsOf(List<Exercise> results) => [for (final e in results) e.id];

  group('search', () {
    final index = ExerciseSearchIndex([
      exercise('0001', 'barbell bench press', aliases: ['supino reto']),
      exercise('0002', 'dumbbell bench press', equipment: Equipment.dumbbell),
      exercise('0003', 'barbell full squat', aliases: ['agachamento livre']),
      exercise('0004', 'push-up (on stability ball)', equipment: Equipment.bodyWeight),
      exercise('0005', 'cable crossover'),
    ]);

    test('an empty query returns everything, alphabetically', () {
      final results = index.search('');

      expect(idsOf(results), ['0001', '0003', '0005', '0002', '0004']);
    });

    test('finds an exercise by name', () {
      expect(idsOf(index.search('squat')), ['0003']);
    });

    test('ranks the exact name above the names containing it', () {
      final results = index.search('bench press');

      // Neither is an exact match, so the shorter name wins the tie — which is
      // also the one someone typing "bench press" most likely meant.
      expect(idsOf(results), ['0001', '0002']);
      expect(idsOf(index.search('dumbbell bench press')).first, '0002');
    });

    test('finds an exercise by its Portuguese alias', () {
      // The dataset ships ten languages and Portuguese is not one of them, so
      // this only works because aliases_pt.json exists (§5.4).
      expect(idsOf(index.search('supino')), ['0001']);
      expect(idsOf(index.search('agachamento livre')), ['0003']);
    });

    test('ignores accents in either direction', () {
      final index = ExerciseSearchIndex([
        exercise('0001', 'push-up', aliases: ['flexão de braços']),
      ]);

      expect(idsOf(index.search('flexao')), ['0001']);
      expect(idsOf(index.search('flexão')), ['0001']);
      expect(idsOf(index.search('BRAÇOS')), ['0001']);
    });

    test('ignores punctuation and case', () {
      expect(idsOf(index.search('PUSH UP')), ['0004']);
      expect(idsOf(index.search('push-up')), ['0004']);
      expect(idsOf(index.search('pushup')), isEmpty);
    });

    test('matches words in any order', () {
      expect(idsOf(index.search('press bench barbell')), ['0001']);
    });

    test('matches on word prefixes, so half a word is enough', () {
      expect(idsOf(index.search('barb ben')), ['0001']);
    });

    test('survives a typo in a word long enough for one', () {
      // Typed one-handed with chalk on the hands. `squt` has to find squats.
      expect(idsOf(index.search('squt')), ['0003']);
      expect(idsOf(index.search('dumbell bench')), ['0002']);
    });

    test('does not invent matches for a query that means nothing', () {
      expect(index.search('kayaking'), isEmpty);
    });

    test('a custom exercise appears inline with the catalogue ones', () {
      final index = ExerciseSearchIndex([
        exercise('0001', 'barbell bench press'),
        customExercise('custom-1', 'bench press machine (my gym)'),
      ]);

      final results = index.search('bench press');

      expect(idsOf(results), containsAll(['0001', 'custom-1']));
      expect(results.firstWhere((e) => e.id == 'custom-1').isCustom, isTrue);
    });
  });

  group('filters', () {
    final index = ExerciseSearchIndex([
      exercise(
        '0001',
        'barbell bench press',
        bodyPart: BodyPart.chest,
        primaryMuscle: Muscle.chest,
        equipment: Equipment.barbell,
      ),
      exercise(
        '0002',
        'dumbbell bench press',
        bodyPart: BodyPart.chest,
        primaryMuscle: Muscle.chest,
        equipment: Equipment.dumbbell,
      ),
      exercise(
        '0003',
        'barbell squat',
        bodyPart: BodyPart.upperLegs,
        primaryMuscle: Muscle.quads,
        equipment: Equipment.barbell,
      ),
    ]);

    test('narrows by body part', () {
      final results = index.search('', filter: const ExerciseFilter(bodyPart: BodyPart.upperLegs));

      expect(idsOf(results), ['0003']);
    });

    test('narrows by primary muscle', () {
      final results = index.search('', filter: const ExerciseFilter(primaryMuscle: Muscle.chest));

      expect(idsOf(results), ['0001', '0002']);
    });

    test('narrows by equipment', () {
      final results = index.search('', filter: const ExerciseFilter(equipment: Equipment.barbell));

      expect(idsOf(results), ['0001', '0003']);
    });

    test('combines with the query rather than replacing it', () {
      final results = index.search(
        'barbell',
        filter: const ExerciseFilter(bodyPart: BodyPart.chest),
      );

      expect(idsOf(results), ['0001']);
    });

    test('filters compose with each other', () {
      final results = index.search(
        '',
        filter: const ExerciseFilter(bodyPart: BodyPart.chest, equipment: Equipment.dumbbell),
      );

      expect(idsOf(results), ['0002']);
    });

    test('narrows to favourites', () {
      final results = index.search(
        '',
        filter: const ExerciseFilter(favouritesOnly: true),
        favouriteIds: {'0003'},
      );

      expect(idsOf(results), ['0003']);
    });
  });

  group('duplicate names', () {
    test('flags only the exercises equipment cannot tell apart', () {
      // §5.4 says to append equipment. For the six upstream collisions that
      // does not work — both halves share it — so those fall back to the id.
      final index = ExerciseSearchIndex([
        exercise('0576', 'lever chest press', equipment: Equipment.leverageMachine),
        exercise('0577', 'lever chest press', equipment: Equipment.leverageMachine),
        exercise('0001', 'bench press', equipment: Equipment.barbell),
        exercise('0002', 'bench press', equipment: Equipment.dumbbell),
      ]);

      expect(index.needsIdSuffix(index.search('lever').first), isTrue);
      expect(index.needsIdSuffix(index.search('bench').first), isFalse);
    });
  });

  group('the real catalogue', () {
    late ExerciseSearchIndex index;

    setUpAll(() async {
      index = ExerciseSearchIndex(await BundledExerciseCatalog().load());
    });

    test('indexes all 1,295 exercises', () {
      expect(index.length, 1295);
    });

    test('finds the lifts a mesocycle is built from', () {
      expect(idsOf(index.search('barbell full squat')).first, '0043');
      expect(idsOf(index.search('barbell deadlift')).first, '0032');
      expect(idsOf(index.search('agachamento')).first, '0043');
      expect(idsOf(index.search('peso morto')).first, '0032');
    });

    test('answers in well under 100 ms across the whole catalogue', () {
      // F2's budget. Measured on the Dart VM in JIT, which is slower than the
      // AOT build on the device, so passing here is the conservative case.
      // Includes the fuzzy tier, which only runs when nothing matched outright
      // — 'zzzz' is the worst case the screen can produce.
      const queries = ['s', 'squat', 'barbell bench', 'agachamento', 'zzzz', 'sq bar'];

      for (final query in queries) {
        final stopwatch = Stopwatch()..start();
        index.search(query);
        stopwatch.stop();

        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(100),
          reason: '"$query" took ${stopwatch.elapsedMilliseconds} ms',
        );
      }
    });

    test('flags the six duplicated names §5.4 names, and two more it does not', () {
      final flagged = <String>{};
      for (final result in index.search('')) {
        if (index.needsIdSuffix(result)) flagged.add(result.name);
      }

      expect(flagged, containsAll(const [
        'barbell seated calf raise',
        'ez barbell spider curl',
        'lever chest press',
        'push-up (on stability ball)',
        'self assisted inverse leg curl',
        'smith reverse calf raises',
      ]));

      // §5.4 counted exact name matches. Two further pairs differ only in
      // punctuation — a hyphen and a pair of brackets — and are the same
      // exercise with the same equipment and the same instructions. A user
      // scanning a list cannot tell those apart either, so they are flagged
      // too: the collision test normalises the name rather than comparing it
      // raw.
      expect(flagged, containsAll(const [
        'dumbbell close grip press',
        'dumbbell close-grip press',
        'dumbbell standing one arm curl (over incline bench)',
        'dumbbell standing one arm curl over incline bench',
      ]));

      expect(flagged, hasLength(10), reason: 'eight pairs, two of which share a normalised name');
    });
  });
}
