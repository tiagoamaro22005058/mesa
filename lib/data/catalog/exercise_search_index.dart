import 'package:mesa/core/formatters/search_text.dart';
import 'package:mesa/domain/models/exercise.dart';
import 'package:mesa/domain/models/exercise_filter.dart';

/// Fuzzy search and filtering over the merged catalogue (F2).
///
/// Built once from the 1,295 bundled exercises plus whatever custom ones the
/// user owns, and rebuilt when the custom list changes. Everything that can be
/// precomputed is: normalising 1,295 names on every keystroke is what makes a
/// search box feel broken.
///
/// A scored linear scan rather than an inverted index. At this size it clears
/// F2's sub-100 ms budget by two orders of magnitude — the whole catalogue fits
/// in a few hundred KB of normalised strings — and a trigram index would be
/// more code, more state and more ways to be subtly wrong for no measurable
/// gain. If the catalogue ever grows by a factor of fifty, revisit.
class ExerciseSearchIndex {
  ExerciseSearchIndex(List<Exercise> exercises)
    : _entries = List.unmodifiable(exercises.map(_IndexEntry.new)),
      _ambiguousIds = _findAmbiguous(exercises);

  final List<_IndexEntry> _entries;
  final Set<String> _ambiguousIds;

  int get length => _entries.length;

  /// Exercises matching [query] and [filter], best match first.
  ///
  /// An empty query is not an empty result: it is the whole catalogue in
  /// alphabetical order, which is what makes the screen useful before anything
  /// is typed.
  List<Exercise> search(
    String query, {
    ExerciseFilter filter = ExerciseFilter.none,
    Set<String> favouriteIds = const {},
  }) {
    final candidates = _entries.where((entry) => _matchesFilter(entry, filter, favouriteIds));
    final normalisedQuery = normaliseForSearch(query);

    if (normalisedQuery.isEmpty) {
      final all = candidates.map((entry) => entry.exercise).toList();
      all.sort((a, b) => a.name.compareTo(b.name));
      return all;
    }

    final queryTokens = normalisedQuery.split(' ');
    final scored = <_Scored>[];
    for (final entry in candidates) {
      final score = entry.score(normalisedQuery, queryTokens);
      if (score > 0) scored.add(_Scored(entry.exercise, score));
    }

    // The typo pass runs only when nothing matched outright. It is the
    // expensive tier — an edit distance per token pair — and paying for it on
    // every keystroke to improve results nobody was going to look at is how a
    // search box ends up janky.
    if (scored.isEmpty) {
      for (final entry in candidates) {
        final score = entry.fuzzyScore(queryTokens);
        if (score > 0) scored.add(_Scored(entry.exercise, score));
      }
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      // Shorter names first: searching "squat" should surface "barbell full
      // squat" above "barbell full squat to a bench with band".
      final byLength = a.exercise.name.length.compareTo(b.exercise.name.length);
      if (byLength != 0) return byLength;
      return a.exercise.name.compareTo(b.exercise.name);
    });

    return [for (final result in scored) result.exercise];
  }

  /// Whether this exercise's name collides with another that has the same
  /// equipment, so the screen has to say which one it is.
  ///
  /// §5.4 says to disambiguate the six duplicated names by appending equipment.
  /// That does not work: all six pairs share their equipment, primary muscle
  /// and body part, differing only in id, media and — twice — a reworded step.
  /// Equipment is shown on every row regardless, so the six that remain
  /// genuinely ambiguous fall back to the upstream id, which is the only thing
  /// that actually tells them apart.
  bool needsIdSuffix(Exercise exercise) => _ambiguousIds.contains(exercise.id);

  static Set<String> _findAmbiguous(List<Exercise> exercises) {
    final byKey = <String, List<String>>{};
    for (final exercise in exercises) {
      final key = '${normaliseForSearch(exercise.name)}|${exercise.equipment.wireValue}';
      byKey.putIfAbsent(key, () => []).add(exercise.id);
    }
    return {
      for (final ids in byKey.values)
        if (ids.length > 1) ...ids,
    };
  }

  bool _matchesFilter(_IndexEntry entry, ExerciseFilter filter, Set<String> favouriteIds) {
    final exercise = entry.exercise;
    if (filter.bodyPart != null && exercise.bodyPart != filter.bodyPart) return false;
    if (filter.primaryMuscle != null && exercise.primaryMuscle != filter.primaryMuscle) return false;
    if (filter.equipment != null && exercise.equipment != filter.equipment) return false;
    if (filter.favouritesOnly && !favouriteIds.contains(exercise.id)) return false;
    return true;
  }
}

class _Scored {
  const _Scored(this.exercise, this.score);

  final Exercise exercise;
  final int score;
}

/// One exercise with its searchable text precomputed.
class _IndexEntry {
  _IndexEntry(this.exercise)
    : name = normaliseForSearch(exercise.name),
      nameTokens = searchTokens(exercise.name),
      aliases = [for (final alias in exercise.aliases) normaliseForSearch(alias)],
      aliasTokens = [for (final alias in exercise.aliases) ...searchTokens(alias)];

  final Exercise exercise;
  final String name;
  final List<String> nameTokens;
  final List<String> aliases;
  final List<String> aliasTokens;

  /// Tiers, highest first. The ordering is the whole design: someone who types
  /// the exact name wants that exercise, not the forty whose names contain it.
  int score(String query, List<String> queryTokens) {
    if (name == query) return 1000;
    if (aliases.contains(query)) return 900;
    if (name.startsWith(query)) return 800;
    if (aliases.any((alias) => alias.startsWith(query))) return 700;
    if (name.contains(query)) return 600;
    if (aliases.any((alias) => alias.contains(query))) return 500;

    // Every word typed has to match the start of some word in the name or an
    // alias. This is what makes "bb bench" find "barbell bench press" and, more
    // to the point, what makes word order not matter.
    if (queryTokens.every(_matchesTokenPrefix)) return 400;
    return 0;
  }

  /// One typo per word, for words long enough that a typo is likelier than a
  /// deliberate abbreviation. `squt` finds squats; `bb` is left to the prefix
  /// tier, where it belongs.
  int fuzzyScore(List<String> queryTokens) {
    if (!queryTokens.every(_matchesApproximately)) return 0;
    return 200;
  }

  bool _matchesTokenPrefix(String token) =>
      nameTokens.any((candidate) => candidate.startsWith(token)) ||
      aliasTokens.any((candidate) => candidate.startsWith(token));

  bool _matchesApproximately(String token) {
    if (_matchesTokenPrefix(token)) return true;
    if (token.length < 4) return false;
    final allowed = token.length >= 7 ? 2 : 1;
    return nameTokens.any((candidate) => _withinEditDistance(token, candidate, allowed)) ||
        aliasTokens.any((candidate) => _withinEditDistance(token, candidate, allowed));
  }
}

/// Levenshtein distance, abandoned as soon as it exceeds [max].
///
/// Two rows rather than a full matrix, and a length check first: the vast
/// majority of pairs differ in length by more than [max] and cost nothing.
bool _withinEditDistance(String a, String b, int max) {
  if ((a.length - b.length).abs() > max) return false;
  if (a == b) return true;

  var previous = List<int>.generate(b.length + 1, (index) => index);
  var current = List<int>.filled(b.length + 1, 0);

  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    var best = current[0];
    for (var j = 1; j <= b.length; j++) {
      final substitution = previous[j - 1] + (a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1);
      final deletion = previous[j] + 1;
      final insertion = current[j - 1] + 1;
      current[j] = substitution < deletion
          ? (substitution < insertion ? substitution : insertion)
          : (deletion < insertion ? deletion : insertion);
      if (current[j] < best) best = current[j];
    }
    // Nothing in this row is close enough, and rows only ever grow.
    if (best > max) return false;
    final swap = previous;
    previous = current;
    current = swap;
  }

  return previous[b.length] <= max;
}
