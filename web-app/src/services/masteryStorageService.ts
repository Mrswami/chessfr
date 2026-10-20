import { doc, getDoc, setDoc, collection, getDocs, deleteDoc } from 'firebase/firestore';
import { db } from '../services/firebase';

export type MasteryStatus = 'needs_work' | 'reviewing' | 'mastered';

export interface UserPuzzleProgress {
  puzzleId: string;
  fen: string;
  theme: string;
  playedBlunder?: string;       // e.g. "Nxe4??"
  solutionUci: string[];        // 3-move plan sequence e.g. ["e2e4", "e7e5", "g1f3"]
  opponent?: string;
  gameDate?: string;
  attempts: number;
  successCount: number;
  consecutiveSolves: number;    // Needs 3 to be considered Mastered
  status: MasteryStatus;
  lastAttemptedAt: string;
  nextReviewAt: string;         // Spaced repetition timestamp
  isThreeMovePlan?: boolean;    // "Here is a position you are likely to see based on your games: what is the 3-move answer?"
  frequencyScore?: number;      // How often this position / structure occurred in their games
}

/**
 * Loads all persistent puzzle progress for a user from Firestore
 */
export async function loadUserPuzzleProgress(userId: string): Promise<Record<string, UserPuzzleProgress>> {
  try {
    const colRef = collection(db, 'users', userId, 'puzzle_progress');
    const snapshot = await getDocs(colRef);
    const progressMap: Record<string, UserPuzzleProgress> = {};
    snapshot.forEach((docSnap) => {
      progressMap[docSnap.id] = docSnap.data() as UserPuzzleProgress;
    });
    return progressMap;
  } catch (err) {
    console.error('Failed to load user puzzle progress:', err);
    return {};
  }
}

/**
 * Records a solve attempt and updates the spaced-repetition interval + familiarity status
 */
export async function recordPuzzleAttempt(
  userId: string,
  puzzleId: string,
  wasCorrect: boolean,
  currentRecord?: UserPuzzleProgress,
  puzzleMeta?: {
    fen: string;
    theme: string;
    playedBlunder?: string;
    solutionUci: string[];
    isThreeMovePlan?: boolean;
    frequencyScore?: number;
  }
): Promise<UserPuzzleProgress> {
  const attempts = (currentRecord?.attempts || 0) + 1;
  const successCount = (currentRecord?.successCount || 0) + (wasCorrect ? 1 : 0);
  const consecutiveSolves = wasCorrect ? ((currentRecord?.consecutiveSolves || 0) + 1) : 0;

  // Familiarity Level Status logic:
  // 3 consecutive solves = 'mastered'
  // 1-2 consecutive = 'reviewing'
  // 0 consecutive (failed attempt) = 'needs_work'
  let status: MasteryStatus = 'needs_work';
  if (consecutiveSolves >= 3) {
    status = 'mastered';
  } else if (consecutiveSolves >= 1) {
    status = 'reviewing';
  }

  // Spaced repetition interval in hours: 1hr -> 24hrs -> 72hrs -> 168hrs (7 days for mastered refresher)
  const intervalHours = status === 'mastered' ? 168 : (consecutiveSolves === 2 ? 48 : (consecutiveSolves === 1 ? 12 : 2));
  const nextReviewDate = new Date();
  nextReviewDate.setHours(nextReviewDate.getHours() + intervalHours);

  const updated: UserPuzzleProgress = {
    puzzleId,
    fen: currentRecord?.fen || puzzleMeta?.fen || '',
    theme: currentRecord?.theme || puzzleMeta?.theme || 'Personal Blunder Recovery',
    playedBlunder: currentRecord?.playedBlunder || puzzleMeta?.playedBlunder,
    solutionUci: currentRecord?.solutionUci || puzzleMeta?.solutionUci || [],
    attempts,
    successCount,
    consecutiveSolves,
    status,
    lastAttemptedAt: new Date().toISOString(),
    nextReviewAt: nextReviewDate.toISOString(),
    isThreeMovePlan: currentRecord?.isThreeMovePlan ?? puzzleMeta?.isThreeMovePlan ?? false,
    frequencyScore: currentRecord?.frequencyScore ?? puzzleMeta?.frequencyScore ?? 1
  };

  try {
    const docRef = doc(db, 'users', userId, 'puzzle_progress', puzzleId);
    await setDoc(docRef, updated, { merge: true });
  } catch (err) {
    console.error('Failed to save puzzle progress to Firestore:', err);
  }

  return updated;
}

export interface SavedPosition {
  id: string;
  fen: string;
  title: string;
  notes?: string;
  createdAt: string;
  playerColor: 'w' | 'b';
  solutionUci: string[];
  solutionSan: string[];
  evalCp?: number;
  sourceGameUrl?: string;
  tags?: string[];
}

/**
 * Loads all saved archive positions for a user
 */
export async function loadSavedPositions(userId: string): Promise<SavedPosition[]> {
  try {
    if (userId && userId !== 'guest_local') {
      const colRef = collection(db, 'users', userId, 'saved_positions');
      const snapshot = await getDocs(colRef);
      const items: SavedPosition[] = [];
      snapshot.forEach((d) => {
        items.push(d.data() as SavedPosition);
      });
      if (items.length > 0) {
        return items.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
      }
    }
  } catch (err) {
    console.error('Failed to load saved positions from Firestore:', err);
  }

  // Fallback to localStorage
  try {
    const raw = localStorage.getItem('chessfr_saved_positions');
    if (raw) return JSON.parse(raw);
  } catch (e) {}
  return [];
}

/**
 * Saves a position with its 3-move best line sequence to Firestore and localStorage
 */
export async function savePositionToArchive(
  userId: string,
  pos: SavedPosition
): Promise<void> {
  // Always update local storage for instant offline / guest access
  try {
    const raw = localStorage.getItem('chessfr_saved_positions');
    const existing: SavedPosition[] = raw ? JSON.parse(raw) : [];
    const filtered = existing.filter((p) => p.id !== pos.id && p.fen !== pos.fen);
    const updated = [pos, ...filtered];
    localStorage.setItem('chessfr_saved_positions', JSON.stringify(updated));
  } catch (e) {}

  if (userId && userId !== 'guest_local') {
    try {
      const docRef = doc(db, 'users', userId, 'saved_positions', pos.id);
      await setDoc(docRef, pos, { merge: true });
    } catch (err) {
      console.error('Failed to save position to Firestore:', err);
    }
  }
}

/**
 * Deletes a position from the archive
 */
export async function deleteSavedPosition(userId: string, positionId: string): Promise<void> {
  try {
    const raw = localStorage.getItem('chessfr_saved_positions');
    if (raw) {
      const existing: SavedPosition[] = JSON.parse(raw);
      const filtered = existing.filter((p) => p.id !== positionId);
      localStorage.setItem('chessfr_saved_positions', JSON.stringify(filtered));
    }
  } catch (e) {}

  if (userId && userId !== 'guest_local') {
    try {
      const docRef = doc(db, 'users', userId, 'saved_positions', positionId);
      await deleteDoc(docRef);
    } catch (err) {
      console.error('Failed to delete position from Firestore:', err);
    }
  }
}
