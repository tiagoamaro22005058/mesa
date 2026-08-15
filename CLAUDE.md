# Mesa — Gym Routine App

A personal, single-user Android app for designing, running and tracking gym training, replacing a spreadsheet-based 4-week RPE mesocycle on a Legs/Push/Pull split. It does three jobs: **design** — build programs (days → exercise blocks → set schemes) from a bundled exercise catalogue; **run** — log sets during a session, offline, one-handed, in under two taps per set; **learn** — turn logged sets into progression suggestions, PRs and trend charts. Exercises are substituted when the gym in use lacks the equipment. Android is the only target, but the code stays platform-portable — iOS is not a goal and must not be structurally excluded.

## The contract

`docs/caderno-de-encargos.md` is the specification and the single source of truth.

- Read the relevant sections of it before starting each milestone. Do not work from memory or from this file alone.
- Implement the current milestone only (M0 → M7, in order). Never build ahead into a later milestone.
- Anything not written in the caderno is out of scope until the caderno is updated.
- A milestone is done when its acceptance criteria (§6) pass, not when the code compiles. Each ends with a working app, a passing test suite, and a commit.
- If the spec is wrong, or an assumption in §2.1 does not hold, flag it and update the document — never silently diverge.
- Use the §3 glossary names verbatim in code: Exercise, CustomExercise, Gym, Program, Day, Block, SetScheme, Mesocycle, WeekRole, Session, SetLog, RIR, e1RM, PR.

## Stack (§2 — decided, do not revisit)

- Flutter, stable channel, Dart 3.
- Backend is Firebase: Auth + Cloud Firestore. No server to run.
- Auth is Firebase Auth with email/password **and** Google Sign-In.
- User data goes in Cloud Firestore, never Realtime Database, all namespaced under `users/{uid}`.
- The exercise catalogue is a bundled local JSON asset (`assets/catalog/`), never Firestore. Zero Firestore reads for catalogue browsing.
- Exercise media (thumbnails, GIFs) loads remotely on demand and is cached via `cached_network_image`. Never bundled in the APK, never re-hosted — the media is © Gym visual, not MIT. Licence terms, not size, drive this (§5.1).
- State management is Riverpod, code-generation flavour.
- Routing is `go_router`.
- Charts are `fl_chart`.
- Units default to kilograms; imperial is a settings toggle, not a v1 blocker.
- Dark theme is the default (gym lighting).
- Strings are externalised from day one (`flutter_localizations` + ARB); ship English, Portuguese ready to add.

## Structure (§9 — architectural rules)

- `domain/` imports nothing from `data/` and nothing from Flutter. Pure Dart only.
- Repository **interfaces** live in `domain/repositories/`; **implementations** live in `data/firestore/`.
- `features/` never touch Firestore directly — they go through repository interfaces.
- `domain/models/` holds freezed entities with no Firebase types.
- `domain/progression/` is a pure algorithm module (§7): no Firebase, no Flutter, unit-testable in isolation.

```
lib/
  main.dart
  app/       // bootstrap, router, theme, DI
  core/      // failures, extensions, formatters, constants
  domain/    // models/ progression/ repositories/
  data/      // firestore/ catalog/
  features/  // auth/ catalog/ programs/ session/ history/ gyms/ settings/ (each: presentation/ + providers/)
assets/catalog/        // exercises.json, version.json
tools/build_catalog/   // ingestion script (§5)
test/ integration_test/  firestore.rules  firestore.indexes.json
```

## Verify

```bash
flutter analyze
flutter test
```

Both must be clean before any commit. CI runs the same two commands plus a debug APK build.
