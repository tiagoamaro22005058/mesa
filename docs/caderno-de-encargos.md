# Caderno de Encargos — Gym Routine App (Android)

**Version:** 0.2 (draft)
**Owner:** Tiago
**Purpose of this document:** single source of truth handed to Claude Code. Work through it milestone by milestone. Anything not written here is out of scope until this document is updated.

---

## 1. Overview

A personal Android app for designing, running and tracking gym training. It replaces a spreadsheet-based plan: a 4-week RPE mesocycle across a Legs / Push / Pull split, with exercises swapped when equipment is unavailable at the gym in use.

Three jobs the app must do well:

1. **Design** — build a program (days → exercises → set schemes) from a catalogue of exercises.
2. **Run** — log sets during a session, offline, one-handed, in under two taps per set.
3. **Learn** — turn logged sets into progression suggestions and trend charts.

**Primary user:** the app owner (single-user product, multi-account capable).
**Platform:** Android. Code must stay platform-portable — iOS is not a target but should not be structurally excluded.

### 1.1 Non-goals (v1)

- Social features, sharing, coach/client roles.
- Nutrition, macros, bodyweight photos.
- Cardio, swimming or any non-lifting session type.
- Wearable / Health Connect integration.
- Video playback or exercise demonstration animation (static images only).
- Web or tablet-optimised layouts.

---

## 2. Decisions already made

| Area | Decision | Rationale |
|---|---|---|
| App framework | **Flutter (stable channel), Dart 3** | Owner's existing skill; first-class Firebase support via FlutterFire; single codebase leaves iOS open. |
| Backend | **Firebase** — Auth + Cloud Firestore | Chosen by owner. No server to run; offline persistence is built in, which matters in a basement gym with no signal. |
| Build flavours | **Two Android flavours, one Firebase project each** — `dev` → applicationId `com.tiagoamaro.mesa.dev` (project `mesa-dev-4970c`); `prod` → applicationId `com.tiagoamaro.mesa` (project `mesa-prod-c0ac6`) | A Firebase Android app binds to exactly one applicationId, so two environments need two ids. The suffix also lets both builds sit on one device at once. Decided in M0. |
| Auth | Firebase Auth — email/password **and** Google Sign-In | Google Sign-In is the low-friction path on Android; email/password is the fallback and makes testing easier. |
| User data store | Cloud Firestore (not Realtime Database) | Better querying, structured documents, per-collection security rules, offline cache on mobile. |
| Exercise catalogue | **Bundled as a local JSON asset**, not stored in Firestore | Static, read-heavy data. Slimmed to English and stripped of cardio it weighs 1.05 MB — instant search, fully offline, zero Firestore reads. See §5. |
| Exercise media | **Remote, on demand, cached** — never bundled, never re-hosted | The GIFs are © Gym visual, not MIT. Licence terms, not size, drive this. See §5.1. |
| State management | Riverpod (code-gen flavour) | Testable, no `BuildContext` coupling, good fit for stream-based Firestore data. |
| Routing | `go_router` | Declarative, deep-link ready. |
| Charts | `fl_chart` | Maintained, no platform channels. |

Because flavours exist, `flutter run` and `flutter build` always require
`--flavor dev` or `--flavor prod`; a bare `flutter build apk` fails as
ambiguous. The flavour is read back at runtime from `appFlavor` to choose the
Firebase project, and an unrecognised flavour throws rather than defaulting —
a silent fallback would let a dev build write into the prod Firestore.

**Google Sign-In prerequisite (found in M1).** Google Sign-In needs the signing
certificate's SHA-1 registered against the Firebase Android app, per flavour,
after which `google-services.json` must be re-downloaded. Without it the app
holds only a web OAuth client (`client_type: 3`) and Credential Manager will
never issue an ID token. The Dart side needs no client id — the Gradle plugin
turns the web client into a per-flavour string resource, so it stays
flavour-correct automatically. This is a console action, not a code change.

The **debug** keystore's SHA-1 is registered in both projects and Google
Sign-In is confirmed working on device (M1, 2026-08-15). This covers debug and
profile builds only. **A signed release build is signed by a different key, so
its SHA-1 must be registered too — see the M7 warning in §10.**

**Code generation — domain models are hand-written (decided M1).** The last
stable `freezed` (3.2.5) pins `analyzer <11`, which cannot coexist with the
`analyzer ^13` that `riverpod_generator` and `build_runner` require on Dart
3.13. The only versions of freezed that fit are `4.0.0-dev.*` prereleases.

Rather than hold a prerelease, `domain/models/` uses plain immutable classes
with hand-written `copyWith`, `==` and `hashCode`. Riverpod keeps its code-gen
flavour on stable versions; freezed is dropped entirely.

The reasoning, since the constraint alone does not settle it:

- M1's model layer is two classes and thirteen fields. Codegen earns its keep on
  volume and nesting, and there is neither yet.
- A prerelease bought nothing in M1, because nothing in M1 needed what
  distinguishes freezed 4 from freezed 3.
- The decision is cheap to reverse. Re-adopting freezed deletes hand-written
  code rather than reworking a design.

**Revisit at M3.** The program builder introduces nested, heavily edited models
(Program → Day → Block → SetScheme) where a `copyWith` that silently forgets a
field is a real and invisible bug. If freezed 4.0.0 has shipped stable by then,
adopt it for `domain/models/` and delete the hand-written boilerplate. The one
thing hand-written `copyWith` must keep getting right in the meantime is
distinguishing "argument omitted" from "set to null" — a plain nullable
parameter cannot, and an optional field that cannot be cleared is the failure
mode. `UserProfile.copyWith` uses a sentinel for this and is tested on it.

### 2.1 Assumptions to confirm

These are written into the spec but are **assumptions, not requirements**. Flag them if wrong.

- ~~**A1** — Non-lifting sessions (swimming, cardio) loggable.~~ **Rejected.** Lifting only. Cardio records are excluded at ingestion and no cardio session type exists.
- **A2** — The mesocycle model mirrors the existing spreadsheet: a 4-week block with named week roles (Base, Deload, Intensification, Peak), each carrying its own RPE target and volume multiplier. Week roles and their order are **user-configurable**, not hard-coded.
- **A3** — Abs/accessory work is attached to existing training days rather than living on its own day. Handled by the block model, no special case needed.
- **A4** — Units default to kilograms; imperial support is a settings toggle, not a v1 blocker.

---

## 3. Glossary / domain model

Use these exact names in code. Ambiguity here produces the worst bugs.

| Term | Meaning |
|---|---|
| **Exercise** | A catalogue entry (e.g. "Barbell Back Squat"). Static reference data. |
| **CustomExercise** | User-created catalogue entry, same shape as Exercise, stored per-user. |
| **Gym** | A named location with a set of available equipment tags. Drives substitution. |
| **Program** | A training plan. Owns week roles, day templates and a status (draft / active / archived). |
| **Day** | A template within a Program (e.g. "Push"). Ordered list of Blocks. |
| **Block** | One exercise slot in a Day: exercise reference + set scheme + ordered alternatives. |
| **SetScheme** | Prescription: sets, rep range, target RPE, rest seconds. |
| **Mesocycle** | One pass through the Program's week roles (default 4 weeks). |
| **WeekRole** | Base / Deload / Intensification / Peak. Carries `rpeTarget` and `volumeMultiplier`. |
| **Session** | One actual workout instance, derived from a Day, stamped with mesocycle + week index. |
| **SetLog** | One performed set: weight, reps, RPE, warmup flag, timestamp. |
| **RIR** | Reps in reserve. `RIR = 10 − RPE`. |
| **e1RM** | Estimated one-rep max. See §7.1. |
| **PR** | Best e1RM ever recorded for an exercise, plus best set at each rep count. |

---

## 4. Firestore data model

All user data is namespaced under `users/{uid}`. Nothing user-owned lives outside that subtree — this makes security rules trivial and correct.

```
users/{uid}
  { displayName, units: 'kg'|'lb', barWeight: 20, plateInventory: [25,20,15,10,5,2.5,1.25],
    dumbbellIncrement: 2, bodyweight, bodyweightUpdatedAt,
    favouriteExerciseIds: [],
    activeProgramId, activeGymId, createdAt, updatedAt }

users/{uid}/bodyweightLog/{entryId}
  { weight, recordedAt }

users/{uid}/gyms/{gymId}
  { name, equipment: ['barbell','dumbbell','cable','machine','smith','bands','bodyweight'], isDefault }

users/{uid}/programs/{programId}
  { name, goal, status: 'draft'|'active'|'archived',
    weekRoles: [ { role: 'base', rpeTarget: 7,  volumeMultiplier: 1.0 },
                 { role: 'intensification', rpeTarget: 8.5, volumeMultiplier: 1.0 },
                 { role: 'peak', rpeTarget: 9.5, volumeMultiplier: 0.9 },
                 { role: 'deload', rpeTarget: 5.5, volumeMultiplier: 0.5 } ],
    currentMesocycle: 1, currentWeekIndex: 0, daysPerWeek, createdAt, updatedAt }

users/{uid}/programs/{programId}/days/{dayId}
  { order, name: 'Push',
    blocks: [ { blockId, exerciseId, isCustom: false, order,
                setScheme: { sets: 4, repMin: 6, repMax: 8, rpeTarget: 8, restSec: 150 },
                alternativeExerciseIds: ['...'], notes } ] }

users/{uid}/sessions/{sessionId}
  { programId, dayId, dayName, gymId, mesocycle, weekIndex, weekRole,
    status: 'in_progress'|'completed'|'abandoned',
    startedAt, endedAt, durationSec, totalVolume, notes }

users/{uid}/sessions/{sessionId}/setLogs/{setId}
  { exerciseId, exerciseName, blockId, setIndex, weight, reps, rpe,
    isWarmup, e1rm, completedAt }

users/{uid}/exerciseStats/{exerciseId}      // denormalised, written on session completion
  { exerciseName, bestE1rm, bestE1rmDate, lastPerformed,
    lastSets: [ { weight, reps, rpe } ], recentE1rm: [ { date, e1rm } ], updatedAt }

users/{uid}/customExercises/{exerciseId}
  { ...same shape as catalogue Exercise, source: 'custom' }
```

### 4.1 Rules

- `bodyweight` is the **current** value, denormalised onto the profile so the ~36 `bodyweightPlusLoad` exercises (§5.6) cost no extra read mid-session. `bodyweightLog` is the dated history: a new entry is appended whenever the value changes, never overwritten. Both are needed — the profile answers "what do I load today", the log answers "what was I when I lifted that", which is what keeps a historical e1RM from silently rewriting itself when the user's weight changes (§7.2). Decided M1, built in **M5**; M1 stores neither. A subcollection rather than an array: entries accumulate for years and are read by date range, not as a unit.
- `favouriteExerciseIds` holds the exercises starred in F2, catalogue and custom alike. Added in **M2**: F2 requires favourites and §4 originally defined nowhere for them to live. An array on the profile rather than a subcollection, because the document is already streamed for every other setting — favourites therefore cost no extra read and no extra listener (NFR2) — and the list will never exceed a few dozen ids. Deleting a custom exercise unstars it in the same action, so the favourites filter cannot show a row that resolves to nothing.
- Blocks are embedded in the Day document, not a subcollection — a day is read as a unit and never exceeds a few KB.
- `setLogs` is a subcollection — sessions can hold 40+ sets and are written incrementally during a workout.
- `exerciseStats` exists so history screens and "last time you did this" lookups cost **one document read**, not a query across every session. Written by the app on session completion; a Cloud Function is not required for v1.
- Denormalised `exerciseName` on SetLog keeps history readable if a custom exercise is later deleted.

### 4.2 Required composite indexes

- `sessions`: `status ASC, startedAt DESC`
- `setLogs` (collection group): `exerciseId ASC, completedAt DESC`

### 4.3 Security rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
      match /{document=**} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
    }
    match /{document=**} { allow read, write: if false; }
  }
}
```

Deliverables: `firestore.rules`, `firestore.indexes.json`, and **rules unit tests** using the Firebase emulator (`@firebase/rules-unit-testing`) proving that user A cannot read user B's sessions.

**Correction (M1).** The trailing `match /{document=**} { allow read, write: if false; }` cannot deny anything. Firestore evaluates rules as a logical OR across every matching path, so a later `if false` never revokes an earlier `allow`, and access is denied by default regardless. It is kept as a statement of intent — it is not a backstop, and nothing should be written on the assumption that it is one. The emulator tests are what actually prove the denials hold.

**Scope note (M1).** These rules authenticate; they do not validate. A signed-in user may write any field of any type into their own documents. That is a deliberate trade for a single-user app — the rules defend an account against *other* accounts, not against its own client — and would need revisiting if the app ever gained untrusted clients.

**Security note:** `google-services.json` is not a secret and its exposure is not the threat model — security rests entirely on the rules above. Add **Firebase App Check** (Play Integrity provider) before any public distribution to stop the API keys being driven from outside the app.

---

## 5. Exercise catalogue ingestion

**Source:** `https://github.com/hasaneyldrm/exercises-dataset` — `data/exercises.json`, 1,324 records, 17 MB raw (instructions in 10 languages).

### 5.1 Licensing — read before writing any code

- Code, dataset structure and instruction text: **MIT**.
- Thumbnails and animation GIFs: **© Gym visual**, redistributed in that repo with permission at 180×180. Reuse is governed by Gym visual's own terms and expects you to obtain your own licence.

Binding consequences for this build:

- Media is **never bundled in the APK and never re-hosted** on Firebase Storage. It loads from the source repo's raw URLs on demand, cached via `cached_network_image`.
- Each record's `attribution` string is displayed on the exercise detail screen.
- `CatalogConfig.mediaEnabled` is a **hardcoded `true`**, not a build flag (decided M1 — see §12.1). The app is not distributed: it runs on the owner's own device, which is personal use rather than redistribution, so the flag has nothing to switch between. Build it as a plain constant in M2 and do not wire configuration to it.

> **Before distributing this app, revisit this section.** The moment it reaches anyone else's device — the Play Store, an internal-testing track, a shared APK — the thumbnails and GIFs stop being personal use and Gym visual's terms apply. At that point either obtain a media licence or set `CatalogConfig.mediaEnabled` to `false` and ship without images. Keeping media access behind the single named constant is what makes that a one-line change; that is the constant's whole remaining purpose.

### 5.2 What gets bundled

Ingestion strips to English and drops cardio. Measured, not estimated:

| Variant | Size |
|---|---|
| Raw upstream, 10 languages, 1,324 records | 17 MB |
| English only, cardio excluded, with instruction steps | **1.05 MB** |
| Same, instruction steps dropped | 0.41 MB |

At this size the catalogue ships in the APK and loads into memory — no database, no Firestore reads. For reference on why media stays remote: thumbnails are ~6 KB each (~8 MB for the set), GIFs 90–125 KB each (**~150 MB** for the set).

**Measured after ingestion (M2): 1.12 MB, 1,295 exercises.** The count is exactly
as predicted. The extra 70 KB over the estimate is the fields ingestion adds
rather than copies — `loadModel`, `gymTag`, `aliases` — plus normalised muscle
names being longer than upstream's.

**Not at startup, and lazily.** §5.2 originally said the catalogue loads at
startup; M2 does not, because it does not need to. Nothing reads the asset until
the catalogue screen is opened, and the parse is then kept for the rest of the
session. Cold start is therefore untouched by it, which serves NFR3 better than
making the parse fast would. The parse also runs on the main isolate rather than
through `compute`: it costs tens of milliseconds once per session, behind a
spinner, and shipping 1,295 objects back across an isolate boundary would cost
as much again in copying.

### 5.3 Upstream schema → internal model

| Upstream field | Internal | Note |
|---|---|---|
| `id` (`"0001"`) | `id` | Stable. Use verbatim — do **not** slug the name, 6 names are duplicated. |
| `name` | `name` | Upstream is lowercase; title-case at render, not at ingestion. |
| `body_part` | `bodyPart` | Byte-identical to `category` in all 1,324 records — ignore `category` entirely. 10 values. |
| `target` | `primaryMuscle` | The real primary-muscle field. Clean: 18 values. |
| `muscle_group` | `synergist` | Misleadingly named upstream — it is a **synergist**, not the primary. (3/4 sit-up → `target: abs`, `muscle_group: hip flexors`.) 29 values, with synonyms. |
| `secondary_muscles` | `secondaryMuscles` | 40 distinct values, with synonyms. |
| `equipment` | `equipment` + derived `loadModel` | 28 values. See §5.6. |
| `instruction_steps.en` | `steps` | Use the step array, not the `instructions.en` blob. Present on every record. |
| `image`, `gif_url` | `thumbnailUrl`, `gifUrl` | Relative paths — prefix with the repo raw base URL. |
| `attribution` | `attribution` | Must be displayed (§5.1). |
| `category`, `media_id`, `created_at`, other languages | dropped | |

### 5.4 Normalisation — the step that must not be skipped

The muscle vocabularies contain synonym pairs that will silently split analytics and break substitution if passed through raw: `traps`/`trapezius`, `delts`/`deltoids`/`shoulders`, `quads`/`quadriceps`, `abs`/`abdominals`, `lats`/`latissimus dorsi`, `upper back`/`rhomboids`.

- Every muscle string from `target`, `muscle_group` and `secondary_muscles` passes through **one** canonical mapping table into a fixed enum: chest, **delts**, front_delts, side_delts, rear_delts, lats, upper_back, traps, biceps, triceps, forearms, quads, hamstrings, glutes, calves, abs, obliques, lower_back, hip_flexors, adductors, abductors, core, neck, **other**.

  **`delts` and `other` were added in M2**, after the dataset was measured against the original list. The dataset carries 49 distinct muscle strings and neither member is optional:

  - **`delts`** — upstream never distinguishes the three deltoid heads. `delts`, `deltoids` and `shoulders` are one undifferentiated bucket (777 mentions across the three fields), and only `rear deltoids` (20, secondary only) is specific. Splitting them by guesswork would put wrong numbers into M6's per-muscle volume, so they collapse to a generic `delts`. **`front_delts` and `side_delts` are therefore produced by nothing in the mapping table** — see the delt-head override below, which is the only thing that can produce them.
  - **`other`** — the long tail with no honest home: ankles (22), feet (8), shins, ankle stabilizers, serratus anterior (5). One visibly-unclassified bucket beats filing six things under near neighbours, and it renders as "Unclassified" rather than naming a muscle it is not.
  - **`rotator cuff` (10 mentions) maps to `rear_delts`**, not `other`. The exercises using it are face pulls and external rotations, which are rear-delt work in any training sense. The anatomical objection — the cuff is four muscles, none of them the deltoid — loses to the practical one: those sets get counted somewhere, and rear delts is where a lifter looks for them. Burying them in `other` would make M6 undercount the area a Push/Pull/Legs split is most likely to be short on.

- **The deltoid-head override.** `tools/build_catalog/delt_heads.json` maps an exercise id to a specific head, applied at ingestion to `primaryMuscle` only. It exists because M6's per-muscle volume cannot answer "is my side delt volume enough" out of one bucket — pressing volume swamps it — and the dataset gives nothing to answer it with. It ships **empty**: filling it is a per-exercise judgement worth making only for the exercises in the owner's actual program, which does not exist until M3. Anything left out stays `delts`, which is honest rather than wrong. The build enforces that an override names a real exercise whose primary muscle already resolves to `delts`, so a typo fails the build rather than silently reclassifying a bench press. Synergist and secondary entries are **not** rewritten — one head per exercise cannot describe both positions of an overhead press.

- **The primary muscle is removed from `secondaryMuscles`.** After the synonym collapse a record can carry the same muscle twice — `target: delts` with `shoulders` in the secondary list — which would double-count the exercise in M6's volume. Secondary lists are also deduplicated.

- **Four upstream names arrive mis-encoded** (`sled 45в° leg press`, and three like it) and are corrected verbatim through `tools/build_catalog/mappings/name_fixes.json`. Record 1463 spells the same name correctly, so this is an upstream inconsistency rather than an encoding to respect. A table rather than a regex, for the same reason the muscle vocabulary is one; the build fails if a fix's source text stops matching, so an upstream correction cannot silently reinstate our stale spelling.
- The 28 equipment strings map onto the `Gym.equipment` vocabulary. The long tail (`tire`, `hammer`, `skierg machine`, `upper body ergometer`, `wheel roller`, `bosu ball`, `sled machine`, `roller`, …) collapses to `other` or is excluded — decide per tag in the mapping file; free-text must not survive ingestion.

  **Corrected in M2: they cannot collapse only that far.** §5.6 needs `weighted` and `assisted` told apart from everything else, and §7.2's load increment needs a kettlebell told apart from a barbell — and neither `weighted` nor `assisted` is a gym tag at all. So the model keeps a fine-grained `Equipment` enum as §5.5 declares, and carries the §4 gym tag *alongside* it as a property of that enum. One mapping table, both answers, no UI in M2 — M7's substitution is what consumes the tag.

  A gym tag may be **null**, meaning the requirement is not expressible in §4's seven tags: a stability ball is neither a machine nor bodyweight. 67 records are in that position. Substitution will never flag them as missing at a gym, which is the honest outcome — the app has no way to record whether a gym has one. Widening §4's vocabulary is the fix if that ever matters; it does not in v1.

  **The long tail is kept, not excluded** (decided M2). 61 non-cardio records use equipment §5.6 assigned no load model to: stability ball (28), rope (9), roller (8), resistance band (7), bosu ball (3), wheel roller (2), plus a hammer, a tire and two cardio machines whose `body_part` is not `cardio` and which therefore survive the exclusion. `resistance band` collapses onto `band`; the rest become `other`. Excluding them instead would have put the count below the 1,295 §5.2 states.
- Exclude `body_part == "cardio"` (29 records). Result: **1,295 exercises**.
- Any value absent from the mapping tables **fails the build** and is written to `tools/build_catalog/unmapped.json`. Silent pass-through is forbidden — that is exactly how synonym drift reaches the database.
- Six duplicate names exist (`lever chest press`, `ez barbell spider curl`, `barbell seated calf raise`, `push-up (on stability ball)`, `self assisted inverse leg curl`, `smith reverse calf raises`). ~~Disambiguate at display time by appending equipment~~; ids stay distinct so nothing else is affected.

  **Wrong, corrected in M2. Appending equipment cannot disambiguate these.** All six pairs share their equipment, primary muscle *and* body part, differing only in id, media and — in two cases — a reworded instruction step. Appending equipment produces two identical labels.

  What ships instead: **equipment is shown on every row** as part of the subtitle, which is more useful than a rule that fires six times and disambiguates anything that genuinely differs by equipment; and where the name *and* equipment still collide, the row appends the **upstream id**, which is the only thing that tells those apart.

  Measured over the generated catalogue this flags **eight pairs, not six**. The two §5.4 missed differ only in punctuation — `dumbbell close grip press` / `dumbbell close-grip press`, and `dumbbell standing one arm curl (over incline bench)` / the same without brackets — because the collision test compares normalised names. A reader scanning a list cannot tell a hyphen apart either, so they are flagged too.
- `aliases` is hand-maintained in `tools/build_catalog/aliases_pt.json`. The dataset carries 10 languages but **no Portuguese**, so Portuguese search only finds what you add — seed it with the exercises actually in your program, not all 1,295.

### 5.5 Internal Exercise model

```dart
class Exercise {
  final String id;                    // upstream id, e.g. '0001'
  final String name;
  final List<String> aliases;         // hand-maintained, incl. Portuguese
  final BodyPart bodyPart;
  final Muscle primaryMuscle;         // upstream `target`
  final Muscle? synergist;            // upstream `muscle_group`
  final List<Muscle> secondaryMuscles;
  final Equipment equipment;
  final LoadModel loadModel;          // §5.6
  final List<String> steps;           // instruction_steps.en
  final String? thumbnailUrl;
  final String? gifUrl;
  final String? attribution;          // null for custom — nothing to credit
  final ExerciseSource source;        // catalogue | custom
}
```

**Two fields added in M2.**

- **`source`.** §4 already stores `source: 'custom'`, and F2 needs user-created exercises to appear inline in search results, visually marked. One merged list beats a parallel type, so §3's **`CustomExercise` is an `Exercise` whose `source` is `custom`** rather than a class of its own.
- **`attribution` is nullable.** It is a licence obligation for the bundled records (§5.1) and meaningless for a user-created one, which borrows no media.

`thumbnailUrl` and `gifUrl` are **absolute once loaded and relative in the asset**. The asset stores `images/0001-….jpg` and the loader prefixes it with the raw base URL pinned to the same upstream commit as the data; baking absolute URLs into the asset would add ~230 KB to the APK and pin the host into data meant to outlive it. A test asserts the URL's commit and `version.json`'s `sourceCommit` agree, because a drift there would show one exercise's name over another's animation.

The **gym equipment tag** (§5.4) is not a field here — it is a property of the `Equipment` enum, since it is a function of equipment and storing it twice only creates a way for the two to disagree.

### 5.6 Load models — derived, absent upstream

The dataset says nothing about *how* an exercise is loaded, but the progression maths depends on it entirely. Derive `loadModel` from `equipment` during ingestion:

| loadModel | Equipment | Logging & maths |
|---|---|---|
| `externalLoad` | barbell, dumbbell, cable, leverage machine, smith machine, kettlebell, ez barbell, olympic barbell, trap bar, band, sled machine, medicine ball | Weight entered directly. Standard e1RM (§7.1). |
| `bodyweight` | body weight (325 records) | No weight field. Progress tracked as reps at a target RPE, not load. |
| `bodyweightPlusLoad` | weighted (36 records) | Total load = bodyweight + added weight. Uses `users/{uid}.bodyweight` for a new set, and the `bodyweightLog` entry current at the time for a historical one (§4). |
| `assisted` | assisted (15 records) | The load **is assistance** — it moves inverse to progress. Less assistance is improvement. |

The `assisted` inversion and the `bodyweightPlusLoad` bodyweight dependency are the two most likely sources of silently wrong numbers in this app. Both get explicit unit tests (§7.4).

**Completed in M2.** The table above covers 1,234 of the 1,295 records; the remaining 61 use the long-tail equipment §5.4 now resolves. Stability balls, bosu balls, rollers, wheel rollers and ropes carry no external load and are `bodyweight` — they are stretches and core work. A sledge hammer and a tire flip do have a load the user can type, so they stay `externalLoad`. `resistance band` follows `band` into `externalLoad`. Final spread over the generated catalogue: **externalLoad 888, bodyweight 356, bodyweightPlusLoad 36, assisted 15**.

The load model is **derived from equipment, never stored independently on a user-created exercise**. The custom-exercise form shows what the chosen equipment implies but does not let it be overridden, and the Firestore converter recomputes it on read rather than trusting a stored value. Letting the two disagree is precisely how the §7 maths goes quietly wrong. A test holds every catalogue record's load model to what its equipment derives, which is what stops the Python mapping table and the Dart enum drifting apart.

### 5.7 Pipeline

1. `tools/build_catalog/` (Python) reads a vendored copy of `data/exercises.json` at a **pinned upstream commit** — an upstream edit must never change a build silently.
2. Normalises, validates, excludes cardio, fails loudly on unmapped values.
3. Writes `assets/catalog/exercises.json` and `assets/catalog/version.json` (`{ sourceCommit, generatedAt, count, checksum }`).
4. Output is committed, so builds are reproducible offline.
5. Re-runnable and idempotent.
6. Record the MIT licence and the Gym visual media terms in `ATTRIBUTION.md`.

---

## 6. Feature specification

Each feature lists acceptance criteria. A milestone is done when its criteria pass, not when the code compiles.

### F1 — Authentication & profile

- Email/password sign-up, sign-in, password reset; Google Sign-In.
- Auth state drives routing: unauthenticated users only reach auth screens.
- Profile settings: display name, units, bar weight, plate inventory, dumbbell increment.
- Sign-out clears local Firestore cache.

**Acceptance:** app restarts land on the last screen with the session intact; a second account sees none of the first account's data.

**Reading of "the last screen" (M1).** M1 has two authenticated screens, so there is nothing meaningful to restore: it proves the *session* survives a restart and the app lands authenticated, with no sign-in flash on cold start. Genuine last-route restoration is revisited in M3/M4, once a route tree exists that makes it worth persisting.

### F2 — Exercise catalogue

- Browse and search the bundled catalogue: fuzzy search across name + aliases, sub-100 ms across all 1,295 entries.
- Filter by body part, primary muscle and equipment.
- Detail screen: instructions, muscles, images, personal history (from `exerciseStats`), e1RM chart.
- Create/edit/delete custom exercises; they appear inline in search results, visually marked.
- Favourites.

**Acceptance:** search returns results with the device in aeroplane mode.

**Met on device 2026-08-16.** Sixteen checks in aeroplane mode, including
deleting a favourited custom exercise — the case where the exercise vanishes
from the merged catalogue while the favourite still points at it. Media falls
back to a placeholder and never surfaces an error, which is the one part of F2
that genuinely needs the network (NFR1).

**Scope split (M2).** Everything above shipped in M2 **except the detail screen's personal history and e1RM chart**, which are deliberately absent rather than unfinished:

- `exerciseStats` has no writer until session completion, which is **M4**.
- Charts are **M6**.

Building either in M2 would mean building against a collection nothing writes. A widget test asserts the detail screen carries neither, so the boundary is checked rather than remembered. Fill them in at M6, when both the data and the chart library are in play.

### F3 — Program builder

- Create a program; set name, goal, days per week.
- Configure week roles: add/remove/reorder, edit RPE target and volume multiplier per role.
- Add days, name and reorder them.
- Within a day: add exercise blocks, reorder by drag, set the scheme (sets, rep range, target RPE, rest), add free-text notes.
- Per block, pick ordered **alternatives** — the app pre-suggests them (§F7) but the user has the final say.
- Duplicate a day; duplicate a program; archive a program.
- Exactly one program may be `active` at a time.

**Acceptance:** a full Legs/Push/Pull program with 6–8 blocks per day can be built in under five minutes, and survives app restart.

### F4 — Session logging (the screen that matters most)

This is used mid-set, one-handed, with chalk on the hands. Design for that, not for looks.

- Start a session from the active program's next scheduled day; allow overriding the day and the gym.
- The session screen shows, per block: prescribed scheme, **last time's performance for that exercise**, and the suggested load (§7.2).
- Logging a set: weight and reps pre-filled from the suggestion; RPE entered on a chip row (6, 6.5, 7 … 10). One tap to confirm a set that matches the suggestion.
- Weight input steps by the user's plate increment; a plate-math helper shows what to load on the bar.
- Auto rest timer on set completion, seeded from the block's `restSec`, with a notification when it fires and the ability to skip or extend.
- Add an unplanned set, add an unplanned exercise, swap the exercise mid-session (alternatives surfaced first), skip a block.
- Finish session → writes `endedAt`, `totalVolume`, updates `exerciseStats`, advances the program's `currentWeekIndex` when a mesocycle week is complete.
- **Offline-first:** every write goes through Firestore's offline cache. A full session must be loggable, finished, and correct with no connectivity, syncing later without duplication or loss.
- Crash/kill recovery: an `in_progress` session is resumed on next launch.

**Acceptance:** aeroplane mode, log a full 25-set session, force-kill the app twice during it, restore connectivity — every set is present exactly once in Firestore.

### F5 — Progression engine

See §7 for the algorithm. UI surface:

- Suggested working load per block, with a one-line explanation of where it came from ("Base week, RPE 7 target, from e1RM 142.5 kg").
- Accept, or override manually — overrides are never fought by the engine.
- Deload weeks visibly reduce prescribed sets and load.
- Stall warning when an exercise's e1RM fails to improve across two consecutive exposures, with a prompt to swap to an alternative or adjust volume.

### F6 — History & analytics

- Session history list with filters by date, day type and program.
- Per-exercise: e1RM trend line, volume per session, rep PRs, last five sessions.
- Weekly summary: total sets per muscle group, total tonnage, session count, average session RPE.
- Mesocycle summary comparing the current block against the previous one.
- Adherence: planned vs completed sessions per week.
- Charts must render from cached data offline.

### F7 — Gym profiles & exercise substitution

Directly serves the "this gym doesn't have that machine" problem.

- Define multiple gyms, each with its equipment tags; set an active gym.
- When starting a session at a gym missing a block's equipment, the app flags the block and offers substitutes, ranked by: same `primaryMuscle` > same `bodyPart` > overlapping `secondaryMuscles` > equipment available at this gym > previously performed by the user.
- The upstream dataset has **no push/pull or compound/isolation field**, so pattern matching is not available for free. Where ranking by muscle alone gives poor suggestions (it will, for pressing vs flye patterns), let the user pin explicit alternatives on the block (F3) — the manual list always outranks the computed one.
- Substitution can be applied for this session only, or written back to the program.

### F8 — Settings

Units, theme (dark default — gym lighting), rest-timer sound/vibration, plate inventory, data export to JSON, account deletion (deletes the whole `users/{uid}` subtree).

---

## 7. Progression algorithm

Implement as a **pure Dart module** in `lib/domain/progression/` with no Firebase or Flutter imports. It must be fully unit-testable in isolation. This is the part most likely to be subtly wrong, so it gets the heaviest test coverage.

### 7.1 Estimated 1RM

```
RIR         = 10 − RPE
repsToFail  = reps + RIR
e1RM        = weight × (1 + repsToFail / 30)        // Epley, RPE-adjusted
```

- Only sets with `repsToFail ≤ 12` produce a trustworthy e1RM; above that, flag as low confidence and exclude from PR calculations.
- Warmup sets never contribute.
- An exercise's working e1RM is the **best of the last three exposures**, not the all-time best — it must track current capacity, not history.

### 7.2 Load suggestion

```
targetRIR   = 10 − weekRole.rpeTarget
targetReps  = midpoint(setScheme.repMin, setScheme.repMax)
rawLoad     = e1RM ÷ (1 + (targetReps + targetRIR) / 30)
suggested   = roundToIncrement(rawLoad, increment(exercise.equipment))
```

- `increment` is 2×smallest plate for barbells (both sides), the dumbbell increment for dumbbells, and the stack increment for machines/cables (default 5 kg, per-exercise overridable).
- Multiply prescribed **sets** by `weekRole.volumeMultiplier`, rounding down, minimum 1.
- Only `externalLoad` exercises get a load suggestion from this formula. Per §5.6: `bodyweight` exercises suggest a **rep** target instead; `bodyweightPlusLoad` adds bodyweight before computing e1RM and subtracts it before suggesting the added plate; `assisted` exercises suggest *less assistance* and **invert** every improvement comparison.
- A `bodyweightPlusLoad` e1RM is computed against the bodyweight **in force when the set was performed**, read from the `bodyweightLog` (§4) — not the current value. Recomputing history against today's bodyweight would make every past lift move whenever the user's weight did, which is the §7.4 case that must not regress.
- No history for an exercise → suggest nothing, prompt the user to enter their first working set, and mark the session as calibration.

### 7.3 Session-to-session adjustment

- Last exposure completed all sets at or below target RPE → increase e1RM estimate from the best set and let the formula raise the load.
- Last exposure exceeded target RPE by ≥1.5 on the first working set → hold the load.
- Two consecutive exposures with a lower e1RM → stall. Surface a warning (F5); never auto-change the program.

### 7.4 Test cases the implementation must satisfy

- 100 kg × 5 @ RPE 8 → e1RM ≈ 123.3 kg.
- Same input, target Base week (RPE 7) at 8 reps → suggests 100 kg after rounding to 2.5 kg.
- Deload week with `volumeMultiplier` 0.5 on a 4-set block → prescribes 2 sets.
- RPE 10 at 1 rep → e1RM equals the weight lifted.
- Reordering week roles changes the prescription for that week and nothing else.
- An `assisted` exercise going from 30 kg to 25 kg of assistance registers as **progress**, not a regression.
- A `bodyweightPlusLoad` exercise computes e1RM against the bodyweight recorded at the time of the set. Changing today's bodyweight moves the *next* suggestion and leaves every historical e1RM exactly where it was.
- A `bodyweight` exercise never renders a weight field and never produces a load suggestion.

---

## 8. Non-functional requirements

| # | Requirement |
|---|---|
| NFR1 | **Offline-first.** Every feature except sign-in and sign-up works with no network. No screen shows an error because the network is absent. |
| NFR2 | **Cost.** Zero Firestore reads for catalogue browsing. A logged session should cost under 60 writes. Stay inside the Firebase free tier for a single user. |
| NFR3 | **Performance.** Cold start under 2 s on mid-range hardware. Set logging responds in under 100 ms (optimistic local write; never await the server). |
| NFR4 | **Ergonomics.** Primary actions reachable one-handed in the bottom third of the screen. Tap targets ≥ 48 dp. Screen-on lock during an active session. |
| NFR5 | **Data safety.** No destructive action without undo or confirmation. JSON export available at any time. |
| NFR6 | **Accessibility.** Dark theme default, WCAG AA contrast, semantic labels on interactive widgets, respects system text scaling. |
| NFR7 | **Localisation.** Strings externalised from day one (`flutter_localizations` + ARB). Ship English; Portuguese ready to add without refactoring. Numeric input accepts a comma or a dot as the decimal separator, through the one parser in `core/` (§9.1) — a Portuguese keyboard offers a comma. Note that the dataset ships instructions in 10 languages but **not Portuguese** — exercise instructions stay English regardless of UI language. |

---

## 9. Project structure

```
lib/
  main.dart
  app/                 // bootstrap, router, theme, DI
  core/                // failures, extensions, formatters, constants
  domain/
    models/            // plain immutable entities — no Firebase types (§2)
    progression/       // pure algorithm module (§7)
    repositories/      // abstract interfaces
  data/
    firestore/         // repository implementations, converters
    catalog/           // bundled JSON loader + search index
  features/
    auth/ catalog/ programs/ session/ history/ gyms/ settings/
      (each: presentation/ + providers/)
assets/catalog/        // exercises.json, version.json
tools/build_catalog/   // ingestion script (§5)
test/                  // unit + widget
integration_test/
firestore.rules
firestore.indexes.json
```

Rules: `domain/` imports nothing from `data/` or Flutter. Repository interfaces live in `domain/`, implementations in `data/`. Features never touch Firestore directly.

### 9.1 Shared conventions — one implementation, in `core/`

Both of these emerged in M1 and are written down because they are the kind of
thing every later milestone re-invents per screen if it is not told not to. A
feature that needs either of them **uses the existing one and extends it if it
falls short** — it does not add a second.

**Failure vocabulary.** Errors reaching the UI are a closed set of app-level
kinds in `core/failures/`, never raw provider exceptions. Each backend
exception is translated once, at the `data/` boundary, and each kind maps to
exactly one localised string.

- M1 established the pattern with `AuthFailure` / `AuthFailureKind`
  (`core/failures/auth_failure.dart`), translated in
  `data/firestore/auth_failure_mapper.dart`.
- M2 added the two siblings §9.1 anticipated: `CatalogFailure` for a bundled
  asset that is missing, malformed, or carries a value this build has no enum
  member for; and `FirestoreFailure`, translated in
  `data/firestore/firestore_failure_mapper.dart`. `FirestoreFailure`
  deliberately has **no `networkUnavailable` kind** — Firestore applies a write
  to its local cache synchronously and syncs later, so a write that has not
  reached the server is a write that succeeded, and telling the user otherwise
  would contradict NFR1.
- Later milestones add sibling types for their own domains — a Firestore
  failure, a catalogue-load failure — following the same shape rather than
  inventing a different error style. Reuse `AuthFailureKind` where the meaning
  genuinely matches; do not stretch it where it does not.
- Two properties matter and must survive. A kind may be **silent**: the UI shows
  nothing for it, which is how backing out of the Google account picker stays a
  decision rather than an error. And an `unknown` kind **keeps the original
  provider code**, so an unmapped failure is still diagnosable from a bug report
  instead of vanishing into a generic message.
- Nothing renders an exception's `toString()` on screen.

**Numeric input.** Every numeric field in the app is a weight, an increment or
a rep count typed one-handed, and most of them arrive between M3 and M6. They
all parse through `parseWeight` in `core/formatters/`, which accepts a comma or
a dot as the decimal separator.

- The Portuguese keyboard, and most non-English ones, offer a comma where
  Dart's parser wants a dot. Rejecting `17,5` reads as the app being broken
  rather than fussy (NFR7).
- `parseWeight` returns `null` rather than throwing, so it drops straight into a
  form validator; `Validators.positiveNumber` is built on it.
- `formatWeight` is its inverse and the only way weights are rendered — `20`,
  not `20.0`. The two round-trip, and a test holds them to it.
- Thousands separators are deliberately unsupported: `1.234` is genuinely
  ambiguous between locales and no weight in this app needs four digits.

---

## 10. Milestones

Build in this order. Each milestone ends with a working app, a passing test suite, and a commit.

| # | Milestone | Done when |
|---|---|---|
| **M0** | Scaffold: Flutter project, Firebase wiring (dev + prod projects), Riverpod, go_router, theme, CI building a debug APK on GitHub Actions | App launches to a placeholder home screen; CI is green |
| **M1** | Auth + profile + security rules + rules tests | Sign-up, sign-in, sign-out, reset; cross-user access proven impossible by test |
| **M2** | Catalogue ingestion + browse/search/filter/detail + custom exercises | Catalogue searchable offline; build fails on any unmapped muscle or equipment value |
| **M3** | Program builder: programs, week roles, days, blocks, set schemes, reordering | A full PPL program is buildable and persists |
| **M4** | Session logging: start, log sets, rest timer, offline durability, finish, resume | The aeroplane-mode acceptance test in F4 passes |
| **M5** | Progression engine + suggestions + deload volume + stall detection | All §7.4 test cases pass; suggestions appear in-session |
| **M6** | History + analytics + charts + PRs | Charts render offline from cached data |
| **M7** | Gyms + substitution + settings + export + App Check + signed release APK | Installable release build; substitution flow works end to end |

**M0 closed 2026-08-15. M1 closed 2026-08-15. M2 closed 2026-08-16** — both of
M2's criteria met, the second one as a CI gate rather than a claim: the
ingestion runs in CI and fails the build on any unmapped value. F2's
aeroplane-mode acceptance passed on device. See §12.1 for the eight spec
questions M2 answered, several of which corrected §5.

**M7 warning — Google Sign-In will break in the signed release build** unless the release keystore's SHA-1 is registered in **both** Firebase projects and `google-services.json` re-downloaded per flavour. Only the debug keystore is registered (M1), and a release APK is signed by a different key, so Credential Manager will refuse to issue an ID token and sign-in will fail with a configuration error that says nothing about certificates. Do this at the same time as creating the release signing config — the two go together, and finding it afterwards costs an afternoon.

---

## 11. Testing

- **Unit:** progression module (exhaustive), catalogue mapping, repository converters, plate math.
- **Widget:** session logging screen, program builder, auth flows.
- **Integration:** full session logged against the Firebase emulator, including an offline/online transition.
- **Rules:** emulator-based tests for every collection path.
- CI runs `flutter analyze`, `flutter test`, and builds the APK on every push.
- The rules tests are a Node package (`test/firestore_rules/`), so `flutter test` cannot run them. They get their own CI job — §4.3 makes them a deliverable, and a deliverable that only ever runs by hand stops being one (added in M1).

---

## 12. Open questions

1. Confirm assumptions **A2–A4** in §2.1 — in particular whether the Base → Deload → Intensification → Peak ordering is deliberate (kept as written).
2. Should a program schedule to fixed weekdays, or simply advance to "next day in sequence" whenever a session starts? (Spec currently assumes the latter — more forgiving of missed days.)
3. Is Portuguese UI needed at launch, or is English-with-ARB-ready sufficient?

### 12.1 Answered

- **The deltoid heads cannot come from the data** (M2, 2026-08-15) — the dataset has one undifferentiated `delts` bucket, so the enum gained a generic `delts` and `front_delts`/`side_delts` are reachable only through the hand-maintained `delt_heads.json` override, which ships empty. Recorded in §5.4 so **M6 does not discover the limitation** while trying to answer "is my side delt volume enough": if that question matters, the override table is where the answer comes from, and it has to be filled in per exercise first.
- **Rotator cuff counts as rear delts** (M2) — 10 mentions, all face pulls and external rotations. Filed under `rear_delts` rather than `other` so M6 does not undercount the area a PPL split is most likely to be short on. §5.4 carries the reasoning.
- **Favourites live on the profile** (M2) — `users/{uid}.favouriteExerciseIds`. F2 required favourites and §4 defined nowhere for them. Zero extra reads, since the document is already streamed. Added to §4.
- **`Exercise` gained `source`** (M2) — §3's `CustomExercise` is an `Exercise` whose source is `custom`, not a separate class, so search can merge the two lists and mark one. §5.5 amended, along with `attribution` becoming nullable.
- **Equipment does not collapse onto the gym vocabulary alone** (M2) — §5.6 and §7.2 need finer granularity than §4's seven tags, and `weighted`/`assisted` are not tags at all. The `Equipment` enum stays fine-grained and carries the gym tag as a property, which may be null where §4's vocabulary cannot express the requirement. §5.4 amended.
- **The long tail is kept, not excluded** (M2) — 61 records on stability balls, ropes and rollers stay in the catalogue as `other`, which keeps the count at §5.2's 1,295. §5.4 and §5.6 amended.
- **Appending equipment cannot disambiguate the duplicate names** (M2) — all six pairs share their equipment. Equipment now shows on every row and the genuinely ambiguous rows append the upstream id. There are eight such pairs, not six. §5.4 corrected.
- **F2's history and chart are M4/M6 work** (M2) — the detail screen ships without them because `exerciseStats` has no writer yet. §6 F2 carries the split.

- **Google Sign-In signing keys** (M1, 2026-08-15) — the debug keystore's SHA-1 is registered in both Firebase projects and Google Sign-In works on device. **The release keystore's SHA-1 is not, and must be added at M7 or sign-in breaks in the signed build.** See §2 and the M7 warning in §10.

- **Distribution and the media licence** (answered 2026-08-15) — the app is **not** going to the Play Store; it runs on the owner's own device. `CatalogConfig.mediaEnabled` is therefore a hardcoded `true` rather than a real flag, and M2 should not build configuration around it. §5.1 carries the standing caveat: distributing the app to anyone else makes the Gym visual licence live again, and the constant is what keeps turning media off a one-line change.
- **Bodyweight tracking** (answered 2026-08-15) — **both**. `users/{uid}.bodyweight` holds the current value for load suggestions, and `users/{uid}/bodyweightLog/{entryId}` appends a dated entry whenever it changes, so a historical e1RM stays computed against the bodyweight in force at the time. Added to §4; consumed in §5.6 and §7.2; built in **M5**. This resolves the contradiction where §5.6 required a profile field that §4 did not define.
- **Domain models and freezed** (M1) — dropped; plain immutable classes with hand-written `copyWith`. Reasoning and the M3 trigger to revisit are in §2.
- **Rules tests in CI** (M1) — yes, as a separate job. See §11.
- **Plate inventory editing** (M1) — a chip toggle over the standard kilogram set (25, 20, 15, 10, 5, 2.5, 1.25, 0.5). §4's default inventory is that set without the 0.5. Free-form plate weights would need this vocabulary widened first.
- **"Last screen" on restart** (M1) — session-only for now. See §6 F1.

---

## 13. Using this document with Claude Code

1. Create the repo, put this file at `docs/caderno-de-encargos.md`.
2. Create a `CLAUDE.md` at the root holding: the stack decisions (§2), the project structure rules (§9), and the instruction to consult this document before starting each milestone.
3. Work one milestone per session, in order. Suggested opening prompt:

> Read `docs/caderno-de-encargos.md`. Implement milestone M1 only. Before writing code, list the files you will create or change and the acceptance criteria you are targeting, and wait for my confirmation. Do not start work on later milestones.

4. Commit at the end of each milestone. Update §12 as questions get answered — this document is the contract, so it should stay current rather than becoming a historical artefact.
