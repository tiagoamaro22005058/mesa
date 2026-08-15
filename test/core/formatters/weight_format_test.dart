import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/core/formatters/weight_format.dart';
import 'package:mesa/domain/models/user_profile.dart';

void main() {
  group('formatWeight', () {
    test('drops the decimal from whole numbers', () {
      expect(formatWeight(20), '20');
      expect(formatWeight(2.0), '2');
    });

    test('keeps the fraction where there is one', () {
      expect(formatWeight(2.5), '2.5');
      expect(formatWeight(1.25), '1.25');
      expect(formatWeight(0.5), '0.5');
    });

    test('renders every plate in the default inventory cleanly', () {
      final rendered = UserProfile.defaultPlateInventory.map(formatWeight);

      expect(rendered, ['25', '20', '15', '10', '5', '2.5', '1.25']);
    });
  });

  group('parseWeight', () {
    test('accepts a dot separator', () {
      expect(parseWeight('17.5'), 17.5);
      expect(parseWeight('20'), 20);
    });

    test('accepts a comma separator', () {
      // The Portuguese keyboard offers a comma where Dart's parser wants a dot
      // (§9.1). Refusing it would read as the app being broken.
      expect(parseWeight('17,5'), 17.5);
      expect(parseWeight('1,25'), 1.25);
    });

    test('ignores surrounding whitespace', () {
      expect(parseWeight('  17,5  '), 17.5);
    });

    test('returns null for anything that is not a number', () {
      expect(parseWeight(null), isNull);
      expect(parseWeight(''), isNull);
      expect(parseWeight('   '), isNull);
      expect(parseWeight('heavy'), isNull);
      expect(parseWeight('17,5,0'), isNull);
    });

    test('round-trips whatever formatWeight produced', () {
      for (final plate in UserProfile.defaultPlateInventory) {
        expect(parseWeight(formatWeight(plate)), plate);
      }
    });
  });
}
