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
}
