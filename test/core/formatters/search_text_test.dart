import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/core/formatters/exercise_display.dart';
import 'package:mesa/core/formatters/search_text.dart';

void main() {
  group('normaliseForSearch', () {
    test('lowercases and strips punctuation', () {
      expect(normaliseForSearch('Push-Up (on Stability Ball)'), 'push up on stability ball');
      expect(normaliseForSearch('3/4 sit-up'), '3 4 sit up');
    });

    test('folds Portuguese accents away', () {
      // Nobody types `flexão` one-handed mid-set (§9.1, NFR7).
      expect(normaliseForSearch('flexão de braços'), 'flexao de bracos');
      expect(normaliseForSearch('AGACHAMENTO'), 'agachamento');
      expect(normaliseForSearch('elevação de gémeos'), 'elevacao de gemeos');
    });

    test('collapses runs of separators and trims', () {
      expect(normaliseForSearch('  sled   45°  leg press '), 'sled 45 leg press');
    });

    test('leaves characters outside the fold alone rather than dropping them', () {
      // Degrades to "does not match an accent-free query", never to a crash.
      expect(normaliseForSearch('приседания'), 'приседания');
    });

    test('the query and the indexed text normalise identically', () {
      // The whole reason there is one function: a search that normalises the
      // two differently silently stops matching.
      expect(normaliseForSearch('Bench-Press'), normaliseForSearch('bench press'));
    });
  });

  group('searchTokens', () {
    test('splits on the normalised separators', () {
      expect(searchTokens('Barbell Bench-Press'), ['barbell', 'bench', 'press']);
    });

    test('is empty for a string with nothing in it', () {
      expect(searchTokens('   '), isEmpty);
      expect(searchTokens('---'), isEmpty);
    });
  });

  group('exerciseTitle', () {
    test('title-cases at render, since upstream stores lowercase (§5.3)', () {
      expect(exerciseTitle('barbell bench press'), 'Barbell Bench Press');
    });

    test('leaves hyphenated halves alone', () {
      // `Push-Up` reads worse than `Push-up`.
      expect(exerciseTitle('push-up'), 'Push-up');
      expect(exerciseTitle('3/4 sit-up'), '3/4 Sit-up');
    });

    test('capitalises the first letter, not the first character', () {
      expect(exerciseTitle('push-up (on stability ball)'), 'Push-up (On Stability Ball)');
      expect(exerciseTitle('45° side bend'), '45° Side Bend');
    });

    test('leaves an already-capitalised name unchanged', () {
      expect(exerciseTitle('My Gym Press'), 'My Gym Press');
    });
  });
}
