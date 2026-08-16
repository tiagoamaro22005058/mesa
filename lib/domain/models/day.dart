import 'package:collection/collection.dart';
import 'package:mesa/domain/models/block.dart';

/// A day template within a [Program] — "Push", "Legs" — as an ordered list of
/// blocks (§3, §4).
///
/// Days are documents under `programs/{programId}/days`, so unlike [Block] they
/// keep a real [order] field: nothing else on the wire expresses their sequence.
/// Blocks are embedded here rather than in a subcollection because a day is read
/// as a unit and never exceeds a few KB (§4.1).
///
/// Carries no timestamps. §4 gives days none — the program document is what
/// stamps `updatedAt` for the whole aggregate.
class Day {
  const Day({
    required this.id,
    required this.name,
    required this.order,
    this.blocks = const [],
  });

  final String id;

  /// The user's own label. §4's example is `Push`.
  final String name;

  /// Position within the program, counted from zero. Rewritten across every
  /// affected day when the list is reordered.
  final int order;

  final List<Block> blocks;

  static const ListEquality<Block> _blocks = ListEquality<Block>();

  Day copyWith({String? id, String? name, int? order, List<Block>? blocks}) {
    return Day(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      blocks: blocks ?? this.blocks,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Day &&
      other.id == id &&
      other.name == name &&
      other.order == order &&
      _blocks.equals(other.blocks, blocks);

  @override
  int get hashCode => Object.hash(id, name, order, _blocks.hash(blocks));

  @override
  String toString() => 'Day($id: $name, order: $order, ${blocks.length} blocks)';
}
