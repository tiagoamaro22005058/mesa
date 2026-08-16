// §4/§4.1: the day document and the blocks embedded in it.
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/data/firestore/converters/day_converter.dart';
import 'package:mesa/domain/models/block.dart';
import 'package:mesa/domain/models/day.dart';
import 'package:mesa/domain/models/set_scheme.dart';

void main() {
  group('DayConverter', () {
    test('round-trips a day and its blocks', () {
      const original = Day(
        id: 'day-1',
        name: 'Push',
        order: 1,
        blocks: [
          Block(
            blockId: 'block-1',
            exerciseId: '0025',
            setScheme: SetScheme(sets: 4, repMin: 6, repMax: 8, rpeTarget: 8, restSec: 150),
            alternativeExerciseIds: ['0289', '0047'],
            notes: 'pause on the chest',
          ),
          Block(blockId: 'block-2', exerciseId: '0334', isCustom: true),
        ],
      );

      final restored = DayConverter.fromMap('day-1', DayConverter.toMap(original));

      expect(restored, original);
    });

    test('round-trips a day with no blocks', () {
      const original = Day(id: 'day-1', name: 'Push', order: 0);

      expect(DayConverter.fromMap('day-1', DayConverter.toMap(original)), original);
    });

    test('writes each block\'s order as its array position', () {
      // §4's shape keeps an `order` field. The app does not read it back as the
      // source of truth, but a document should still be readable without this
      // class, so it is written from the index rather than from a stored value
      // that could disagree with it.
      const day = Day(
        id: 'day-1',
        name: 'Push',
        order: 0,
        blocks: [
          Block(blockId: 'block-a', exerciseId: '0025'),
          Block(blockId: 'block-b', exerciseId: '0334'),
          Block(blockId: 'block-c', exerciseId: '0201'),
        ],
      );

      final blocks = (DayConverter.toMap(day)['blocks'] as List)
          .cast<Map<String, dynamic>>();

      expect(blocks.map((block) => block['order']), [0, 1, 2]);
      expect(blocks.map((block) => block['blockId']), ['block-a', 'block-b', 'block-c']);
    });

    test('reads blocks back in `order`, not in array order', () {
      // The case the two-places-for-one-fact problem produces: a document whose
      // array and `order` fields disagree. Sorting by `order` on read and
      // rewriting it from the index on save is what stops them diverging again.
      final restored = DayConverter.fromMap('day-1', {
        'name': 'Push',
        'order': 0,
        'blocks': [
          {'blockId': 'block-c', 'exerciseId': '0201', 'order': 2},
          {'blockId': 'block-a', 'exerciseId': '0025', 'order': 0},
          {'blockId': 'block-b', 'exerciseId': '0334', 'order': 1},
        ],
      });

      expect(restored.blocks.map((block) => block.blockId), [
        'block-a',
        'block-b',
        'block-c',
      ]);
    });

    test('falls back to array position when a block has no order', () {
      final restored = DayConverter.fromMap('day-1', {
        'blocks': [
          {'blockId': 'block-a', 'exerciseId': '0025'},
          {'blockId': 'block-b', 'exerciseId': '0334'},
        ],
      });

      expect(restored.blocks.map((block) => block.blockId), ['block-a', 'block-b']);
    });

    test('drops a block with no exercise rather than the whole day', () {
      // One corrupt block should cost that block, not the six around it.
      final restored = DayConverter.fromMap('day-1', {
        'name': 'Push',
        'blocks': [
          {'blockId': 'block-a', 'exerciseId': '0025', 'order': 0},
          {'blockId': 'block-b', 'order': 1},
          'not a block',
          {'blockId': 'block-c', 'exerciseId': '0201', 'order': 2},
        ],
      });

      expect(restored.name, 'Push');
      expect(restored.blocks.map((block) => block.blockId), ['block-a', 'block-c']);
    });

    test('falls back to a visible default rather than throwing', () {
      final restored = DayConverter.fromMap('day-1', {
        'name': 'Push',
        'order': 'second',
        'blocks': [
          {
            'blockId': 'block-a',
            'exerciseId': '0025',
            'setScheme': {'sets': 'four', 'repMin': 5},
            'alternativeExerciseIds': ['0289', 7, null],
          },
        ],
      });

      expect(restored.order, 0);
      final block = restored.blocks.single;
      expect(block.setScheme.sets, SetScheme.defaultSets);
      expect(block.setScheme.repMin, 5);
      expect(block.setScheme.repMax, SetScheme.defaultRepMax);
      expect(block.alternativeExerciseIds, ['0289']);
    });

    test('a block with no set scheme gets §4\'s example', () {
      final restored = DayConverter.fromMap('day-1', {
        'blocks': [
          {'blockId': 'block-a', 'exerciseId': '0025'},
        ],
      });

      expect(restored.blocks.single.setScheme, const SetScheme());
    });

    test('survives a document with almost nothing in it', () {
      final restored = DayConverter.fromMap('day-1', const {});

      expect(restored.id, 'day-1');
      expect(restored.name, '');
      expect(restored.order, 0);
      expect(restored.blocks, isEmpty);
    });

    test('keeps isCustom as written, defaulting to a catalogue exercise', () {
      final restored = DayConverter.fromMap('day-1', {
        'blocks': [
          {'blockId': 'a', 'exerciseId': 'custom-1', 'isCustom': true, 'order': 0},
          {'blockId': 'b', 'exerciseId': '0025', 'order': 1},
          {'blockId': 'c', 'exerciseId': '0043', 'isCustom': 'yes', 'order': 2},
        ],
      });

      expect(restored.blocks.map((block) => block.isCustom), [true, false, false]);
    });
  });
}
