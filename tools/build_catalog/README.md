# Catalogue ingestion

Turns the vendored upstream dataset into the two files the app ships in its
APK: `assets/catalog/exercises.json` and `assets/catalog/version.json`.

Specified in §5 of `docs/caderno-de-encargos.md`. Read that before changing
anything here — particularly §5.1, which is a licence constraint rather than a
technical one.

```bash
python3 tools/build_catalog/build.py           # regenerate the assets
python3 tools/build_catalog/build.py --check   # verify the committed assets
python3 tools/build_catalog/test_build.py      # run the tests
```

Python 3.12, standard library only. There is nothing to install.

## What is in here

| File | |
|---|---|
| `exercises.json` | The vendored upstream dataset, 17 MB, 1,324 records. An input, never edited. |
| `exercises.schema.json` | Upstream's own schema, kept for reference. |
| `SOURCE_COMMIT` | The upstream commit the vendored copy came from. |
| `mappings/muscles.json` | Every muscle string → the canonical muscle enum. |
| `mappings/equipment.json` | Every equipment string → equipment, load model and gym tag. |
| `mappings/name_fixes.json` | Verbatim corrections to mis-encoded upstream names. |
| `aliases_pt.json` | Hand-maintained Portuguese search aliases. |
| `delt_heads.json` | Hand-maintained deltoid-head overrides. Empty by design. |
| `unmapped.json` | Written **only** on failure, git-ignored. The list of values to add to a table. |

## The rule

Nothing free-text survives ingestion. Every muscle, equipment and body-part
string must be in a table; anything else aborts the build and lands in
`unmapped.json` with its count, the upstream fields it appeared in, and example
exercises. Add it to the right table and run again.

This is not fussiness. `traps` and `trapezius` are the same muscle, and a
pipeline that passes both through splits every per-muscle total in M6 without
ever looking wrong.

## Why the upstream copy is vendored and pinned

`SOURCE_COMMIT` names the exact upstream commit the dataset came from, and the
17 MB copy is committed alongside it. An upstream edit can therefore never
change a build silently, and the whole pipeline runs offline. The generated
assets are committed too, so a normal `flutter build` never runs any of this.

To move to a newer upstream: replace `exercises.json`, update `SOURCE_COMMIT`,
update `mediaBaseUrl` in `lib/core/constants/catalog_config.dart` to the same
commit — a test asserts they match — then run `build.py` and fix whatever it
refuses to map.

## Media

The generated catalogue stores **relative** media paths (`images/0001-….jpg`).
The app prefixes them with the pinned raw base URL at load time. Media is never
bundled and never re-hosted: the GIFs are © Gym visual, not MIT, and §5.1 is
what governs that. See `ATTRIBUTION.md` at the repo root.
