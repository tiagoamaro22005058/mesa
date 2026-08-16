import 'package:mesa/domain/models/block.dart';
import 'package:mesa/domain/models/day.dart';
import 'package:mesa/domain/models/program.dart';
import 'package:mesa/domain/models/set_scheme.dart';
import 'package:mesa/domain/models/week_role.dart';

/// The clock the program builders default to, so two programs built in the same
/// test compare equal unless the test says otherwise.
final DateTime testNow = DateTime.utc(2026, 8, 16);

/// One program, with everything the test does not care about filled in.
///
/// Keeps the tests readable: an activation test says what the status is and
/// stays silent about mesocycle counters.
Program program(
  String id,
  String name, {
  String? goal,
  ProgramStatus status = ProgramStatus.draft,
  List<WeekRole> weekRoles = WeekRole.defaults,
  int currentMesocycle = 1,
  int currentWeekIndex = 0,
  int daysPerWeek = Program.defaultDaysPerWeek,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return Program(
    id: id,
    name: name,
    goal: goal,
    status: status,
    weekRoles: weekRoles,
    currentMesocycle: currentMesocycle,
    currentWeekIndex: currentWeekIndex,
    daysPerWeek: daysPerWeek,
    createdAt: createdAt ?? testNow,
    updatedAt: updatedAt ?? testNow,
  );
}

/// One day template.
Day day(
  String id,
  String name, {
  int order = 0,
  List<Block> blocks = const [],
}) {
  return Day(id: id, name: name, order: order, blocks: blocks);
}

/// One exercise slot.
Block block(
  String blockId,
  String exerciseId, {
  bool isCustom = false,
  SetScheme setScheme = const SetScheme(),
  List<String> alternativeExerciseIds = const [],
  String? notes,
}) {
  return Block(
    blockId: blockId,
    exerciseId: exerciseId,
    isCustom: isCustom,
    setScheme: setScheme,
    alternativeExerciseIds: alternativeExerciseIds,
    notes: notes,
  );
}
