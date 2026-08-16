// Emulator tests for firestore.rules (§4.3).
//
// §11 asks for "emulator-based tests for every collection path", so every
// collection in §4 is exercised against three actors: the owner, a second
// signed-in account, and an unauthenticated client. The M1 acceptance
// criterion — "a second account sees none of the first account's data" — is
// the `OTHER` half of this file.
//
// Run from the repository root:
//   firebase emulators:exec --only firestore "npm --prefix test/firestore_rules test"

import { after, before, describe, it } from 'node:test';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, writeBatch } from 'firebase/firestore';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..');

const OWNER = 'user-a';
const OTHER = 'user-b';

/**
 * Every user-owned path in §4, relative to `users/{uid}`.
 *
 * Depth matters as much as breadth here: the rules rely on a single recursive
 * wildcard, so a subcollection three levels down has to be covered explicitly
 * rather than assumed.
 */
const PATHS = {
  profile: '',
  bodyweightEntry: 'bodyweightLog/entry-1',
  gym: 'gyms/gym-1',
  program: 'programs/program-1',
  day: 'programs/program-1/days/day-1',
  session: 'sessions/session-1',
  setLog: 'sessions/session-1/setLogs/set-1',
  exerciseStats: 'exerciseStats/0001',
  customExercise: 'customExercises/custom-1',
};

/** Builds the full document path for `uid`. */
function pathFor(uid, suffix) {
  return suffix === '' ? `users/${uid}` : `users/${uid}/${suffix}`;
}

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'mesa-rules-test',
    firestore: {
      rules: readFileSync(join(ROOT, 'firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });

  // Seed one document per path under the owner, bypassing the rules, so the
  // read tests below are denied by the rules rather than by absence.
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const suffix of Object.values(PATHS)) {
      await setDoc(doc(db, pathFor(OWNER, suffix)), { seeded: true });
    }
  });
});

after(async () => {
  await testEnv.cleanup();
});

describe('the owner', () => {
  for (const [name, suffix] of Object.entries(PATHS)) {
    it(`can read their own ${name}`, async () => {
      const db = testEnv.authenticatedContext(OWNER).firestore();
      await assertSucceeds(getDoc(doc(db, pathFor(OWNER, suffix))));
    });

    it(`can write their own ${name}`, async () => {
      const db = testEnv.authenticatedContext(OWNER).firestore();
      await assertSucceeds(
        setDoc(doc(db, pathFor(OWNER, suffix)), { written: true }),
      );
    });
  }
});

describe('a second account', () => {
  for (const [name, suffix] of Object.entries(PATHS)) {
    it(`cannot read another user's ${name}`, async () => {
      const db = testEnv.authenticatedContext(OTHER).firestore();
      await assertFails(getDoc(doc(db, pathFor(OWNER, suffix))));
    });

    it(`cannot write another user's ${name}`, async () => {
      const db = testEnv.authenticatedContext(OTHER).firestore();
      await assertFails(
        setDoc(doc(db, pathFor(OWNER, suffix)), { written: true }),
      );
    });
  }
});

describe('an unauthenticated client', () => {
  for (const [name, suffix] of Object.entries(PATHS)) {
    it(`cannot read any ${name}`, async () => {
      const db = testEnv.unauthenticatedContext().firestore();
      await assertFails(getDoc(doc(db, pathFor(OWNER, suffix))));
    });

    it(`cannot write any ${name}`, async () => {
      const db = testEnv.unauthenticatedContext().firestore();
      await assertFails(
        setDoc(doc(db, pathFor(OWNER, suffix)), { written: true }),
      );
    });
  }
});

// M3's activation writes three documents at once — the newly active program,
// the one it displaces, and `users/{uid}.activeProgramId` — because §4 stores
// the active program in two places and they must not drift. A batch is
// evaluated per document, so the interesting case is one that spans two
// accounts: it has to fail as a unit rather than partly land.
describe('a batch spanning the profile and its programs', () => {
  it('succeeds entirely within the owner\'s subtree', async () => {
    const db = testEnv.authenticatedContext(OWNER).firestore();
    const batch = writeBatch(db);

    batch.set(doc(db, pathFor(OWNER, 'programs/program-1')), { status: 'active' });
    batch.set(doc(db, pathFor(OWNER, 'programs/program-2')), { status: 'draft' });
    batch.set(doc(db, pathFor(OWNER, '')), { activeProgramId: 'program-1' });

    await assertSucceeds(batch.commit());
  });

  it('fails when one document in it belongs to another account', async () => {
    const db = testEnv.authenticatedContext(OTHER).firestore();
    const batch = writeBatch(db);

    // The second account's own program is fine; the owner's profile is not.
    batch.set(doc(db, pathFor(OTHER, 'programs/program-1')), { status: 'active' });
    batch.set(doc(db, pathFor(OWNER, '')), { activeProgramId: 'program-1' });

    await assertFails(batch.commit());
  });

  it('leaves the owner\'s profile untouched after that denial', async () => {
    // Atomicity is the point: a partly-applied batch would have written the
    // activeProgramId above into an account that did not authorise it.
    const db = testEnv.authenticatedContext(OWNER).firestore();
    const snapshot = await getDoc(doc(db, pathFor(OWNER, '')));

    if (snapshot.data()?.activeProgramId !== 'program-1') {
      throw new Error('expected the owner\'s own earlier batch to be the last write');
    }
  });
});

describe('outside the users subtree', () => {
  const foreignPaths = ['exercises/0001', 'config/app', 'anything/at/all/here'];

  for (const path of foreignPaths) {
    it(`denies a signed-in read of /${path}`, async () => {
      const db = testEnv.authenticatedContext(OWNER).firestore();
      await assertFails(getDoc(doc(db, path)));
    });

    it(`denies a signed-in write to /${path}`, async () => {
      const db = testEnv.authenticatedContext(OWNER).firestore();
      await assertFails(setDoc(doc(db, path), { written: true }));
    });
  }
});
