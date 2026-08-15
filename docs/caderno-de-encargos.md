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

At 1.05 MB the catalogue ships in the APK and loads into memory at startup — no database, no lazy loading, no Firestore reads. For reference on why media stays remote: thumbnails are ~6 KB each (~8 MB for the set), GIFs 90–125 KB each (**~150 MB** for the set).

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

- Every muscle string from `target`, `muscle_group` and `secondary_muscles` passes through **one** canonical mapping table into a fixed enum: chest, front_delts, side_delts, rear_delts, lats, upper_back, traps, biceps, triceps, forearms, quads, hamstrings, glutes, calves, abs, obliques, lower_back, hip_flexors, adductors, abductors, core, neck.
- The 28 equipment strings map onto the `Gym.equipment` vocabulary. The long tail (`tire`, `hammer`, `skierg machine`, `upper body ergometer`, `wheel roller`, `bosu ball`, `sled machine`, `roller`, …) collapses to `other` or is excluded — decide per tag in the mapping file; free-text must not survive ingestion.
- Exclude `body_part == "cardio"` (29 records). Result: **1,295 exercises**.
- Any value absent from the mapping tables **fails the build** and is written to `tools/build_catalog/unmapped.json`. Silent pass-through is forbidden — that is exactly how synonym drift reaches the database.
- Six duplicate names exist (`lever chest press`, `ez barbell spider curl`, `barbell seated calf raise`, `push-up (on stability ball)`, `self assisted inverse leg curl`, `smith reverse calf raises`). Disambiguate at display time by appending equipment; ids stay distinct so nothing else is affected.
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
  final String attribution;
}
```

### 5.6 Load models — derived, absent upstream

The dataset says nothing about *how* an exercise is loaded, but the progression maths depends on it entirely. Derive `loadModel` from `equipment` during ingestion:

| loadModel | Equipment | Logging & maths |
|---|---|---|
| `externalLoad` | barbell, dumbbell, cable, leverage machine, smith machine, kettlebell, ez barbell, olympic barbell, trap bar, band, sled machine, medicine ball | Weight entered directly. Standard e1RM (§7.1). |
| `bodyweight` | body weight (325 records) | No weight field. Progress tracked as reps at a target RPE, not load. |
| `bodyweightPlusLoad` | weighted (36 records) | Total load = bodyweight + added weight. Uses `users/{uid}.bodyweight` for a new set, and the `bodyweightLog` entry current at the time for a historical one (§4). |
| `assisted` | assisted (15 records) | The load **is assistance** — it moves inverse to progress. Less assistance is improvement. |

The `assisted` inversion and the `bodyweightPlusLoad` bodyweight dependency are the two most likely sources of silently wrong numbers in this app. Both get explicit unit tests (§7.4).

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
| NFR7 | **Localisation.** Strings externalised from day one (`flutter_localizations` + ARB). Ship English; Portuguese ready to add without refactoring. Note that the dataset ships instructions in 10 languages but **not Portuguese** — exercise instructions stay English regardless of UI language. |

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
