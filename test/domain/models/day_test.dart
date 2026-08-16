// §3/§4: Day.
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/domain/models/block.dart';
import 'package:mesa/domain/models/day.dart';

import '../../support/copy_with.dart';

void main() {
  const squat = Block(blockId: 'block-1', exerciseId: '0043');
  const legPress = Block(blockId: 'block-2', exerciseId: '0585');

  Day build() => const Day(id: 'day-1', name: 'Legs', order: 0, blocks: [squat]);

  group('Day defaults', () {
    test('a day starts with no blocks', () {
      expect(const Day(id: 'day-1', name: 'Legs', order: 0).blocks, isEmpty);
    });
  });

  group('Day.copyWith', () {
    test('covers every field', () {
      final day = build();

      expectCopyWithCoversEveryField(day, {
        'id': day.copyWith(id: 'day-2'),
        'name': day.copyWith(name: 'Push'),
        'order': day.copyWith(order: 1),
        'blocks': day.copyWith(blocks: const [legPress]),
      });
    });

    test('changing nothing produces an equal day', () {
      expect(build().copyWith(), build());
    });
  });

  group('Day equality', () {
    test('compares blocks by value, not by identity', () {
      // A day read back from Firestore holds different Block objects with the
      // same contents; comparing by identity would call every reload a change.
      expect(
        build().copyWith(blocks: const [squat, legPress]),
        build().copyWith(blocks: const [squat, legPress]),
      );
    });

    test('block order is part of the day', () {
      // Position in this list *is* the block order — §4's `order` field is
      // written but never read back as the source of truth. If reordering did
      // not change the day, nothing would persist a drag.
      expect(
        build().copyWith(blocks: const [squat, legPress]),
        isNot(build().copyWith(blocks: const [legPress, squat])),
      );
    });
  });
}
