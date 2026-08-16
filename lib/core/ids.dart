/// Monotonic within the process, so ids minted in the same microsecond differ.
int _sequence = 0;

/// A new document or block id, prefixed with what it identifies.
///
/// The counter is what makes this safe in a loop. Duplicating a day mints a
/// fresh id for every block in it, and eight `DateTime.now().microsecondsSinceEpoch`
/// calls inside one synchronous loop can land on the same value — which would
/// give a day two blocks sharing an id, and M4's `SetLog.blockId` no way to say
/// which one a set belonged to.
///
/// Not a UUID: there is no `uuid` package in the deps, ids only have to be
/// unique within one user's own subtree, and a timestamped id sorts by creation
/// which is occasionally useful when reading raw documents.
String newId(String prefix) =>
    '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';
