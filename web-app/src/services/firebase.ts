import { initializeApp } from 'firebase/app';
import {
  getAuth,
  GoogleAuthProvider,
  signInWithPopup,
  linkWithPopup,
  User
} from 'firebase/auth';
import {
  getFirestore,
  doc,
  getDoc,
  runTransaction,
  serverTimestamp
} from 'firebase/firestore';

const firebaseConfig = {
  projectId: "chessfr",
  appId: "1:681661810918:web:05df0861e23611a9059327",
  storageBucket: "chessfr.firebasestorage.app",
  apiKey: "AIzaSyCFCPhOgW0rGbd7Uuw1Y82oJDi529FP3eE",
  authDomain: "chessfr.firebaseapp.com",
  messagingSenderId: "681661810918",
  projectNumber: "681661810918"
};

export const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);

// Google Auth Provider setup
export const googleProvider = new GoogleAuthProvider();
googleProvider.setCustomParameters({ prompt: 'select_account' });

/**
 * Triggers Google Sign-In Popup
 */
export async function signInWithGoogle(): Promise<User> {
  const result = await signInWithPopup(auth, googleProvider);
  return result.user;
}

/**
 * Checks if a username is available in the global username registry
 */
export async function checkUsernameAvailable(rawUsername: string): Promise<boolean> {
  const clean = rawUsername.trim().toLowerCase();
  if (!clean || clean.length < 3) return false;
  try {
    const docRef = doc(db, 'usernames', clean);
    const snap = await getDoc(docRef);
    return !snap.exists();
  } catch (err) {
    console.error('Error checking username availability:', err);
    return false;
  }
}

/**
 * Atomically reserves a unique username and establishes/updates the user profile
 */
export async function claimUsername(
  uid: string,
  rawUsername: string,
  meta?: { email?: string; displayName?: string; chessComUsername?: string }
): Promise<string> {
  const cleanUsername = rawUsername.trim().toLowerCase();

  // Validate format: 3-20 characters, alphanumeric and underscores only
  if (!/^[a-zA-Z0-9_]{3,20}$/.test(cleanUsername)) {
    throw new Error('Username must be 3-20 characters and contain only letters, numbers, or underscores.');
  }

  return await runTransaction(db, async (transaction) => {
    const usernameDocRef = doc(db, 'usernames', cleanUsername);
    const usernameSnap = await transaction.get(usernameDocRef);

    if (usernameSnap.exists()) {
      const existingUid = usernameSnap.data()?.uid;
      // Allow if current user already owns it
      if (existingUid !== uid) {
        throw new Error(`Username @${cleanUsername} is already taken.`);
      }
    }

    const userDocRef = doc(db, 'users', uid);

    // 1. Lock the unique username document
    transaction.set(usernameDocRef, {
      uid,
      claimedAt: serverTimestamp()
    });

    // 2. Set profile data
    transaction.set(
      userDocRef,
      {
        uid,
        username: cleanUsername,
        email: meta?.email || null,
        displayName: meta?.displayName || cleanUsername,
        chessComUsername: meta?.chessComUsername || null,
        updatedAt: serverTimestamp()
      },
      { merge: true }
    );

    return cleanUsername;
  });
}
