/// Text normalisation for catalogue search (F2, §9.1).
///
/// One implementation, used by both the index and the query, because a search
/// that normalises the two differently silently stops matching.
///
/// Accents are stripped rather than respected: the aliases are Portuguese and
/// nobody types `flexão` one-handed mid-set — they type `flexao`. Dart has no
/// Unicode decomposition in the core library, so the fold is a table. It covers
/// Latin-1 plus the characters Portuguese, Spanish and the dataset itself
/// actually use; anything outside it passes through unchanged, which degrades
/// to "does not match an accent-free query" rather than to a crash.
library;

const Map<String, String> _foldedCharacters = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n', 'ý': 'y', 'ÿ': 'y',
};

/// Anything that is neither a letter nor a digit, in any script.
///
/// Unicode-aware rather than `[^a-z0-9]`: stripping every non-Latin character
/// would normalise a name written in another script to the empty string, and an
/// exercise that normalises to nothing can never be found. Custom exercise
/// names are user-typed, so that is a real input rather than a hypothetical.
final RegExp _separators = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// Lowercases, strips accents, and reduces everything else to single spaces.
///
/// `Push-Up (on Stability Ball)` and `push up on stability ball` normalise to
/// the same string, which is what makes punctuation invisible to search.
String normaliseForSearch(String value) {
  final buffer = StringBuffer();
  for (final character in value.toLowerCase().split('')) {
    buffer.write(_foldedCharacters[character] ?? character);
  }
  return buffer.toString().replaceAll(_separators, ' ').trim();
}

/// The normalised words of [value], in order, with empties dropped.
List<String> searchTokens(String value) {
  final normalised = normaliseForSearch(value);
  return normalised.isEmpty ? const [] : normalised.split(' ');
}
