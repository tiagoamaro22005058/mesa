import 'package:mesa/domain/models/block.dart';
import 'package:mesa/domain/models/day.dart';
import 'package:mesa/domain/models/set_scheme.dart';

/// Maps `users/{uid}/programs/{programId}/days/{dayId}` (§4) to and from [Day],
/// including the blocks embedded in it (§4.1).
///
/// Tolerant on read, like every other converter here (§4.3 validates nothing).
///
/// **This converter owns the block `order` field.** §4 stores an `order` on
/// each block *and* keeps them in an array, which is the same fact twice.
/// [Block] therefore has no `order` of its own: [fromMap] sorts by the stored
/// value and then discards it, and [toMap] writes the array index back. The
/// document shape §4 specifies is unchanged — what changes is that the app can
/// no longer read an array and an `order` that disagree.
abstract final class DayConverter {
  static Day fromMap(String id, Map<String, dynamic> data) {
    return Day(
      id: id,
      name: _string(data['name']) ?? '',
      order: _int(data['order']) ?? 0,
      blocks: _blocks(data['blocks']),
    );
  }

  static Map<String, dynamic> toMap(Day day) {
    return <String, dynamic>{
      'name': day.name,
      'order': day.order,
      'blocks': [
        for (final (index, block) in day.blocks.indexed)
          <String, dynamic>{
            'blockId': block.blockId,
            'exerciseId': block.exerciseId,
            'isCustom': block.isCustom,
            // Position in the array, always. Written because §4's shape has it
            // and a document should be readable without this class.
            'order': index,
            'setScheme': <String, dynamic>{
              'sets': block.setScheme.sets,
              'repMin': block.setScheme.repMin,
              'repMax': block.setScheme.repMax,
              'rpeTarget': block.setScheme.rpeTarget,
              'restSec': block.setScheme.restSec,
            },
            'alternativeExerciseIds': block.alternativeExerciseIds,
            'notes': block.notes,
          },
      ],
    };
  }

  /// A block with no `exerciseId` resolves to nothing and is dropped, rather
  /// than taking the whole day down with it — one corrupt block should cost
  /// that block, not the six around it.
  static List<Block> _blocks(Object? value) {
    if (value is! List) return const [];

    final entries = <(int, Block)>[];
    for (final (index, entry) in value.indexed) {
      if (entry is! Map) continue;
      final exerciseId = _string(entry['exerciseId']);
      if (exerciseId == null) continue;

      entries.add((
        // Falls back to the array position when `order` is missing, so a
        // document written by something that did not store it still reads in
        // the order it was written.
        _int(entry['order']) ?? index,
        Block(
          blockId: _string(entry['blockId']) ?? 'block-$index',
          exerciseId: exerciseId,
          isCustom: entry['isCustom'] == true,
          setScheme: _setScheme(entry['setScheme']),
          alternativeExerciseIds: _stringList(entry['alternativeExerciseIds']),
          notes: _string(entry['notes']),
        ),
      ));
    }

    // Sorted here and then thrown away: from this point the list position is
    // the order, and `order` is only ever written again by toMap.
    entries.sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final (_, block) in entries) block];
  }

  static SetScheme _setScheme(Object? value) {
    if (value is! Map) return const SetScheme();

    return SetScheme(
      sets: _int(value['sets']) ?? SetScheme.defaultSets,
      repMin: _int(value['repMin']) ?? SetScheme.defaultRepMin,
      repMax: _int(value['repMax']) ?? SetScheme.defaultRepMax,
      rpeTarget: _double(value['rpeTarget']) ?? SetScheme.defaultRpeTarget,
      restSec: _int(value['restSec']) ?? SetScheme.defaultRestSec,
    );
  }

  static String? _string(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return value;
  }

  /// Drops anything that is not a string rather than rejecting the whole list:
  /// one malformed alternative should cost that alternative, not all of them.
  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is String && item.isNotEmpty) item,
    ];
  }

  /// Firestore hands back `int` for whole numbers written as doubles, so every
  /// numeric read has to widen rather than cast.
  static double? _double(Object? value) => value is num ? value.toDouble() : null;

  static int? _int(Object? value) => value is num ? value.toInt() : null;
}
