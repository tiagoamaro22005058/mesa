/// Where the bundled catalogue and its media come from (§5).
abstract final class CatalogConfig {
  /// The upstream commit the vendored dataset was built from.
  ///
  /// Must match `tools/build_catalog/SOURCE_COMMIT` and the `sourceCommit` in
  /// `assets/catalog/version.json` — a test holds all three together. If they
  /// drift, the app requests media for exercises from a different revision of
  /// the dataset than the one it is showing.
  static const String sourceCommit = '7455efae41b330c265e7cd4b78dfa848e7ce5ebd';

  /// Media loads from here on demand and is cached on device (§5.1).
  ///
  /// Pinned to [sourceCommit] rather than a branch, for the same reason the
  /// dataset is: an upstream force-push must not silently change what the app
  /// displays.
  static const String mediaBaseUrl =
      'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/$sourceCommit/';

  /// Whether exercise thumbnails and GIFs are fetched at all.
  ///
  /// A hardcoded `true`, deliberately not a build flag (§5.1, §12.1). The app
  /// is not distributed — it runs on the owner's own device, which is personal
  /// use rather than redistribution, so there is nothing for a flag to switch
  /// between.
  ///
  /// **Before distributing this app, read §5.1.** The moment it reaches anyone
  /// else's device — the Play Store, an internal testing track, a shared APK —
  /// the thumbnails and GIFs stop being personal use and Gym visual's terms
  /// apply. At that point either obtain a media licence or set this to `false`
  /// and ship without images. Every media request in the app goes through this
  /// constant, which is what keeps that a one-line change; that is its whole
  /// remaining purpose.
  static const bool mediaEnabled = true;

  static const String catalogAsset = 'assets/catalog/exercises.json';
  static const String versionAsset = 'assets/catalog/version.json';

  /// Turns a stored relative media path into a URL.
  ///
  /// The asset stores `images/0001-2gPfomN.jpg` rather than the full URL:
  /// baking the base in would add ~230 KB to the APK and pin the host into
  /// data that is meant to outlive it.
  static String? mediaUrl(String? relativePath) {
    if (!mediaEnabled || relativePath == null || relativePath.isEmpty) return null;
    return '$mediaBaseUrl$relativePath';
  }
}
