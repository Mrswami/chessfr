import React, { useState, useEffect } from 'react';
import {
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signInAnonymously,
  signOut,
  User
} from 'firebase/auth';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import {
  auth,
  db,
  signInWithGoogle,
  claimUsername,
  checkUsernameAvailable
} from '../services/firebase';
import {
  User as UserIcon,
  LogIn,
  UserPlus,
  LogOut,
  Link as LinkIcon,
  Check,
  AlertCircle,
  AtSign,
  ShieldCheck,
  Sparkles
} from 'lucide-react';

interface AuthModalProps {
  isOpen: boolean;
  onClose: () => void;
  currentUser: User | null;
  chessComUsername: string;
  onUpdateChessComUsername: (username: string) => void;
}

export const AuthModal: React.FC<AuthModalProps> = ({
  isOpen,
  onClose,
  currentUser,
  chessComUsername,
  onUpdateChessComUsername
}) => {
  const [isSignUp, setIsSignUp] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [inputUsername, setInputUsername] = useState(chessComUsername);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  // Unique Username Setup Step for Google Sign-In & New Accounts
  const [isClaimingHandle, setIsClaimingHandle] = useState(false);
  const [desiredHandle, setDesiredHandle] = useState('');
  const [isHandleAvailable, setIsHandleAvailable] = useState<boolean | null>(null);
  const [checkingHandle, setCheckingHandle] = useState(false);
  const [currentClaimUser, setCurrentClaimUser] = useState<User | null>(null);
  const [registeredHandle, setRegisteredHandle] = useState<string>('');

  // Fetch registered username when currentUser changes
  useEffect(() => {
    if (currentUser) {
      getDoc(doc(db, 'users', currentUser.uid)).then((snap) => {
        if (snap.exists() && snap.data()?.username) {
          setRegisteredHandle(snap.data().username);
        }
      });
    } else {
      setRegisteredHandle('');
    }
  }, [currentUser]);

  // Real-time debounce check for handle availability
  useEffect(() => {
    if (!desiredHandle || desiredHandle.trim().length < 3) {
      setIsHandleAvailable(null);
      return;
    }
    const timer = setTimeout(async () => {
      setCheckingHandle(true);
      const available = await checkUsernameAvailable(desiredHandle);
      setIsHandleAvailable(available);
      setCheckingHandle(false);
    }, 350);
    return () => clearTimeout(timer);
  }, [desiredHandle]);

  if (!isOpen) return null;

  // Google Sign-In flow with atomic unique handle verification
  const handleGoogleSignIn = async () => {
    setError(null);
    setLoading(true);
    try {
      const user = await signInWithGoogle();
      const userDocRef = doc(db, 'users', user.uid);
      const userSnap = await getDoc(userDocRef);

      if (userSnap.exists() && userSnap.data()?.username) {
        // User already has an established unique profile
        setSuccessMsg(`Welcome back, @${userSnap.data().username}!`);
        setTimeout(() => {
          onClose();
          setSuccessMsg(null);
        }, 900);
      } else {
        // First-time Google user: prompt for atomic unique handle claim
        const suggested = (user.displayName || user.email?.split('@')[0] || 'player')
          .toLowerCase()
          .replace(/[^a-z0-9_]/g, '_')
          .slice(0, 18);
        setDesiredHandle(suggested);
        setCurrentClaimUser(user);
        setIsClaimingHandle(true);
      }
    } catch (err: any) {
      setError(err.message || 'Google sign-in failed');
    } finally {
      setLoading(false);
    }
  };

  // Submit atomic handle reservation
  const handleConfirmHandleClaim = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!currentClaimUser) return;
    setError(null);
    setLoading(true);

    try {
      const claimed = await claimUsername(currentClaimUser.uid, desiredHandle, {
        email: currentClaimUser.email || undefined,
        displayName: currentClaimUser.displayName || undefined,
        chessComUsername: inputUsername || undefined
      });
      setRegisteredHandle(claimed);
      setSuccessMsg(`Reserved handle @${claimed}! Profile active.`);
      setTimeout(() => {
        setIsClaimingHandle(false);
        onClose();
        setSuccessMsg(null);
      }, 1000);
    } catch (err: any) {
      setError(err.message || 'Failed to claim handle.');
    } finally {
      setLoading(false);
    }
  };

  const handleAuth = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      if (isSignUp) {
        const cred = await createUserWithEmailAndPassword(auth, email, password);
        // Prompt for unique handle claim
        const suggested = email.split('@')[0].toLowerCase().replace(/[^a-z0-9_]/g, '_').slice(0, 18);
        setDesiredHandle(suggested);
        setCurrentClaimUser(cred.user);
        setIsClaimingHandle(true);
      } else {
        await signInWithEmailAndPassword(auth, email, password);
        setSuccessMsg('Signed in successfully!');
        setTimeout(() => {
          onClose();
          setSuccessMsg(null);
        }, 900);
      }
    } catch (err: any) {
      setError(err.message || 'Authentication failed');
    } finally {
      setLoading(false);
    }
  };

  const handleGuestLogin = async () => {
    setLoading(true);
    try {
      await signInAnonymously(auth);
      setSuccessMsg('Signed in as Guest!');
      setTimeout(() => {
        onClose();
        setSuccessMsg(null);
      }, 800);
    } catch (err: any) {
      setError(err.message || 'Guest sign-in failed');
    } finally {
      setLoading(false);
    }
  };

  const handleSaveChessCom = async () => {
    if (!inputUsername.trim()) return;
    try {
      setLoading(true);
      if (currentUser) {
        await setDoc(doc(db, 'users', currentUser.uid), {
          chessComUsername: inputUsername.trim()
        }, { merge: true });
      }
      onUpdateChessComUsername(inputUsername.trim());
      setSuccessMsg(`Connected Chess.com account: ${inputUsername}`);
      setTimeout(() => setSuccessMsg(null), 2000);
    } catch (err: any) {
      setError('Failed to update Chess.com connection');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <div className="modal-title">
            <UserIcon size={20} className="text-cyan-400" />
            <span>
              {isClaimingHandle
                ? 'Claim Unique ChessFr Handle'
                : currentUser
                ? 'User Profile & Connected Accounts'
                : (isSignUp ? 'Create ChessFr Account' : 'Sign In to ChessFr')}
            </span>
          </div>
          <button className="close-btn" onClick={onClose}>✕</button>
        </div>

        {error && (
          <div className="auth-alert alert-error">
            <AlertCircle size={16} />
            <span>{error}</span>
          </div>
        )}

        {successMsg && (
          <div className="auth-alert alert-success">
            <Check size={16} />
            <span>{successMsg}</span>
          </div>
        )}

        {/* STEP A: Claim Unique Handle Screen */}
        {isClaimingHandle ? (
          <form onSubmit={handleConfirmHandleClaim} className="auth-form">
            <div className="p-3 bg-slate-900/80 border border-slate-700 rounded-lg text-xs text-slate-300 mb-3 flex items-start gap-2">
              <ShieldCheck size={18} className="text-emerald-400 shrink-0 mt-0.5" />
              <div>
                <strong className="text-white block font-medium">Industry Standard Handle Lock:</strong>
                Usernames are globally unique and reserved atomically across all of ChessFr.
              </div>
            </div>

            <div className="form-field">
              <label>Choose Your Unique Handle</label>
              <div className="relative">
                <input
                  type="text"
                  required
                  placeholder="e.g. magnus_carlsen"
                  value={desiredHandle}
                  onChange={(e) => setDesiredHandle(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, ''))}
                  className="modal-input font-mono"
                  style={{ paddingLeft: '2rem' }}
                />
                <AtSign size={15} className="absolute left-2.5 top-3 text-slate-400" />
              </div>

              <div className="text-xs mt-1">
                {checkingHandle ? (
                  <span className="text-slate-400">Checking availability...</span>
                ) : isHandleAvailable === true ? (
                  <span className="text-emerald-400 font-semibold flex items-center gap-1">
                    <Check size={12} /> @{desiredHandle} is available!
                  </span>
                ) : isHandleAvailable === false ? (
                  <span className="text-rose-400 font-semibold">
                    ❌ @{desiredHandle} is already taken. Try another.
                  </span>
                ) : (
                  <span className="text-slate-500">3-20 characters (letters, numbers, underscores)</span>
                )}
              </div>
            </div>

            <div className="form-field">
              <label>Connect Chess.com Account (Optional)</label>
              <input
                type="text"
                placeholder="Chess.com username"
                value={inputUsername}
                onChange={(e) => setInputUsername(e.target.value)}
                className="modal-input"
              />
            </div>

            <button
              type="submit"
              className="action-btn action-btn-primary"
              style={{ width: '100%', padding: '0.75rem' }}
              disabled={loading || isHandleAvailable === false || !desiredHandle}
            >
              <Sparkles size={16} />
              <span>Claim Handle & Complete Profile</span>
            </button>
          </form>
        ) : currentUser ? (
          /* STEP B: Active User Profile */
          <div className="profile-details">
            <div className="profile-row">
              <span className="profile-label">Handle:</span>
              <span className="profile-val font-semibold text-cyan-300">
                {registeredHandle ? `@${registeredHandle}` : 'No handle registered'}
              </span>
            </div>

            <div className="profile-row">
              <span className="profile-label">Email / User ID:</span>
              <span className="profile-val">{currentUser.email || `Guest (${currentUser.uid.slice(0, 8)})`}</span>
            </div>

            {/* Chess.com account connect section */}
            <div className="chesscom-connect-card">
              <div className="chesscom-title">
                <LinkIcon size={16} className="text-emerald-400" />
                <span>Connect Chess.com Account</span>
              </div>
              <p className="chesscom-desc">
                Link your handle to automatically import your games, calculate your true blunder profile, and generate custom tactical drills.
              </p>
              <div className="input-group">
                <input
                  type="text"
                  placeholder="e.g. MagnusCarlsen"
                  value={inputUsername}
                  onChange={(e) => setInputUsername(e.target.value)}
                  className="modal-input"
                />
                <button
                  className="action-btn action-btn-primary"
                  onClick={handleSaveChessCom}
                  disabled={loading}
                >
                  Connect
                </button>
              </div>
            </div>

            <button
              className="action-btn"
              style={{ width: '100%', marginTop: '1rem', background: '#334155' }}
              onClick={() => signOut(auth)}
            >
              <LogOut size={16} />
              <span>Sign Out</span>
            </button>
          </div>
        ) : (
          /* STEP C: Sign In / Sign Up Form with Google */
          <div className="auth-form-container">
            {/* Google Sign-In Button */}
            <button
              type="button"
              onClick={handleGoogleSignIn}
              disabled={loading}
              className="google-signin-btn"
            >
              <svg width="18" height="18" viewBox="0 0 24 24">
                <path
                  fill="#4285F4"
                  d="M23.745 12.27c0-.7-.06-1.4-.19-2.07H12v4.51h6.6c-.29 1.52-1.14 2.8-2.4 3.66v3.05h3.88c2.27-2.09 3.66-5.17 3.66-9.15z"
                />
                <path
                  fill="#34A853"
                  d="M12 24c3.24 0 5.95-1.08 7.93-2.91l-3.88-3.05c-1.08.72-2.45 1.16-4.05 1.16-3.12 0-5.77-2.1-6.72-4.93H1.25v3.15C3.26 21.36 7.33 24 12 24z"
                />
                <path
                  fill="#FBBC05"
                  d="M5.28 14.27c-.25-.72-.38-1.49-.38-2.27s.13-1.55.38-2.27V6.58H1.25C.45 8.17 0 9.99 0 12s.45 3.83 1.25 5.42l4.03-3.15z"
                />
                <path
                  fill="#EA4335"
                  d="M12 4.75c1.77 0 3.35.61 4.6 1.8l3.42-3.42C17.95 1.19 15.24 0 12 0 7.33 0 3.26 2.64 1.25 6.58l4.03 3.15c.95-2.83 3.6-4.98 6.72-4.98z"
                />
              </svg>
              <span>Continue with Google</span>
            </button>

            <div className="divider"><span>OR WITH EMAIL</span></div>

            <form onSubmit={handleAuth} className="auth-form">
              <div className="form-field">
                <label>Email Address</label>
                <input
                  type="email"
                  required
                  placeholder="grandmaster@chessfr.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="modal-input"
                />
              </div>

              <div className="form-field">
                <label>Password</label>
                <input
                  type="password"
                  required
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="modal-input"
                />
              </div>

              <button
                type="submit"
                className="action-btn action-btn-primary"
                style={{ width: '100%', padding: '0.75rem' }}
                disabled={loading}
              >
                {isSignUp ? <UserPlus size={16} /> : <LogIn size={16} />}
                <span>{isSignUp ? 'Sign Up' : 'Sign In'}</span>
              </button>

              <div className="divider"><span>OR</span></div>

              <button
                type="button"
                className="action-btn"
                style={{ width: '100%', background: '#1e293b' }}
                onClick={handleGuestLogin}
                disabled={loading}
              >
                Continue as Guest
              </button>

              <div className="auth-toggle">
                {isSignUp ? 'Already have an account?' : "Don't have an account?"}{' '}
                <button
                  type="button"
                  className="link-btn"
                  onClick={() => { setIsSignUp(!isSignUp); setError(null); }}
                >
                  {isSignUp ? 'Sign In' : 'Create One'}
                </button>
              </div>
            </form>
          </div>
        )}
      </div>
    </div>
  );
};
