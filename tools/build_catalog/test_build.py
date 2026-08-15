#!/usr/bin/env python3
"""Tests for the catalogue ingestion (§5.4, §5.7).

The property under test is the one M2 is judged on: **the build fails on any
unmapped muscle or equipment value**. A pipeline that quietly passes an unknown
string through is worse than one that does not run, because the damage only
surfaces later as split analytics and broken substitution.

Run with:  python3 tools/build_catalog/test_build.py
"""

from __future__ import annotations

import io
import json
import shutil
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import build  # noqa: E402

TOOL_DIR = Path(__file__).resolve().parent


def record(
    exercise_id: str,
    *,
    name: str = "test exercise",
    body_part: str = "chest",
    equipment: str = "barbell",
    target: str = "pectorals",
    muscle_group: str = "shoulders",
    secondary: list[str] | None = None,
) -> dict:
    """One synthetic upstream record, in the shape exercises.schema.json declares."""
    return {
        "id": exercise_id,
        "name": name,
        "category": body_part,
        "body_part": body_part,
        "equipment": equipment,
        "instructions": {"en": "Do the thing."},
        "instruction_steps": {"en": ["Do the thing.", "Then stop."]},
        "muscle_group": muscle_group,
        "secondary_muscles": secondary if secondary is not None else ["triceps"],
        "target": target,
        "media_id": "abc123",
        "image": f"images/{exercise_id}-abc123.jpg",
        "gif_url": f"videos/{exercise_id}-abc123.gif",
        "attribution": "© Gym visual — https://gymvisual.com/",
        "created_at": "2024-01-01T00:00:00Z",
    }


class IngestionTestCase(unittest.TestCase):
    """Runs the real pipeline against a synthetic dataset in a temp directory."""

    def setUp(self) -> None:
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp)

        self.tool_dir = self.tmp / "build_catalog"
        (self.tool_dir / "mappings").mkdir(parents=True)

        # The real tables, so the tests exercise the mappings that actually ship.
        for table in ("muscles.json", "equipment.json", "name_fixes.json"):
            shutil.copy(TOOL_DIR / "mappings" / table, self.tool_dir / "mappings" / table)
        (self.tool_dir / "SOURCE_COMMIT").write_text("a" * 40, encoding="utf-8")

        # name_fixes targets ids the synthetic dataset does not have, so it is
        # emptied; its own failure modes get a dedicated test below.
        self.write_table("mappings/name_fixes.json", {"map": {}})
        self.write_table("aliases_pt.json", {"map": {}})
        self.write_table("delt_heads.json", {"allowed": ["front_delts", "side_delts", "rear_delts"], "map": {}})

        self.dataset = self.tool_dir / "exercises.json"
        self.out = self.tmp / "assets"

    def write_table(self, relative: str, payload: dict) -> None:
        path = self.tool_dir / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(payload), encoding="utf-8")

    def write_dataset(self, records: list[dict]) -> None:
        self.dataset.write_text(json.dumps(records), encoding="utf-8")

    def run_build(self, *extra: str) -> tuple[int, str]:
        argv = ["--tool-dir", str(self.tool_dir), "--dataset", str(self.dataset), "--out", str(self.out)]
        stderr = io.StringIO()
        with redirect_stderr(stderr), redirect_stdout(io.StringIO()):
            code = build.main(argv + list(extra))
        return code, stderr.getvalue()

    def catalogue(self) -> list[dict]:
        return json.loads((self.out / "exercises.json").read_text(encoding="utf-8"))

    # --- the M2 criterion -------------------------------------------------

    def test_unmapped_muscle_fails_the_build(self) -> None:
        self.write_dataset([record("0001", secondary=["gluteus profundus"])])

        code, stderr = self.run_build()

        self.assertEqual(code, 1)
        self.assertIn("no mapping", stderr)
        report = json.loads((self.tool_dir / "unmapped.json").read_text(encoding="utf-8"))
        self.assertIn("gluteus profundus", report["muscles"])
        self.assertEqual(report["muscles"]["gluteus profundus"]["count"], 1)
        self.assertEqual(report["muscles"]["gluteus profundus"]["upstreamFields"], ["secondary_muscles"])
        self.assertFalse((self.out / "exercises.json").exists(), "no asset is written on failure")

    def test_unmapped_equipment_fails_the_build(self) -> None:
        self.write_dataset([record("0001", equipment="gravity boots")])

        code, stderr = self.run_build()

        self.assertEqual(code, 1)
        self.assertIn("no mapping", stderr)
        report = json.loads((self.tool_dir / "unmapped.json").read_text(encoding="utf-8"))
        self.assertIn("gravity boots", report["equipment"])

    def test_unmapped_body_part_fails_the_build(self) -> None:
        self.write_dataset([record("0001", body_part="tail")])

        code, _ = self.run_build()

        self.assertEqual(code, 1)
        report = json.loads((self.tool_dir / "unmapped.json").read_text(encoding="utf-8"))
        self.assertIn("tail", report["bodyPart"])

    def test_the_report_lists_every_unmapped_value_not_only_the_first(self) -> None:
        self.write_dataset(
            [
                record("0001", target="left pinky"),
                record("0002", equipment="gravity boots"),
                record("0003", target="left pinky"),
            ]
        )

        self.run_build()

        report = json.loads((self.tool_dir / "unmapped.json").read_text(encoding="utf-8"))
        self.assertEqual(report["muscles"]["left pinky"]["count"], 2)
        self.assertIn("gravity boots", report["equipment"])
        self.assertEqual(len(report["muscles"]["left pinky"]["examples"]), 2)

    # --- normalisation ----------------------------------------------------

    def test_cardio_is_excluded(self) -> None:
        self.write_dataset([record("0001"), record("0002", body_part="cardio", equipment="stationary bike")])

        code, _ = self.run_build()

        self.assertEqual(code, 0)
        self.assertEqual([e["id"] for e in self.catalogue()], ["0001"])

    def test_synonyms_collapse_onto_one_canonical_muscle(self) -> None:
        self.write_dataset(
            [
                record("0001", target="quads", muscle_group="quadriceps", secondary=["trapezius"]),
                record("0002", target="pectorals", muscle_group="traps", secondary=["latissimus dorsi"]),
            ]
        )

        self.run_build()
        first, second = self.catalogue()

        self.assertEqual(first["primaryMuscle"], "quads")
        self.assertEqual(first["synergist"], "quads")
        self.assertEqual(first["secondaryMuscles"], ["traps"])
        self.assertEqual(second["primaryMuscle"], "chest")
        self.assertEqual(second["secondaryMuscles"], ["lats"])

    def test_the_primary_muscle_is_dropped_from_the_secondaries(self) -> None:
        # `delts` and `shoulders` are the same muscle once normalised. Carrying
        # both would double-count the exercise in M6's per-muscle volume.
        self.write_dataset([record("0001", target="delts", secondary=["shoulders", "triceps", "deltoids"])])

        self.run_build()

        self.assertEqual(self.catalogue()[0]["secondaryMuscles"], ["triceps"])

    def test_load_models_are_derived_from_equipment(self) -> None:
        self.write_dataset(
            [
                record("0001", equipment="barbell"),
                record("0002", equipment="body weight"),
                record("0003", equipment="weighted"),
                record("0004", equipment="assisted"),
                record("0005", equipment="stability ball"),
            ]
        )

        self.run_build()
        models = {e["id"]: e["loadModel"] for e in self.catalogue()}

        self.assertEqual(models["0001"], "externalLoad")
        self.assertEqual(models["0002"], "bodyweight")
        self.assertEqual(models["0003"], "bodyweightPlusLoad")
        self.assertEqual(models["0004"], "assisted")
        self.assertEqual(models["0005"], "bodyweight")

    def test_media_paths_stay_relative(self) -> None:
        self.write_dataset([record("0001")])

        self.run_build()
        exercise = self.catalogue()[0]

        self.assertEqual(exercise["thumbnailUrl"], "images/0001-abc123.jpg")
        self.assertEqual(exercise["gifUrl"], "videos/0001-abc123.gif")

    def test_records_are_sorted_by_id(self) -> None:
        self.write_dataset([record("0003"), record("0001"), record("0002")])

        self.run_build()

        self.assertEqual([e["id"] for e in self.catalogue()], ["0001", "0002", "0003"])

    # --- the hand-maintained tables ---------------------------------------

    def test_a_delt_head_override_narrows_only_the_primary_muscle(self) -> None:
        self.write_table(
            "delt_heads.json",
            {"allowed": ["front_delts", "side_delts", "rear_delts"], "map": {"0001": "side_delts"}},
        )
        self.write_dataset([record("0001", target="delts", muscle_group="shoulders", secondary=["traps"])])

        code, _ = self.run_build()
        exercise = self.catalogue()[0]

        self.assertEqual(code, 0)
        self.assertEqual(exercise["primaryMuscle"], "side_delts")
        self.assertEqual(exercise["synergist"], "delts", "a single head cannot describe both positions")

    def test_a_delt_head_override_on_a_non_delt_exercise_fails(self) -> None:
        self.write_table(
            "delt_heads.json",
            {"allowed": ["front_delts", "side_delts", "rear_delts"], "map": {"0001": "side_delts"}},
        )
        self.write_dataset([record("0001", target="pectorals")])

        code, stderr = self.run_build()

        self.assertEqual(code, 1)
        self.assertIn("not delts", stderr)

    def test_an_override_for_an_unknown_id_fails(self) -> None:
        self.write_table(
            "delt_heads.json",
            {"allowed": ["front_delts", "side_delts", "rear_delts"], "map": {"9999": "side_delts"}},
        )
        self.write_dataset([record("0001", target="delts")])

        code, stderr = self.run_build()

        self.assertEqual(code, 1)
        self.assertIn("9999", stderr)

    def test_an_alias_for_an_unknown_id_fails(self) -> None:
        self.write_table("aliases_pt.json", {"map": {"9999": ["agachamento"]}})
        self.write_dataset([record("0001")])

        code, stderr = self.run_build()

        self.assertEqual(code, 1)
        self.assertIn("9999", stderr)

    def test_aliases_are_attached_to_the_exercise(self) -> None:
        self.write_table("aliases_pt.json", {"map": {"0001": ["agachamento livre"]}})
        self.write_dataset([record("0001")])

        self.run_build()

        self.assertEqual(self.catalogue()[0]["aliases"], ["agachamento livre"])

    def test_a_name_fix_whose_source_no_longer_matches_fails(self) -> None:
        # Guards against the fix silently rewriting a name upstream has since
        # corrected — which would put our stale spelling back.
        self.write_table("mappings/name_fixes.json", {"map": {"0001": {"from": "old name", "to": "new name"}}})
        self.write_dataset([record("0001", name="a different name")])

        code, stderr = self.run_build()

        self.assertEqual(code, 1)
        self.assertIn("upstream changed", stderr)

    def test_a_name_fix_is_applied(self) -> None:
        self.write_table("mappings/name_fixes.json", {"map": {"0001": {"from": "sled 45в°", "to": "sled 45°"}}})
        self.write_dataset([record("0001", name="sled 45в°")])

        self.run_build()

        self.assertEqual(self.catalogue()[0]["name"], "sled 45°")

    # --- reproducibility (§5.7.5) -----------------------------------------

    def test_two_runs_produce_identical_bytes(self) -> None:
        self.write_dataset([record("0002"), record("0001", equipment="cable")])

        self.run_build()
        first = (self.out / "exercises.json").read_bytes()
        self.run_build()
        second = (self.out / "exercises.json").read_bytes()

        self.assertEqual(first, second)

    def test_check_mode_fails_on_a_stale_asset(self) -> None:
        self.write_dataset([record("0001")])
        self.run_build()

        self.write_dataset([record("0001"), record("0002")])
        code, stderr = self.run_build("--check")

        self.assertEqual(code, 1)
        self.assertIn("stale", stderr)

    def test_check_mode_passes_on_a_current_asset(self) -> None:
        self.write_dataset([record("0001"), record("0002")])
        self.run_build()

        code, _ = self.run_build("--check")

        self.assertEqual(code, 0)

    def test_the_version_file_records_the_pinned_commit_and_a_checksum(self) -> None:
        self.write_dataset([record("0001")])

        self.run_build()
        version = json.loads((self.out / "version.json").read_text(encoding="utf-8"))

        self.assertEqual(version["sourceCommit"], "a" * 40)
        self.assertEqual(version["count"], 1)
        self.assertTrue(version["checksum"].startswith("sha256:"))

    # --- table self-consistency -------------------------------------------

    def test_a_mapping_onto_a_non_canonical_muscle_fails(self) -> None:
        self.write_table(
            "mappings/muscles.json",
            {"canonical": ["chest"], "map": {"pectorals": "pecs"}},
        )
        self.write_dataset([record("0001")])

        code, stderr = self.run_build()

        self.assertEqual(code, 1)
        self.assertIn("non-canonical", stderr)


class ShippedTablesTestCase(unittest.TestCase):
    """The committed tables, against the committed dataset."""

    def test_the_real_catalogue_builds_clean(self) -> None:
        catalogue, source_commit, count = build.build(TOOL_DIR, TOOL_DIR / "exercises.json")

        self.assertEqual(count, 1295, "§5.2: 1,324 upstream records less 29 cardio")
        self.assertEqual(len(source_commit), 40)
        exercises = json.loads(catalogue.decode("utf-8"))
        self.assertEqual(len(exercises), 1295)
        self.assertTrue(all(e["loadModel"] for e in exercises))
        self.assertTrue(all(e["attribution"] for e in exercises), "§5.1 requires an attribution")


if __name__ == "__main__":
    unittest.main(verbosity=2)
