import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/app/bootstrap.dart';

void main() {
  group('firebaseOptionsFor', () {
    test('dev resolves to the dev Firebase project', () {
      expect(firebaseOptionsFor('dev').projectId, 'mesa-dev-4970c');
    });

    test('prod resolves to the prod Firebase project', () {
      expect(firebaseOptionsFor('prod').projectId, 'mesa-prod-c0ac6');
    });

    test('dev and prod are different projects', () {
      expect(
        firebaseOptionsFor('dev').projectId,
        isNot(firebaseOptionsFor('prod').projectId),
      );
    });

    test('an unflavoured build throws rather than guessing a project', () {
      expect(() => firebaseOptionsFor(null), throwsStateError);
      expect(() => firebaseOptionsFor('staging'), throwsStateError);
    });
  });
}
