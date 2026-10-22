import { ChessComGame } from './chessComService';
import { PlaystyleProfile } from '../utils/playstyleAnalyzer';
import { TacticalPuzzle } from '../data/chessContent';

const DB_NAME = 'ChessFrDB';
const DB_VERSION = 1;
const STORE_GAMES = 'games';
const STORE_PROFILES = 'profiles';
const STORE_PUZZLES = 'puzzles';

function openDatabase(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    if (typeof window === 'undefined' || !window.indexedDB) {
      return reject(new Error('IndexedDB is not supported'));
    }

    const request = window.indexedDB.open(DB_NAME, DB_VERSION);

    request.onupgradeneeded = (event) => {
      const db = (event.target as IDBOpenDBRequest).result;
      if (!db.objectStoreNames.contains(STORE_GAMES)) {
        db.createObjectStore(STORE_GAMES, { keyPath: 'username' });
      }
      if (!db.objectStoreNames.contains(STORE_PROFILES)) {
        db.createObjectStore(STORE_PROFILES, { keyPath: 'username' });
      }
      if (!db.objectStoreNames.contains(STORE_PUZZLES)) {
        db.createObjectStore(STORE_PUZZLES, { keyPath: 'id' });
      }
    };

    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

/**
 * Saves games for a user into IndexedDB
 */
export async function saveCachedGames(username: string, games: ChessComGame[]): Promise<void> {
  try {
    const db = await openDatabase();
    const cleanUser = username.trim().toLowerCase();
    const tx = db.transaction(STORE_GAMES, 'readwrite');
    const store = tx.objectStore(STORE_GAMES);
    store.put({
      username: cleanUser,
      timestamp: Date.now(),
      games: games.slice(0, 150)
    });
  } catch (err) {
    console.warn('IndexedDB saveCachedGames failed:', err);
  }
}

/**
 * Loads cached games for a user from IndexedDB
 */
export async function loadCachedGames(username: string): Promise<ChessComGame[] | null> {
  try {
    const db = await openDatabase();
    const cleanUser = username.trim().toLowerCase();
    const tx = db.transaction(STORE_GAMES, 'readonly');
    const store = tx.objectStore(STORE_GAMES);
    return new Promise((resolve) => {
      const req = store.get(cleanUser);
      req.onsuccess = () => {
        if (req.result && Array.isArray(req.result.games)) {
          resolve(req.result.games);
        } else {
          resolve(null);
        }
      };
      req.onerror = () => resolve(null);
    });
  } catch (err) {
    console.warn('IndexedDB loadCachedGames failed:', err);
    return null;
  }
}

/**
 * Saves Playstyle profile into IndexedDB
 */
export async function saveCachedProfile(username: string, profile: PlaystyleProfile): Promise<void> {
  try {
    const db = await openDatabase();
    const cleanUser = username.trim().toLowerCase();
    const tx = db.transaction(STORE_PROFILES, 'readwrite');
    const store = tx.objectStore(STORE_PROFILES);
    store.put({
      username: cleanUser,
      timestamp: Date.now(),
      profile
    });
  } catch (err) {
    console.warn('IndexedDB saveCachedProfile failed:', err);
  }
}

/**
 * Loads cached Playstyle profile from IndexedDB
 */
export async function loadCachedProfile(username: string): Promise<PlaystyleProfile | null> {
  try {
    const db = await openDatabase();
    const cleanUser = username.trim().toLowerCase();
    const tx = db.transaction(STORE_PROFILES, 'readonly');
    const store = tx.objectStore(STORE_PROFILES);
    return new Promise((resolve) => {
      const req = store.get(cleanUser);
      req.onsuccess = () => {
        if (req.result && req.result.profile) {
          resolve(req.result.profile);
        } else {
          resolve(null);
        }
      };
      req.onerror = () => resolve(null);
    });
  } catch (err) {
    console.warn('IndexedDB loadCachedProfile failed:', err);
    return null;
  }
}

/**
 * Saves or updates a solved puzzle (caching its 3-move engine line)
 */
export async function cacheSolvedPuzzle(puzzle: TacticalPuzzle): Promise<void> {
  try {
    const db = await openDatabase();
    const tx = db.transaction(STORE_PUZZLES, 'readwrite');
    const store = tx.objectStore(STORE_PUZZLES);
    store.put(puzzle);
  } catch (err) {
    console.warn('IndexedDB cacheSolvedPuzzle failed:', err);
  }
}

/**
 * Retrieves a cached solved puzzle
 */
export async function getCachedSolvedPuzzle(puzzleId: string): Promise<TacticalPuzzle | null> {
  try {
    const db = await openDatabase();
    const tx = db.transaction(STORE_PUZZLES, 'readonly');
    const store = tx.objectStore(STORE_PUZZLES);
    return new Promise((resolve) => {
      const req = store.get(puzzleId);
      req.onsuccess = () => resolve(req.result || null);
      req.onerror = () => resolve(null);
    });
  } catch (err) {
    return null;
  }
}
