# mesa

A personal Android app for designing, running and tracking gym training.

`docs/caderno-de-encargos.md` is the specification and the single source of
truth. `CLAUDE.md` restates the binding rules for working on it.

## Building

Two Android flavours point at two Firebase projects (§2), so the flavour is
never optional — a bare `flutter build apk` fails as ambiguous:

```bash
flutter run --flavor dev
```

```bash
flutter build apk --debug --flavor dev
```

## Verifying

Both must be clean before any commit, and CI runs them on every push:

```bash
flutter analyze && flutter test
```

Firestore security rules are tested separately, against the emulator. They are
a Node package rather than Dart, so `flutter test` does not pick them up — run
them from the repository root (needs Node and a JDK for the emulator):

```bash
npm ci --prefix test/firestore_rules && firebase emulators:exec --only firestore --project mesa-rules-test "npm --prefix test/firestore_rules test"
```

## Code generation

Riverpod providers and freezed models are generated. After changing anything
annotated, or any ARB file:

```bash
dart run build_runner build && flutter gen-l10n
```

## Google Sign-In

Google Sign-In needs the signing certificate's SHA-1 registered against **both**
Firebase Android apps, after which `google-services.json` must be re-downloaded
for each flavour. Print the debug fingerprint with:

```bash
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android -keypass android
```
