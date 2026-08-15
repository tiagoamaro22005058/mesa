/// The ways the bundled catalogue can fail to load.
///
/// A sibling of `AuthFailure`, same shape and same rules (§9.1): a closed set
/// of app-level kinds, translated once at the `data/` boundary, never a raw
/// exception rendered on screen.
///
/// Every one of these is a build or packaging fault rather than something the
/// user did — the asset is committed and validated by
/// `tools/build_catalog/build.py`, and it either shipped correctly or it did
/// not. That is precisely why they are worth naming: the failure will happen on
/// a device, once, and the message has to be enough to identify which of the
/// three went wrong.
enum CatalogFailureKind {
  /// The asset is not in the bundle. A missing `assets/catalog/` entry in
  /// `pubspec.yaml`, or a build that never ran the ingestion.
  assetMissing,

  /// The asset is present but is not the JSON this app expects.
  assetMalformed,

  /// A record carries a muscle, body part, equipment or load model this build
  /// has no enum member for — the mapping tables got ahead of the Dart enums.
  unknownValue,
}

final class CatalogFailure implements Exception {
  const CatalogFailure(this.kind, {this.detail});

  final CatalogFailureKind kind;

  /// What exactly was wrong — the offending value, or the underlying decoder's
  /// message. Never shown on screen; it exists so a bug report is actionable.
  final String? detail;

  @override
  String toString() =>
      detail == null ? 'CatalogFailure(${kind.name})' : 'CatalogFailure(${kind.name}): $detail';

  @override
  bool operator ==(Object other) =>
      other is CatalogFailure && other.kind == kind && other.detail == detail;

  @override
  int get hashCode => Object.hash(kind, detail);
}
