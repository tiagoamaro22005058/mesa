// §3/§4: Block and SetScheme.
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/domain/models/block.dart';
import 'package:mesa/domain/models/set_scheme.dart';

import '../../support/copy_with.dart';

void main() {
  Block build() => const Block(
    blockId: 'block-1',
    exerciseId: '0043',
    setScheme: SetScheme(sets: 4, repMin: 6, repMax: 8, rpeTarget: 8, restSec: 150),
    alternativeExerciseIds: ['0042'],
    notes: 'belt from set 3',
  );

  group('Block defaults', () {
    test('a catalogue exercise with nothing else set', () {
      const block = Block(blockId: 'block-1', exerciseId: '0043');

      expect(block.isCustom, isFalse);
      expect(block.alternativeExerciseIds, isEmpty);
      expect(block.notes, isNull);
      expect(block.setScheme, const SetScheme());
    });
  });

  group('Block.copyWith', () {
    test('covers every field', () {
      final block = build();

      expectCopyWithCoversEveryField(block, {
        'blockId': block.copyWith(blockId: 'block-2'),
        'exerciseId': block.copyWith(exerciseId: '0025'),
        'isCustom': block.copyWith(isCustom: true),
        'setScheme': block.copyWith(setScheme: const SetScheme(sets: 3)),
        'alternativeExerciseIds': block.copyWith(alternativeExerciseIds: const ['0063']),
        'notes': block.copyWith(notes: 'no belt'),
      });
    });

    test('clears the notes when passed null explicitly', () {
      // Deleting the note has to be expressible. A plain nullable parameter
      // would read the null as "leave it alone" and the note would be stuck.
      final updated = build().copyWith(notes: null);

      expect(updated.notes, isNull);
      expect(updated.exerciseId, '0043', reason: 'omitted, so unchanged');
    });

    test('changing nothing produces an equal block', () {
      expect(build().copyWith(), build());
    });
  });

  group('Block equality', () {
    test('compares the alternatives by value and in order', () {
      // Order is the user's preference ranking (F3), so two blocks holding the
      // same ids in a different order are not the same block.
      expect(
        build().copyWith(alternativeExerciseIds: const ['0042', '0063']),
        build().copyWith(alternativeExerciseIds: const ['0042', '0063']),
      );
      expect(
        build().copyWith(alternativeExerciseIds: const ['0042', '0063']),
        isNot(build().copyWith(alternativeExerciseIds: const ['0063', '0042'])),
      );
    });
  });

  group('SetScheme', () {
    test('defaults are §4\'s example', () {
      const scheme = SetScheme();

      expect(scheme.sets, 4);
      expect(scheme.repMin, 6);
      expect(scheme.repMax, 8);
      expect(scheme.rpeTarget, 8);
      expect(scheme.restSec, 150);
    });

    test('copyWith covers every field', () {
      const scheme = SetScheme();

      expectCopyWithCoversEveryField(scheme, {
        'sets': scheme.copyWith(sets: 3),
        'repMin': scheme.copyWith(repMin: 5),
        'repMax': scheme.copyWith(repMax: 12),
        'rpeTarget': scheme.copyWith(rpeTarget: 9.5),
        'restSec': scheme.copyWith(restSec: 90),
      });
    });

    test('a fixed rep count is a normal prescription', () {
      const scheme = SetScheme(repMin: 5, repMax: 5);

      expect(scheme.repMin, scheme.repMax);
    });
  });
}
