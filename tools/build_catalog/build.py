#!/usr/bin/env python3
"""Builds `assets/catalog/` from the vendored upstream dataset (§5.7).

Reads a pinned copy of hasaneyldrm/exercises-dataset, normalises it against the
tables in `mappings/`, drops cardio, derives a load model per exercise, and
writes `exercises.json` and `version.json`. The output is committed, so a build
never needs the network and never depends on what upstream did today.

The rule that matters: **nothing free-text survives**. Every muscle string,
every equipment string and every body part must be present in a table. Anything
absent aborts the run and is written to `unmapped.json` — silent pass-through is
exactly how synonym drift reaches the database (§5.4).

Usage:

    python3 tools/build_catalog/build.py            # regenerate the assets
    python3 tools/build_catalog/build.py --check    # verify the committed assets

`--check` regenerates into a temporary directory and compares. It is what CI
runs, and it fails on three separate things: an unmapped value, a stale
committed asset, and a non-idempotent build.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
import tempfile
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

TOOL_DIR = Path(__file__).resolve().parent
REPO_ROOT = TOOL_DIR.parent.parent

ID_PATTERN = re.compile(r"^[0-9]{4}$")

# Fixed by the upstream schema's `body_part` enum, and a 1:1 transliteration
# rather than a mapping — there are no synonyms to resolve, so there is no table
# to review. An unrecognised value still fails the build.
BODY_PARTS = {
    "back": "back",
    "chest": "chest",
    "lower arms": "lower_arms",
    "lower legs": "lower_legs",
    "neck": "neck",
    "shoulders": "shoulders",
    "upper arms": "upper_arms",
    "upper legs": "upper_legs",
    "waist": "waist",
}

# §5.4: excluded outright. A1 was rejected — this app logs lifting only.
CARDIO_BODY_PART = "cardio"


class BuildError(Exception):
    """A failure the operator has to fix by hand, in a mapping table."""


def display_path(path: Path) -> str:
    """Repo-relative where that reads better, absolute otherwise (tests run in /tmp)."""
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def load_json(path: Path) -> dict | list:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as error:
        raise BuildError(f"missing input: {path}") from error
    except json.JSONDecodeError as error:
        raise BuildError(f"{path} is not valid JSON: {error}") from error


def validate_tables(muscles: dict, equipment: dict, delt_heads: dict) -> None:
    """Checks the tables against themselves before any record is read.

    A typo in a mapping target would otherwise invent a muscle that no Dart enum
    member matches, and the failure would surface much later as a parse error on
    a device.
    """
    canonical = set(muscles["canonical"])
    stray = {value for value in muscles["map"].values()} - canonical
    if stray:
        raise BuildError(f"muscles.json maps onto non-canonical values: {sorted(stray)}")

    unreachable = canonical - set(muscles["map"].values()) - set(delt_heads["allowed"])
    if unreachable:
        raise BuildError(
            f"muscles.json declares canonical values nothing can produce: {sorted(unreachable)}"
        )

    equipment_values = set(equipment["equipmentValues"])
    load_models = set(equipment["loadModelValues"])
    gym_tags = set(equipment["gymTagValues"])
    for upstream, mapped in equipment["map"].items():
        if mapped["equipment"] not in equipment_values:
            raise BuildError(f"equipment.json: {upstream!r} → unknown equipment {mapped['equipment']!r}")
        if mapped["loadModel"] not in load_models:
            raise BuildError(f"equipment.json: {upstream!r} → unknown loadModel {mapped['loadModel']!r}")
        if mapped["gymTag"] is not None and mapped["gymTag"] not in gym_tags:
            raise BuildError(f"equipment.json: {upstream!r} → unknown gymTag {mapped['gymTag']!r}")

    stray_heads = set(delt_heads["allowed"]) - canonical
    if stray_heads:
        raise BuildError(f"delt_heads.json allows non-canonical values: {sorted(stray_heads)}")


def collect_unmapped(records: list[dict], muscles: dict, equipment: dict) -> dict:
    """Every value with no table entry, with enough context to fix it.

    Collects all of them rather than aborting on the first: fixing a mapping
    table one failed build at a time is miserable, and the whole point of the
    report is that it tells you the size of the job.
    """
    report: dict[str, dict[str, dict]] = {"muscles": {}, "equipment": {}, "bodyPart": {}}
    counts: dict[str, Counter] = {key: Counter() for key in report}
    examples: dict[str, dict[str, list[str]]] = {key: defaultdict(list) for key in report}
    fields: dict[str, dict[str, set]] = {"muscles": defaultdict(set)}

    def note(kind: str, value: str, record: dict, field: str | None = None) -> None:
        counts[kind][value] += 1
        if len(examples[kind][value]) < 5:
            examples[kind][value].append(f"{record['id']} {record['name']}")
        if field is not None:
            fields[kind][value].add(field)

    muscle_map, equipment_map = muscles["map"], equipment["map"]
    for record in records:
        if record["body_part"] not in BODY_PARTS:
            note("bodyPart", record["body_part"], record)
        if record["equipment"] not in equipment_map:
            note("equipment", record["equipment"], record)
        if record["target"] not in muscle_map:
            note("muscles", record["target"], record, "target")
        if record["muscle_group"] not in muscle_map:
            note("muscles", record["muscle_group"], record, "muscle_group")
        for muscle in record["secondary_muscles"]:
            if muscle not in muscle_map:
                note("muscles", muscle, record, "secondary_muscles")

    for kind, counter in counts.items():
        for value, count in counter.most_common():
            entry: dict = {"count": count, "examples": examples[kind][value]}
            if kind in fields and value in fields[kind]:
                entry["upstreamFields"] = sorted(fields[kind][value])
            report[kind][value] = entry

    return report


def apply_name_fixes(records: list[dict], name_fixes: dict) -> None:
    """Rewrites the handful of upstream names that arrive mis-encoded."""
    by_id = {record["id"]: record for record in records}
    for exercise_id, fix in name_fixes["map"].items():
        record = by_id.get(exercise_id)
        if record is None:
            raise BuildError(f"name_fixes.json: id {exercise_id} is not in the catalogue")
        if record["name"] != fix["from"]:
            raise BuildError(
                f"name_fixes.json: id {exercise_id} reads {record['name']!r}, "
                f"not {fix['from']!r} — upstream changed, so re-check the fix"
            )
        record["name"] = fix["to"]


def normalise(record: dict, muscles: dict, equipment: dict) -> dict:
    """One upstream record → one internal Exercise (§5.3, §5.5)."""
    muscle_map = muscles["map"]
    mapped_equipment = equipment["map"][record["equipment"]]
    primary = muscle_map[record["target"]]

    # Deduplicated, and with the primary removed. Both are artefacts of the
    # synonym collapse rather than information: a record whose target is `delts`
    # and whose secondary list says `shoulders` would otherwise carry the same
    # muscle twice, and double-count in M6's per-muscle volume.
    secondary: list[str] = []
    for raw in record["secondary_muscles"]:
        mapped = muscle_map[raw]
        if mapped != primary and mapped not in secondary:
            secondary.append(mapped)

    synergist = muscle_map[record["muscle_group"]]

    return {
        "id": record["id"],
        # Upstream is lowercase throughout; §5.3 title-cases at render, not here.
        "name": record["name"],
        "aliases": [],
        "bodyPart": BODY_PARTS[record["body_part"]],
        "primaryMuscle": primary,
        "synergist": synergist,
        "secondaryMuscles": secondary,
        "equipment": mapped_equipment["equipment"],
        "gymTag": mapped_equipment["gymTag"],
        "loadModel": mapped_equipment["loadModel"],
        "steps": list(record["instruction_steps"]["en"]),
        # Relative, deliberately. The loader prefixes them with the pinned raw
        # base URL — baking absolute URLs in would add ~230 KB to the APK and
        # pin the host into the data (§5.1).
        "thumbnailUrl": record["image"],
        "gifUrl": record["gif_url"],
        "attribution": record["attribution"],
    }


def apply_delt_heads(exercises: list[dict], delt_heads: dict) -> None:
    """Applies the hand-maintained deltoid-head overrides (§5.4).

    `primaryMuscle` only. A single head per exercise cannot honestly describe
    both the primary and the synergist of a press, so the synergist and
    secondary entries keep the generic `delts`.
    """
    allowed = set(delt_heads["allowed"])
    by_id = {exercise["id"]: exercise for exercise in exercises}
    for exercise_id, head in delt_heads["map"].items():
        exercise = by_id.get(exercise_id)
        if exercise is None:
            raise BuildError(f"delt_heads.json: id {exercise_id} is not in the catalogue")
        if head not in allowed:
            raise BuildError(f"delt_heads.json: id {exercise_id} → {head!r} is not a deltoid head")
        if exercise["primaryMuscle"] != "delts":
            raise BuildError(
                f"delt_heads.json: id {exercise_id} ({exercise['name']}) has primary muscle "
                f"{exercise['primaryMuscle']!r}, not delts — an override here is a typo"
            )
        exercise["primaryMuscle"] = head


def apply_aliases(exercises: list[dict], aliases: dict) -> None:
    by_id = {exercise["id"]: exercise for exercise in exercises}
    for exercise_id, values in aliases["map"].items():
        exercise = by_id.get(exercise_id)
        if exercise is None:
            raise BuildError(f"aliases_pt.json: id {exercise_id} is not in the catalogue")
        if not values or any(not isinstance(value, str) or not value.strip() for value in values):
            raise BuildError(f"aliases_pt.json: id {exercise_id} has an empty alias")
        exercise["aliases"] = list(values)


def validate_records(records: list[dict]) -> None:
    seen: set[str] = set()
    for record in records:
        if not ID_PATTERN.match(record["id"]):
            raise BuildError(f"id {record['id']!r} is not a 4-digit upstream id")
        if record["id"] in seen:
            raise BuildError(f"duplicate id {record['id']}")
        seen.add(record["id"])
        if not record["name"].strip():
            raise BuildError(f"id {record['id']} has an empty name")
        if not record["instruction_steps"].get("en"):
            raise BuildError(f"id {record['id']} has no English instruction steps")
        if not record["attribution"].strip():
            raise BuildError(f"id {record['id']} has no attribution — §5.1 requires one")


def render_exercises(exercises: list[dict]) -> bytes:
    """Serialises the catalogue deterministically.

    One record per line inside a JSON array: still valid JSON, still compact
    enough to ship, and a regenerated catalogue produces a diff that can be read
    rather than a single 1.1 MB line.
    """
    lines = [json.dumps(e, ensure_ascii=False, separators=(",", ":")) for e in exercises]
    return ("[\n" + ",\n".join(lines) + "\n]\n").encode("utf-8")


def render_version(catalogue: bytes, source_commit: str, count: int, generated_at: str) -> bytes:
    payload = {
        "sourceCommit": source_commit,
        "generatedAt": generated_at,
        "count": count,
        "checksum": "sha256:" + hashlib.sha256(catalogue).hexdigest(),
    }
    return (json.dumps(payload, indent=2, ensure_ascii=False) + "\n").encode("utf-8")


def build(tool_dir: Path, dataset: Path) -> tuple[bytes, str, int]:
    """Runs the pipeline and returns the rendered catalogue, source commit and count."""
    muscles = load_json(tool_dir / "mappings" / "muscles.json")
    equipment = load_json(tool_dir / "mappings" / "equipment.json")
    name_fixes = load_json(tool_dir / "mappings" / "name_fixes.json")
    aliases = load_json(tool_dir / "aliases_pt.json")
    delt_heads = load_json(tool_dir / "delt_heads.json")

    validate_tables(muscles, equipment, delt_heads)

    records = load_json(dataset)
    if not isinstance(records, list):
        raise BuildError(f"{dataset} is not an array of records")

    kept = [r for r in records if r["body_part"] != CARDIO_BODY_PART]
    validate_records(kept)
    apply_name_fixes(kept, name_fixes)

    unmapped = collect_unmapped(kept, muscles, equipment)
    if any(unmapped.values()):
        report = tool_dir / "unmapped.json"
        report.write_text(
            json.dumps(unmapped, indent=2, ensure_ascii=False, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        totals = ", ".join(f"{len(values)} {kind}" for kind, values in unmapped.items() if values)
        raise BuildError(
            f"{totals} value(s) have no mapping. Wrote {display_path(report)} — "
            f"add every value there to the tables in mappings/ and re-run. "
            f"Passing them through unchanged is what §5.4 forbids."
        )

    # Sorted by id so the output never depends on the order upstream happened to
    # write its file in.
    exercises = sorted((normalise(r, muscles, equipment) for r in kept), key=lambda e: e["id"])
    apply_delt_heads(exercises, delt_heads)
    apply_aliases(exercises, aliases)

    source_commit = (tool_dir / "SOURCE_COMMIT").read_text(encoding="utf-8").strip()
    if not re.fullmatch(r"[0-9a-f]{40}", source_commit):
        raise BuildError(f"SOURCE_COMMIT is not a full commit sha: {source_commit!r}")

    return render_exercises(exercises), source_commit, len(exercises)


def write_outputs(out_dir: Path, catalogue: bytes, source_commit: str, count: int) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "exercises.json").write_bytes(catalogue)
    generated_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
    (out_dir / "version.json").write_bytes(
        render_version(catalogue, source_commit, count, generated_at)
    )


def check(out_dir: Path, catalogue: bytes, source_commit: str, count: int) -> int:
    """Verifies the committed assets match what this run would produce.

    `generatedAt` is excluded from the comparison: it describes the run, not the
    catalogue, and including it would make idempotence impossible to assert.
    """
    committed_catalogue = out_dir / "exercises.json"
    committed_version = out_dir / "version.json"
    if not committed_catalogue.exists() or not committed_version.exists():
        print(f"error: {out_dir} has no committed catalogue. Run build.py.", file=sys.stderr)
        return 1

    problems: list[str] = []
    if committed_catalogue.read_bytes() != catalogue:
        problems.append("exercises.json is stale")

    expected = json.loads(render_version(catalogue, source_commit, count, "").decode("utf-8"))
    actual = json.loads(committed_version.read_text(encoding="utf-8"))
    for key in ("sourceCommit", "count", "checksum"):
        if actual.get(key) != expected[key]:
            problems.append(f"version.json {key}: {actual.get(key)!r} != {expected[key]!r}")

    if problems:
        print("error: committed catalogue is out of date:", file=sys.stderr)
        for problem in problems:
            print(f"  - {problem}", file=sys.stderr)
        print("Run: python3 tools/build_catalog/build.py", file=sys.stderr)
        return 1

    print(f"catalogue is up to date: {count} exercises at {source_commit[:10]}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify the committed assets instead of rewriting them",
    )
    parser.add_argument(
        "--tool-dir",
        type=Path,
        default=TOOL_DIR,
        help="directory holding SOURCE_COMMIT and the mapping tables (tests override this)",
    )
    parser.add_argument("--dataset", type=Path, default=None, help="vendored upstream exercises.json")
    parser.add_argument("--out", type=Path, default=None, help="output directory for the assets")
    args = parser.parse_args(argv)

    tool_dir: Path = args.tool_dir
    dataset: Path = args.dataset or tool_dir / "exercises.json"
    out_dir: Path = args.out or REPO_ROOT / "assets" / "catalog"

    try:
        catalogue, source_commit, count = build(tool_dir, dataset)
    except BuildError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    if args.check:
        exit_code = check(out_dir, catalogue, source_commit, count)
        if exit_code:
            return exit_code
        # Idempotence (§5.7.5): a second pass over the same inputs must render
        # the same bytes. Cheap to prove here, and it is the property every
        # other check quietly assumes.
        again, _, _ = build(tool_dir, dataset)
        if again != catalogue:
            print("error: the build is not idempotent — two runs differ", file=sys.stderr)
            return 1
        return 0

    write_outputs(out_dir, catalogue, source_commit, count)
    size_mb = len(catalogue) / 1_000_000
    print(f"wrote {count} exercises ({size_mb:.2f} MB) to {out_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
