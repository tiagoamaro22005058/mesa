/// Renders an upstream exercise name for the screen.
///
/// Upstream stores names lowercase (`barbell bench press`). §5.3 is explicit
/// that title-casing happens at render rather than at ingestion, so the stored
/// value stays exactly what upstream published and only the presentation
/// changes.
///
/// Capitalises the first letter of each whitespace-delimited word, leaving the
/// rest alone: `3/4 sit-up` → `3/4 Sit-up`, `push-up (on stability ball)` →
/// `Push-up (On Stability Ball)`. Hyphenated halves are deliberately not
/// capitalised — `Push-Up` reads worse than `Push-up`.
String exerciseTitle(String name) {
  return name
      .split(' ')
      .map((word) {
        for (var index = 0; index < word.length; index++) {
          final character = word[index];
          if (character.toUpperCase() != character.toLowerCase()) {
            return word.substring(0, index) +
                character.toUpperCase() +
                word.substring(index + 1);
          }
        }
        return word;
      })
      .join(' ');
}
