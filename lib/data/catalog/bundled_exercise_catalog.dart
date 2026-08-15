import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:mesa/core/constants/catalog_config.dart';
import 'package:mesa/core/failures/catalog_failure.dart';
import 'package:mesa/data/catalog/exercise_json.dart';
import 'package:mesa/domain/models/exercise.dart';
import 'package:mesa/domain/repositories/exercise_catalog.dart';

/// [ExerciseCatalog] backed by the JSON asset in the APK (§5.2).
///
/// No network, no Firestore, no database — this is the whole reason catalogue
/// browsing costs nothing and works in aeroplane mode (NFR1, NFR2, F2).
class BundledExerciseCatalog implements ExerciseCatalog {
  BundledExerciseCatalog({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<List<Exercise>> load() async {
    final String raw;
    try {
      raw = await _bundle.loadString(CatalogConfig.catalogAsset);
    } on Exception catch (error) {
      // A missing asset is a packaging fault: either pubspec.yaml lost its
      // `assets/catalog/` entry or the ingestion never ran.
      throw CatalogFailure(
        CatalogFailureKind.assetMissing,
        detail: '${CatalogConfig.catalogAsset}: $error',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw CatalogFailure(CatalogFailureKind.assetMalformed, detail: error.message);
    }

    if (decoded is! List) {
      throw CatalogFailure(
        CatalogFailureKind.assetMalformed,
        detail: 'expected an array of exercises, got ${decoded.runtimeType}',
      );
    }

    // Parsed on this isolate rather than through `compute`. The decode is
    // ~1.1 MB and costs tens of milliseconds once per app session, behind the
    // spinner on the catalogue screen; shipping 1,295 objects back across an
    // isolate boundary would cost as much again in copying. Cold start is
    // untouched either way — nothing loads the catalogue until the catalogue is
    // opened (NFR3).
    return [
      for (final record in decoded)
        if (record is Map<String, dynamic>)
          ExerciseJson.fromMap(record)
        else
          throw CatalogFailure(
            CatalogFailureKind.assetMalformed,
            detail: 'expected an object per exercise, got ${record.runtimeType}',
          ),
    ];
  }
}
