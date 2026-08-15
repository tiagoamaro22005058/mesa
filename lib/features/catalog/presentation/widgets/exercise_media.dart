import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mesa/core/constants/catalog_config.dart';
import 'package:mesa/l10n/app_localizations.dart';

/// An exercise thumbnail or animation, loaded remotely and cached (§5.1).
///
/// Never bundled and never re-hosted: the images are © Gym visual, not MIT.
/// Every media request in the app goes through here, so
/// [CatalogConfig.mediaEnabled] is the single switch that turns them all off.
///
/// **A missing image is not an error.** NFR1 says no screen shows an error
/// because the network is absent, and media is the one thing in the catalogue
/// that genuinely needs it — so an unreachable image degrades to a placeholder
/// and the rest of the screen carries on.
class ExerciseMedia extends StatelessWidget {
  const ExerciseMedia({
    required this.url,
    this.size,
    this.borderRadius = 8,
    super.key,
  });

  final String? url;

  /// Square when given, fills its parent's width when not.
  final double? size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final resolved = url;
    final placeholder = _Placeholder(size: size, borderRadius: borderRadius);

    if (!CatalogConfig.mediaEnabled || resolved == null || resolved.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: resolved,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => placeholder,
        errorWidget: (context, url, error) => placeholder,
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.size, required this.borderRadius});

  final double? size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colours = Theme.of(context).colorScheme;

    return Semantics(
      label: AppLocalizations.of(context)!.exerciseMediaUnavailable,
      child: Container(
        width: size,
        height: size ?? 180,
        decoration: BoxDecoration(
          color: colours.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Icon(
          Icons.fitness_center,
          size: size == null ? 48 : size! * 0.5,
          color: colours.onSurfaceVariant,
        ),
      ),
    );
  }
}
