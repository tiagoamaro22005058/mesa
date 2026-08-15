import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:mesa/core/constants/catalog_config.dart';
import 'package:mesa/data/catalog/bundled_exercise_catalog.dart';
import 'package:mesa/domain/models/equipment.dart';
import 'package:mesa/domain/models/exercise.dart';
import 'package:mesa/domain/models/muscle.dart';

/// The committed catalogue asset, parsed by the code that will parse it on the
/// device (§5.2, §5.6).
///
/// This is the test that catches the failure mode the Python side cannot: the
/// ingestion tables and the Dart enums drifting apart. `build.py` guarantees
/// the asset is internally consistent; only this proves the app agrees with it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Exercise> catalogue;

  setUpAll(() async {
    catalogue = await BundledExerciseCatalog().load();
  });

  test('holds the 1,295 exercises §5.2 specifies', () {
    // 1,324 upstream records less the 29 cardio ones. A different number means
    // either the exclusion rule or the dataset changed, and both are worth
    // noticing deliberately rather than in a screenshot.
    expect(catalogue, hasLength(1295));
  });

  test('parses every record without an unknown value', () {
    // load() throws CatalogFailure on the first unmapped value, so reaching
    // here at all is the assertion. Stated explicitly so a future reader knows
    // the coverage is the whole file, not a sample.
    expect(catalogue.every((e) => e.id.isNotEmpty && e.name.isNotEmpty), isTrue);
  });

  test('ids are unique', () {
    expect(catalogue.map((e) => e.id).toSet(), hasLength(catalogue.length));
  });

  test("every record's load model matches what its equipment derives", () {
    // The Python mapping table and Equipment.defaultLoadModel are two
    // statements of the same rule (§5.6). This holds them together — without
    // it, editing one and not the other would give catalogue exercises a load
    // model that user-created ones with the same equipment do not get.
    final drifted = catalogue
        .where((e) => e.loadModel != e.equipment.defaultLoadModel)
        // Ingestion assigns these two directly: a sledge hammer and a tire flip
        // are externally loaded even though `other` defaults to bodyweight.
        .where((e) => e.equipment != Equipment.other)
        .toList();

    expect(drifted, isEmpty, reason: 'load model drifted from equipment: $drifted');
  });

  test('the primary muscle never repeats in the secondary list', () {
    // After synonym collapse a record can carry the same muscle twice, which
    // would double-count it in M6's per-muscle volume.
    final duplicated = catalogue.where((e) => e.secondaryMuscles.contains(e.primaryMuscle));

    expect(duplicated, isEmpty);
  });

  test('secondary muscles hold no duplicates', () {
    final duplicated = catalogue.where(
      (e) => e.secondaryMuscles.toSet().length != e.secondaryMuscles.length,
    );

    expect(duplicated, isEmpty);
  });

  test('every record has instruction steps and an attribution', () {
    // §5.1 makes the attribution string a licence obligation, not a nicety.
    expect(catalogue.every((e) => e.steps.isNotEmpty), isTrue);
    expect(catalogue.every((e) => (e.attribution ?? '').isNotEmpty), isTrue);
  });

  test('media URLs resolve against the pinned upstream commit', () {
    final squat = catalogue.firstWhere((e) => e.id == '0043');

    expect(squat.thumbnailUrl, startsWith(CatalogConfig.mediaBaseUrl));
    expect(squat.thumbnailUrl, contains(CatalogConfig.sourceCommit));
    expect(squat.gifUrl, endsWith('.gif'));
  });

  test('the pinned commit matches the one the asset was generated from', () async {
    // Media comes from a revision of the upstream repo; the data comes from a
    // revision of the upstream repo. If those stop being the same revision, the
    // app shows one exercise's name over another's animation, and nothing else
    // would ever catch it.
    final version = jsonDecode(await rootBundle.loadString(CatalogConfig.versionAsset));

    expect(version['sourceCommit'], CatalogConfig.sourceCommit);
    expect(version['count'], catalogue.length);
  });

  test('no cardio survived ingestion', () {
    // A1 was rejected: this app logs lifting only. Cardio has no body part left
    // to land in, so its absence shows as the muscle it used to target.
    expect(catalogue.any((e) => e.primaryMuscle == Muscle.other && e.steps.isEmpty), isFalse);
    expect(catalogue.map((e) => e.name), isNot(contains('walking on treadmill')));
  });

  test('the deltoid heads only appear where the override put them', () {
    // delt_heads.json is empty, so the dataset's undifferentiated `delts` is
    // all there is — except rear delts, which upstream does name, and which the
    // rotator-cuff exercises map onto. If this starts failing, someone filled
    // in the override table, which is exactly what it is for.
    final primaries = catalogue.map((e) => e.primaryMuscle).toSet();

    expect(primaries, contains(Muscle.delts));
    expect(primaries, isNot(contains(Muscle.frontDelts)));
    expect(primaries, isNot(contains(Muscle.sideDelts)));
  });

  test('the Portuguese aliases reach the exercises they were written for', () {
    final squat = catalogue.firstWhere((e) => e.id == '0043');
    final benchPress = catalogue.firstWhere((e) => e.id == '0025');

    expect(squat.aliases, contains('agachamento livre'));
    expect(benchPress.aliases, contains('supino reto'));
  });

  test('the mis-encoded upstream names were repaired', () {
    // Four records arrive with `в°` where `°` belongs. Left alone they reach
    // the screen that way.
    final broken = catalogue.where((e) => e.name.contains('в'));

    expect(broken, isEmpty);
    expect(catalogue.firstWhere((e) => e.id == '0739').name, 'sled 45° leg press');
  });
}
