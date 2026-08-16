import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/core/ids.dart';

void main() {
  group('newId', () {
    test('never repeats, even minted in a tight loop', () {
      // The reason the counter exists. Duplicating a day mints a fresh id for
      // every block in it, and eight microsecond timestamps taken inside one
      // synchronous loop can land on the same value — which would give a day
      // two blocks sharing an id, and M4's SetLog.blockId no way to say which
      // one a set belonged to.
      final ids = {for (var i = 0; i < 1000; i++) newId('block')};

      expect(ids, hasLength(1000));
    });

    test('carries the prefix it was given', () {
      expect(newId('program'), startsWith('program-'));
      expect(newId('day'), startsWith('day-'));
    });

    test('does not look like a catalogue id', () {
      // Catalogue ids are upstream's and look like `0043`. An id that could be
      // mistaken for one would shadow a real exercise in a block lookup.
      expect(newId('block'), isNot(matches(RegExp(r'^\d+$'))));
    });
  });
}
