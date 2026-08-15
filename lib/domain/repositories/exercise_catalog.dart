import 'package:mesa/domain/models/exercise.dart';

/// The 1,295 bundled exercises (§5.2, F2).
///
/// An interface even though the only implementation reads a local asset: it
/// keeps `rootBundle` out of the widget tests, and it is the same boundary
/// every other feature crosses to reach its data (§9).
///
/// Note what is *not* here — nothing takes a uid, and nothing writes. The
/// catalogue is static reference data shipped in the APK, which is what makes
/// browsing cost zero Firestore reads (NFR2) and work in aeroplane mode (F2).
abstract interface class ExerciseCatalog {
  /// Loads and parses the whole catalogue.
  ///
  /// Throws [CatalogFailure] if the asset is missing or malformed — both are
  /// build faults rather than anything the user can act on.
  Future<List<Exercise>> load();
}
