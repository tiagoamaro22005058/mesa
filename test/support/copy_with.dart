import 'package:flutter_test/flutter_test.dart';

/// Holds a hand-written `copyWith` / `==` / `hashCode` to covering every field.
///
/// **This is the freezed replacement.** §2 dropped codegen for `domain/models/`
/// and named the hazard that decision leaves behind: on nested, heavily edited
/// models, "a `copyWith` that silently forgets a field is a real and invisible
/// bug". M3 is where the models stopped being two flat classes, so the hazard
/// stopped being theoretical and needed a guard.
///
/// Give it an [original] and a table of *field name → a copy of [original] made
/// by `copyWith`, changing only that field to a different value*. For each entry
/// it asserts the copy differs from the original, which fails in three separate
/// ways:
///
/// - `copyWith` never wired the field through, so the copy came back unchanged;
/// - `==` does not compare the field, so a real change reads as equal;
/// - `hashCode` does not mix the field in, so two unequal values collide.
///
/// **What it cannot catch**, stated plainly rather than left to be discovered:
/// a field added to the class later whose entry is never added to the table.
/// Flutter has no reflection to enumerate fields with, so nothing short of
/// codegen closes that gap. This is a guard, not a proof — adding a field to a
/// model means adding a line here in the same edit.
void expectCopyWithCoversEveryField<T>(T original, Map<String, T> mutations) {
  for (final MapEntry(key: field, value: mutated) in mutations.entries) {
    expect(
      mutated,
      isNot(original),
      reason:
          'copyWith($field: ...) produced a value equal to the original. '
          'Either copyWith drops $field, or == does not compare it.',
    );
    expect(
      mutated.hashCode,
      isNot(original.hashCode),
      reason: 'hashCode does not mix in $field.',
    );
  }
}
