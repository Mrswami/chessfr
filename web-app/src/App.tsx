import React, { useState, useEffect } from 'react';
import { Chess, Square } from 'chess.js';
import confetti from 'canvas-confetti';
import { onAuthStateChanged, User } from 'firebase/auth';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { auth, db } from './services/firebase';
import {
  fetchRecentChessComGames,
  extractBlundersFromGames,
  generateCommonPositionalScenarios,
  generateChallengingVariationPuzzles,
  ChessComGame,
  FetchGamesOptions
} from './services/chessComService';
import {
  loadUserPuzzleProgress,
  recordPuzzleAttempt,
  UserPuzzleProgress,
  MasteryStatus,
  SavedPosition,
  loadSavedPositions,
  savePositionToArchive,
  deleteSavedPosition
} from './services/masteryStorageService';
import { InteractiveBoard, BoardArrow } from './components/InteractiveBoard';
import { EngineEvalBar } from './components/EngineEvalBar';
import { GameInsightsPanel, LoadedGameInfo } from './components/GameInsightsPanel';
import { TrainingModulesPanel } from './components/TrainingModulesPanel';
import { AuthModal } from './components/AuthModal';
import { PlaystyleAnalysisPanel } from './components/PlaystyleAnalysisPanel';
import { ChallengingVariationsPanel } from './components/ChallengingVariationsPanel';
import { DedicatedLoadingOverlay } from './components/DedicatedLoadingOverlay';
import { analyzePlaystyle, PlaystyleProfile, OpeningStats } from './utils/playstyleAnalyzer';
import {
  SAMPLE_PUZZLES,
  OPENING_REPERTOIRE,
  TacticalPuzzle,
  OpeningLine
} from './data/chessContent';
import {
  MoveAnalysis,
  classifyMove,
  calculateAccuracy,
  getMaterialEval,
  getEngineEval,
  formatEvalPoints,
  MOVE_NOTATION_MAP
} from './utils/analysisEngine';
import { evaluatePosition, findBestLine } from './utils/chessSearch';
import {
  BarChart3,
  Compass,
  GraduationCap,
  RotateCcw,
  User as UserIcon,
  RefreshCw,
  Sparkles,
  CheckCircle,
  AlertTriangle,
  Clock,
  Flame,
  HelpCircle,
  GitBranch,
  Lightbulb,
  Bookmark,
  Swords,
  ShieldAlert,
  SkipBack,
  ChevronLeft,
  ChevronRight,
  SkipForward
} from 'lucide-react';
import { OpeningTreePanel } from './components/OpeningTreePanel';
import { RecentGamesList } from './components/RecentGamesList';
import {
  buildOpeningTree,
  getTreeMovesForFen,
  OpeningTree,
  TreeMoveStats
} from './utils/openingTreeBuilder';

export function App() {
  const [chess] = useState<Chess>(new Chess());
  const [fen, setFen] = useState<string>(chess.fen());
  const [selectedSquare, setSelectedSquare] = useState<Square | null>(null);
  const [validMoves, setValidMoves] = useState<string[]>([]);
  const [lastMove, setLastMove] = useState<{ from: string; to: string } | null>(null);
  const [activeView, setActiveView] = useState<'playstyle' | 'games' | 'challenging' | 'insights' | 'tree' | 'training'>('playstyle');
  const [trainingTab, setTrainingTab] = useState<'puzzles' | 'openings' | 'archive'>('puzzles');
  const [currentPuzzle, setCurrentPuzzle] = useState<TacticalPuzzle>(SAMPLE_PUZZLES[0]);
  const [savedPositions, setSavedPositions] = useState<SavedPosition[]>([]);
  const [drillBestMoveArrow, setDrillBestMoveArrow] = useState<BoardArrow | null>(null);
  const [isBestMoveActive, setIsBestMoveActive] = useState<boolean>(false);
  const [openingTreeWhite, setOpeningTreeWhite] = useState<OpeningTree | null>(null);
  const [openingTreeBlack, setOpeningTreeBlack] = useState<OpeningTree | null>(null);
  const [treeColor, setTreeColor] = useState<'white' | 'black'>('white');
  const [treeLineSan, setTreeLineSan] = useState<string[]>([]);
  const [gamesFilter, setGamesFilter] = useState<FetchGamesOptions>({
    limit: 100,
    timeControl: 'all',
    ratedOnly: false
  });
  const [totalGamesAnalyzed, setTotalGamesAnalyzed] = useState<number>(0);
  const [showArrows, setShowArrows] = useState<boolean>(true);
  const [puzzleStep, setPuzzleStep] = useState<number>(0);
  const [puzzleFeedback, setPuzzleFeedback] = useState<string | null>(null);
  const [puzzleError, setPuzzleError] = useState<boolean>(false);
  const [boardOrientation, setBoardOrientation] = useState<'w' | 'b'>('w');
  const [moveHistory, setMoveHistory] = useState<MoveAnalysis[]>([]);
  const [currentMoveIdx, setCurrentMoveIdx] = useState<number>(-1);
  const [evaluation, setEvaluation] = useState<number>(35); // centipawns
  const [puzzleSolved, setPuzzleSolved] = useState<boolean>(false);
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [isAuthOpen, setIsAuthOpen] = useState<boolean>(false);
  const [chessComUsername, setChessComUsername] = useState<string>('');
  const [puzzlesList, setPuzzlesList] = useState<TacticalPuzzle[]>(SAMPLE_PUZZLES);
  const [progressMap, setProgressMap] = useState<Record<string, UserPuzzleProgress>>({});
  const [isSyncing, setIsSyncing] = useState<boolean>(false);
  const [isInitialLoading, setIsInitialLoading] = useState<boolean>(true);
  const [syncStatus, setSyncStatus] = useState<string | null>(null);
  const [playstyleProfile, setPlaystyleProfile] = useState<PlaystyleProfile | null>(null);
  const [recentGames, setRecentGames] = useState<ChessComGame[]>([]);
  const [loadedAnalyzedGame, setLoadedAnalyzedGame] = useState<LoadedGameInfo | null>(null);

  // Load local progress & persistent chess.com account cache & saved positions on mount
  useEffect(() => {
    let hasLoaded = false;
    try {
      const cached = localStorage.getItem('chessfr_puzzle_progress');
      if (cached) {
        setProgressMap(JSON.parse(cached));
      }
      const cachedSaved = localStorage.getItem('chessfr_saved_positions');
      if (cachedSaved) {
        setSavedPositions(JSON.parse(cachedSaved));
      }
      const cachedUser = localStorage.getItem('chessfr_chesscom_username');
      if (cachedUser) {
        setChessComUsername(cachedUser);
        loadChessComGames(cachedUser);
        hasLoaded = true;
      }
    } catch (e) {
      // Ignore local storage error
    } finally {
      if (!hasLoaded) {
        // Quick splash for guest mode initial page load
        setTimeout(() => setIsInitialLoading(false), 900);
      }
    }
  }, []);

  // Monitor Firebase Auth & sync cloud progress and persistent cloud profile
  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (user) => {
      setCurrentUser(user);
      if (user) {
        setIsInitialLoading(true);
        setSyncStatus(`Signing in @${user.email?.split('@')[0]} & loading cloud repertoire...`);
        try {
          // Load cloud puzzle progress
          const cloudProgress = await loadUserPuzzleProgress(user.uid);
          if (cloudProgress && Object.keys(cloudProgress).length > 0) {
            setProgressMap((prev) => {
              const merged = { ...prev, ...cloudProgress };
              localStorage.setItem('chessfr_puzzle_progress', JSON.stringify(merged));
              return merged;
            });
          }

          // Load cloud saved positions
          const cloudSaved = await loadSavedPositions(user.uid);
          if (cloudSaved && cloudSaved.length > 0) {
            setSavedPositions(cloudSaved);
          }

          const userDoc = await getDoc(doc(db, 'users', user.uid));
          if (userDoc.exists() && userDoc.data()?.chessComUsername) {
            const handle = userDoc.data().chessComUsername;
            setChessComUsername(handle);
            try {
              localStorage.setItem('chessfr_chesscom_username', handle);
            } catch (e) {}
            await loadChessComGames(handle, user.uid);
          } else {
            // If user has local handle stored, sync it up to their new cloud account
            const localHandle = localStorage.getItem('chessfr_chesscom_username');
            if (localHandle) {
              await setDoc(doc(db, 'users', user.uid), { chessComUsername: localHandle }, { merge: true });
              await loadChessComGames(localHandle, user.uid);
            }
          }
        } catch (e) {
          console.error('Error loading user profile:', e);
        } finally {
          setIsInitialLoading(false);
          setTimeout(() => setSyncStatus(null), 4000);
        }
      }
    });
    return () => unsub();
  }, []);

  const loadChessComGames = async (username: string, uid?: string, customFilters?: FetchGamesOptions) => {
    if (!username) return;
    const activeFilters = customFilters || gamesFilter;
    setIsSyncing(true);
    setSyncStatus(`Syncing up to ${activeFilters.limit ?? 100} games from Chess.com for @${username}...`);
    try {
      const games = await fetchRecentChessComGames(username, activeFilters);
      setRecentGames(games);
      setTotalGamesAnalyzed(games.length);
      if (games.length > 0) {
        // 1. Extract blunders in BOTH won and lost games
        const blunderPuzzles = extractBlundersFromGames(games, username);

        // 2. Identify common positional scenarios based on positional history
        const commonScenarioPuzzles = generateCommonPositionalScenarios(games, username);

        // Compute Playstyle & Opening Conduciveness Diagnostics
        const style = analyzePlaystyle(games, username);
        setPlaystyleProfile(style);

        // 3. Extract custom pattern puzzles from Most Challenging Variations (thematic losses)
        const challengingVariationPuzzles = generateChallengingVariationPuzzles(style.problematicOpenings);

        const allCustomPuzzles = [
          ...challengingVariationPuzzles,
          ...commonScenarioPuzzles,
          ...blunderPuzzles,
          ...SAMPLE_PUZZLES
        ];
        
        // Sort puzzles: Needs Work first, Reviewing second, Mastered refreshers
        allCustomPuzzles.sort((a, b) => {
          const progA = progressMap[a.id];
          const progB = progressMap[b.id];
          const order = { needs_work: 0, reviewing: 1, mastered: 2 };
          const statusA = progA?.status || 'needs_work';
          const statusB = progB?.status || 'needs_work';
          return (order[statusA] || 0) - (order[statusB] || 0);
        });

        setPuzzlesList(allCustomPuzzles);
        if (allCustomPuzzles.length > 0) {
          handleSelectPuzzle(allCustomPuzzles[0]);
        }

        // 3. Build personal opening trees for White & Black (openingtree.com style)
        const treeW = buildOpeningTree(games, username, 'white');
        const treeB = buildOpeningTree(games, username, 'black');
        setOpeningTreeWhite(treeW);
        setOpeningTreeBlack(treeB);

        setSyncStatus(
          `Analyzed ${games.length} games! Built Opening Tree, extracted ${blunderPuzzles.length} blunders (won/lost games) & generated ${commonScenarioPuzzles.length} 3-move scenarios.`
        );
      } else {
        setSyncStatus(`No recent games found for @${username}.`);
      }
    } catch (e) {
      setSyncStatus('Failed to sync Chess.com games.');
    } finally {
      setIsSyncing(false);
      setIsInitialLoading(false);
      setTimeout(() => setSyncStatus(null), 6000);
    }
  };

  // Sync board state & eval
  const refreshBoard = () => {
    setFen(chess.fen());
    const matEval = getMaterialEval(chess);
    setEvaluation(matEval);
  };

  // Select puzzle and reset solving state
  const handleSelectPuzzle = (p: TacticalPuzzle) => {
    setCurrentPuzzle(p);
    chess.load(p.fen);
    setBoardOrientation(p.playerColor);
    setLastMove(null);
    setSelectedSquare(null);
    setValidMoves([]);
    setPuzzleSolved(false);
    setPuzzleStep(0);
    setPuzzleFeedback(null);
    setPuzzleError(false);
    setDrillBestMoveArrow(null);
    setIsBestMoveActive(false);
    refreshBoard();
  };

  // Square Click handler for moves
  const handleSquareClick = (square: Square) => {
    if (selectedSquare) {
      if (selectedSquare === square) {
        setSelectedSquare(null);
        setValidMoves([]);
        return;
      }

      // Attempt move
      const evalBefore = evaluation;
      try {
        const move = chess.move({
          from: selectedSquare,
          to: square,
          promotion: 'q'
        });

        if (move) {
          const evalAfter = getMaterialEval(chess);
          const isSac = Boolean(move.captured) === false && ['q', 'r'].includes(move.piece);
          const rating = classifyMove(evalBefore, evalAfter, move.color, isSac, evalAfter > 0);
          const cpl = Math.abs(evalBefore - evalAfter);

          const analysis: MoveAnalysis = {
            san: move.san,
            from: move.from,
            to: move.to,
            color: move.color,
            evalBefore,
            evalAfter,
            centipawnLoss: cpl,
            rating
          };

          const newHistory = [...moveHistory, analysis];
          setMoveHistory(newHistory);
          setCurrentMoveIdx(newHistory.length - 1);
          setLastMove({ from: move.from, to: move.to });
          setSelectedSquare(null);
          setValidMoves([]);
          refreshBoard();

          // Check tactical puzzle solution with 3-move plan handling
          if (activeView === 'training') {
            handlePuzzleMoveAttempt(move);
            return;
          }

          // Trigger basic bot reply in Insights demo if game not ended
          if (activeView === 'insights' && !chess.isGameOver()) {
            setTimeout(() => {
              makeBotReply();
            }, 400);
          }
          return;
        }
      } catch (err) {
        // Invalid move, fall through to piece selection
      }
    }

    // Select new piece
    const piece = chess.get(square);
    if (piece && piece.color === chess.turn()) {
      setSelectedSquare(square);
      const moves = chess.moves({ square, verbose: true });
      setValidMoves(moves.map((m) => m.to));
    } else {
      setSelectedSquare(null);
      setValidMoves([]);
    }
  };

  /**
   * Evaluates sequential moves for 3-move plans & spaced repetition mastery
   */
  const handlePuzzleMoveAttempt = async (move: { from: string; to: string; san: string }) => {
    const moveUci = `${move.from}${move.to}`;
    const solution = currentPuzzle.solutionUci || [];
    const expectedMoveUci = solution[puzzleStep];

    const isCorrect = solution.length > 0
      ? (expectedMoveUci === moveUci || solution.includes(moveUci))
      : true;

    if (isCorrect) {
      setPuzzleError(false);
      const nextStep = puzzleStep + 1;

      // If there's an immediate opponent response in the sequence
      if (nextStep < solution.length) {
        const userMoveNum = Math.floor(puzzleStep / 2) + 1;
        setPuzzleFeedback(`Move ${userMoveNum} of 3-move plan is correct! Opponent responding...`);
        
        setTimeout(() => {
          let oppMove: any = null;
          let playedFrom: Square | null = null;
          let playedTo: Square | null = null;

          const oppUci = solution[nextStep];
          if (oppUci && oppUci.length >= 4) {
            const oppFrom = oppUci.slice(0, 2) as Square;
            const oppTo = oppUci.slice(2, 4) as Square;
            try {
              oppMove = chess.move({ from: oppFrom, to: oppTo, promotion: 'q' });
              if (oppMove) {
                playedFrom = oppFrom;
                playedTo = oppTo;
              }
            } catch (e) {
              // Ignore move error
            }
          }

          // Fallback if oppUci was illegal or empty: play highest heuristic / legal reply
          if (!oppMove && !chess.isGameOver()) {
            const legalReplies = chess.moves({ verbose: true });
            if (legalReplies.length > 0) {
              const fallback = legalReplies[0];
              oppMove = chess.move(fallback);
              if (oppMove) {
                playedFrom = fallback.from as Square;
                playedTo = fallback.to as Square;
              }
            }
          }

          if (oppMove && playedFrom && playedTo) {
            setLastMove({ from: playedFrom, to: playedTo });
            refreshBoard();
            setPuzzleStep(nextStep + 1);
            const nextUserMoveNum = Math.floor((nextStep + 1) / 2) + 1;
            setPuzzleFeedback(`Opponent played ${oppMove.san}. Find Move ${nextUserMoveNum} of your 3-move answer!`);
          } else {
            // No moves possible or game over: mark completed
            setPuzzleSolved(true);
            confetti({ particleCount: 85, spread: 70, origin: { y: 0.7 } });
          }
        }, 450);
      } else {
        // All steps of the 3-move plan completed!
        setPuzzleSolved(true);
        confetti({ particleCount: 85, spread: 70, origin: { y: 0.7 } });

        // Record attempt in spaced repetition mastery storage
        const userId = currentUser ? currentUser.uid : 'guest_local';
        const updatedRecord = await recordPuzzleAttempt(
          userId,
          currentPuzzle.id,
          true,
          progressMap[currentPuzzle.id],
          {
            fen: currentPuzzle.fen,
            theme: currentPuzzle.theme,
            playedBlunder: currentPuzzle.playedBlunder,
            solutionUci: currentPuzzle.solutionUci,
            isThreeMovePlan: currentPuzzle.isThreeMovePlan,
            frequencyScore: currentPuzzle.frequencyScore
          }
        );

        // Update local state and cache
        const nextMap = { ...progressMap, [currentPuzzle.id]: updatedRecord };
        setProgressMap(nextMap);
        try {
          localStorage.setItem('chessfr_puzzle_progress', JSON.stringify(nextMap));
        } catch (e) {
          // Ignore
        }

        if (updatedRecord.consecutiveSolves >= 3) {
          setPuzzleFeedback(`🎉 Mastered! Solved 3 consecutive times over spaced intervals. This position will reappear periodically for refresher testing.`);
        } else {
          setPuzzleFeedback(`✨ Solved! (${updatedRecord.consecutiveSolves}/3 solves toward Mastery).`);
        }
      }
    } else {
      // Incorrect move
      setPuzzleError(true);
      setPuzzleFeedback(`Incorrect move. In your game / optimal plan, that gives away the advantage.`);

      const userId = currentUser ? currentUser.uid : 'guest_local';
      const updatedRecord = await recordPuzzleAttempt(
        userId,
        currentPuzzle.id,
        false,
        progressMap[currentPuzzle.id],
        {
          fen: currentPuzzle.fen,
          theme: currentPuzzle.theme,
          playedBlunder: currentPuzzle.playedBlunder,
          solutionUci: currentPuzzle.solutionUci,
          isThreeMovePlan: currentPuzzle.isThreeMovePlan,
          frequencyScore: currentPuzzle.frequencyScore
        }
      );

      const nextMap = { ...progressMap, [currentPuzzle.id]: updatedRecord };
      setProgressMap(nextMap);
      try {
        localStorage.setItem('chessfr_puzzle_progress', JSON.stringify(nextMap));
      } catch (e) {
        // Ignore
      }

      // Revert board after brief delay so user can try again
      setTimeout(() => {
        chess.load(currentPuzzle.fen);
        setPuzzleStep(0);
        setLastMove(null);
        setSelectedSquare(null);
        setValidMoves([]);
        refreshBoard();
        setPuzzleError(false);
      }, 900);
    }
  };

  // Simple auto-reply generator for demo game review
  const makeBotReply = () => {
    if (chess.isGameOver()) return;
    const moves = chess.moves({ verbose: true });
    if (moves.length === 0) return;
    const randomMove = moves[Math.floor(Math.random() * moves.length)];
    const evalBefore = evaluation;

    const move = chess.move(randomMove);
    if (move) {
      const evalAfter = getMaterialEval(chess);
      const rating = classifyMove(evalBefore, evalAfter, move.color, false, false);
      const cpl = Math.abs(evalBefore - evalAfter);

      const analysis: MoveAnalysis = {
        san: move.san,
        from: move.from,
        to: move.to,
        color: move.color,
        evalBefore,
        evalAfter,
        centipawnLoss: cpl,
        rating
      };

      const newHistory = [...moveHistory, analysis];
      setMoveHistory(newHistory);
      setCurrentMoveIdx(newHistory.length - 1);
      setLastMove({ from: move.from, to: move.to });
      refreshBoard();
    }
  };

  const handleReset = () => {
    chess.reset();
    setLastMove(null);
    setSelectedSquare(null);
    setValidMoves([]);
    setMoveHistory([]);
    setCurrentMoveIdx(-1);
    setPuzzleSolved(false);
    setPuzzleStep(0);
    setPuzzleFeedback(null);
    setLoadedAnalyzedGame(null);
    refreshBoard();
  };

  /**
   * Loads a full Chess.com game into the Game Review analysis engine
   */
  const handleAnalyzeGame = (game: ChessComGame) => {
    if (!game.pgn) return;

    try {
      const isUserWhite = game.white.username.toLowerCase() === chessComUsername.toLowerCase();
      // Strip clock annotations, eval comments, and non-standard tags for safe parsing
      const cleanPgn = (game.pgn || '')
        .replace(/\{[^}]*\}/g, '')
        .replace(/\$\d+/g, '')
        .trim();

      const pgnChess = new Chess();
      try {
        pgnChess.loadPgn(cleanPgn);
      } catch (err) {
        // Fallback to original pgn
        pgnChess.loadPgn(game.pgn);
      }
      const history = pgnChess.history({ verbose: true });

      const newHistory: MoveAnalysis[] = [];
      const replayChess = new Chess();
      let lastEval = getMaterialEval(replayChess);

      for (let i = 0; i < history.length; i++) {
        const move = history[i];
        const evalBefore = lastEval;
        replayChess.move(move);
        const evalAfter = evaluatePosition(replayChess);
        const isSac = Boolean(move.captured) === false && ['q', 'r'].includes(move.piece);
        const rating = classifyMove(evalBefore, evalAfter, move.color, isSac, evalAfter > 0);
        const cpl = Math.abs(evalBefore - evalAfter);

        newHistory.push({
          san: move.san,
          from: move.from,
          to: move.to,
          color: move.color,
          evalBefore,
          evalAfter,
          centipawnLoss: cpl,
          rating
        });
        lastEval = evalAfter;
      }

      setMoveHistory(newHistory);
      
      // Start position at the beginning of the game (Move 1 / starting board)
      chess.reset();
      setCurrentMoveIdx(-1);
      setBoardOrientation(isUserWhite ? 'w' : 'b');
      setLastMove(null);
      setEvaluation(newHistory.length > 0 ? (newHistory[0].evalBefore ?? 0) : 0);

      const dateStr = game.end_time ? new Date(game.end_time * 1000).toLocaleDateString() : '';
      const userResult = isUserWhite ? game.white.result : game.black.result;
      const outcomeLabel = userResult === 'win' ? 'Won' : ['agreed', 'repetition', 'stalemate', 'timevsinsufficient', 'insufficient'].includes(userResult) ? 'Drawn' : 'Lost';

      setLoadedAnalyzedGame({
        whiteUsername: game.white.username,
        whiteRating: game.white.rating,
        blackUsername: game.black.username,
        blackRating: game.black.rating,
        result: `${outcomeLabel} (${game.white.result} vs ${game.black.result})`,
        url: game.url,
        dateStr
      });

      refreshBoard();
      setActiveView('insights');
      setSyncStatus(`Loaded game vs @${isUserWhite ? game.black.username : game.white.username} into Game Review (${newHistory.length} moves).`);
      setTimeout(() => setSyncStatus(null), 5000);
    } catch (e) {
      setSyncStatus('Failed to parse game PGN.');
      setTimeout(() => setSyncStatus(null), 4000);
    }
  };

  /**
   * Navigates to a specific ply in the loaded game review
   */
  const handleSelectReviewMove = (targetIdx: number) => {
    if (targetIdx < -1 || targetIdx >= moveHistory.length) return;

    chess.reset();
    for (let i = 0; i <= targetIdx; i++) {
      chess.move(moveHistory[i].san);
    }
    setCurrentMoveIdx(targetIdx);
    if (targetIdx >= 0) {
      const current = moveHistory[targetIdx];
      setLastMove({ from: current.from, to: current.to });
      setEvaluation(current.evalAfter);
    } else {
      setLastMove(null);
      setEvaluation(0);
    }
    setFen(chess.fen());
  };

  /**
   * Practicing the 3-move response pattern for a challenging variation
   */
  const handlePracticeChallengingPattern = (opening: OpeningStats) => {
    if (!opening.criticalFen) return;

    const pattern = opening.challengingPattern;
    const playerColor: 'w' | 'b' = opening.playedAs === 'Black' ? 'b' : 'w';

    const customDrill: TacticalPuzzle = {
      id: `challenging-var-${opening.eco}-${Date.now()}`,
      title: `Challenging Variation: ${opening.name}`,
      theme: pattern?.theme || 'Challenging Variation Pattern',
      rating: 1450,
      description: `In this recurring loss variation (${opening.winRate}% win rate), you faced: ${pattern?.problemDescription || 'a positional breakdown'}. What is the correct 3-move response to overcome or avoid this trap?`,
      fen: opening.criticalFen,
      solutionUci: pattern?.solutionUci || [],
      solutionSan: pattern?.solutionSan || [],
      playerColor,
      explanation: pattern?.actionableAdvice || `Optimal continuation is ${pattern?.solutionSan.join(' ') || 'to challenge the center'}.`,
      isThreeMovePlan: true
    };

    setPuzzlesList((prev) => [customDrill, ...prev.filter(p => p.id !== customDrill.id)]);
    handleSelectPuzzle(customDrill);
    setActiveView('training');
    setTrainingTab('puzzles');
    setSyncStatus(`Loaded 3-move pattern drill for ${opening.name}! Solve the critical position.`);
    setTimeout(() => setSyncStatus(null), 5000);
  };

  const handleSelectOpening = (op: OpeningLine) => {
    chess.reset();
    setBoardOrientation('w');
    const newHistory: MoveAnalysis[] = [];

    for (const moveSan of op.moves) {
      const m = chess.move(moveSan);
      if (m) {
        newHistory.push({
          san: m.san,
          from: m.from,
          to: m.to,
          color: m.color,
          evalBefore: 0,
          evalAfter: 0,
          centipawnLoss: 0,
          rating: 'book'
        });
      }
    }
    setMoveHistory(newHistory);
    setCurrentMoveIdx(newHistory.length - 1);
    if (newHistory.length > 0) {
      const last = newHistory[newHistory.length - 1];
      setLastMove({ from: last.from, to: last.to });
    }
    refreshBoard();
  };

  const whiteAcc = calculateAccuracy(moveHistory, 'w');
  const blackAcc = calculateAccuracy(moveHistory, 'b');

  const currentProg = progressMap[currentPuzzle.id];
  const currentStatus: MasteryStatus = currentProg?.status || 'needs_work';
  const consecutiveSolves = currentProg?.consecutiveSolves || 0;

  // Calculate candidate moves from opening tree for the current board FEN
  const candidateMoves = getTreeMovesForFen(treeColor === 'white' ? openingTreeWhite : openingTreeBlack, fen);
  const boardArrows: BoardArrow[] = (showArrows && activeView === 'tree')
    ? candidateMoves.slice(0, 5).map(m => ({
        from: m.uci.slice(0, 2),
        to: m.uci.slice(2, 4),
        frequency: m.frequency,
        winRate: m.winRate
      }))
    : (activeView === 'training' && drillBestMoveArrow)
    ? [drillBestMoveArrow]
    : [];

  // Toggle/display best move for the active 3-move drill step
  const handleToggleBestMove = () => {
    if (isBestMoveActive) {
      setDrillBestMoveArrow(null);
      setIsBestMoveActive(false);
      return;
    }

    const solution = currentPuzzle.solutionUci || [];
    const targetMoveUci = solution[puzzleStep];
    if (targetMoveUci && targetMoveUci.length >= 4) {
      const from = targetMoveUci.slice(0, 2);
      const to = targetMoveUci.slice(2, 4);
      setDrillBestMoveArrow({
        from,
        to,
        winRate: 85,
        frequency: 90
      });
      setIsBestMoveActive(true);
      const targetSan = currentPuzzle.solutionSan ? currentPuzzle.solutionSan[puzzleStep] : targetMoveUci;
      setPuzzleFeedback(`💡 Best move is ${targetSan} (${from} → ${to}). Play it to continue your 3-move plan!`);
    } else {
      // Compute engine best move dynamically from current position
      const best = findBestLine(chess, 3);
      if (best && best.bestMove) {
        const from = best.bestMove.slice(0, 2);
        const to = best.bestMove.slice(2, 4);
        setDrillBestMoveArrow({
          from,
          to,
          winRate: 85,
          frequency: 90
        });
        setIsBestMoveActive(true);
        setPuzzleFeedback(`💡 Best move is ${best.bestSan} (${from} → ${to}).`);
      }
    }
  };

  // Save current position to personal positional archive
  const handleSavePosition = async () => {
    const currentFen = chess.fen();
    const best = findBestLine(chess, 3);
    const userId = currentUser ? currentUser.uid : 'guest_local';
    const posId = `pos-${Date.now()}`;
    const title = currentPuzzle.isThreeMovePlan
      ? `${currentPuzzle.title} (Custom Save)`
      : `Struggling Position (${chess.turn() === 'w' ? 'White' : 'Black'} to move)`;

    const newPos: SavedPosition = {
      id: posId,
      fen: currentFen,
      title,
      notes: `Saved from ${activeView === 'training' ? '3-Move Drill' : 'Game Analysis'}. Found best 3-move continuation: ${best?.lineSan.join(' ') || 'N/A'}.`,
      createdAt: new Date().toISOString(),
      playerColor: chess.turn(),
      solutionUci: best ? best.line : (currentPuzzle.solutionUci || []),
      solutionSan: best ? best.lineSan : (currentPuzzle.solutionSan || []),
      evalCp: best?.eval
    };

    await savePositionToArchive(userId, newPos);
    setSavedPositions((prev) => [newPos, ...prev.filter(p => p.fen !== currentFen)]);
    setSyncStatus(`Saved position to your Positional Archive! You can test yourself anytime in Drills → Positional Archive.`);
    setTimeout(() => setSyncStatus(null), 5000);
  };

  // Load and test a saved archive position as a drill
  const handleTestSavedPosition = (pos: SavedPosition) => {
    const customDrill: TacticalPuzzle = {
      id: pos.id,
      title: pos.title,
      theme: 'Archived Weakness Drill',
      rating: 1400,
      description: 'Here is a position you saved to your personal archive. What is the three move answer to this position?',
      fen: pos.fen,
      solutionUci: pos.solutionUci,
      solutionSan: pos.solutionSan,
      playerColor: pos.playerColor,
      explanation: `From your personal archive, the optimal 3-move response is ${pos.solutionSan.join(' ')}.`,
      isThreeMovePlan: true
    };
    setPuzzlesList((prev) => [customDrill, ...prev.filter(p => p.id !== customDrill.id)]);
    handleSelectPuzzle(customDrill);
    setActiveView('training');
    setTrainingTab('puzzles');
    setSyncStatus(`Loaded position from archive! Test your 3-move response.`);
    setTimeout(() => setSyncStatus(null), 4000);
  };

  const handleDeletePosition = async (posId: string) => {
    const userId = currentUser ? currentUser.uid : 'guest_local';
    await deleteSavedPosition(userId, posId);
    setSavedPositions((prev) => prev.filter(p => p.id !== posId));
  };

  return (
    <div>
      {/* Navigation Header */}
      <header className="app-header">
        <div className="brand">
          <span>♟️ ChessFr</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '0.6rem' }}>
          {chessComUsername && (
            <button
              className="action-btn"
              style={{
                fontSize: '0.75rem',
                padding: '0.35rem 0.65rem',
                background: 'rgba(16, 185, 129, 0.15)',
                color: '#34d399',
                borderColor: 'rgba(16, 185, 129, 0.3)'
              }}
              onClick={() => loadChessComGames(chessComUsername, currentUser?.uid)}
              disabled={isSyncing}
              title="Resync Chess.com games"
            >
              <RefreshCw size={13} className={isSyncing ? 'animate-spin' : ''} />
              <span>@{chessComUsername}</span>
            </button>
          )}

          <button
            className="action-btn"
            style={{ fontSize: '0.75rem', padding: '0.35rem 0.65rem' }}
            onClick={() => setIsAuthOpen(true)}
          >
            <UserIcon size={14} />
            <span>{currentUser ? (currentUser.email ? currentUser.email.split('@')[0] : 'Profile') : 'Sign In'}</span>
          </button>

          <div className="domain-pill">chessfr.web.app</div>
        </div>
      </header>

      {/* Dedicated AI Loading Screen on Initial Load & Sign-in Sync */}
      {(isInitialLoading || (isSyncing && recentGames.length === 0)) && (
        <DedicatedLoadingOverlay
          statusMessage={
            syncStatus || (currentUser ? 'Synchronizing cloud profile & recent games...' : 'Initializing chessfr neural engine & repertoire...')
          }
          subMessage={
            chessComUsername
              ? `Crunching @${chessComUsername}'s games, blunders & 3-move response patterns`
              : 'Loading tactical puzzles, mastery storage & master opening trees'
          }
        />
      )}

      {/* Sync Status Banner */}
      {syncStatus && !isInitialLoading && (
        <div className="sync-banner">
          <Sparkles size={16} className="text-cyan-400" />
          <span>{syncStatus}</span>
        </div>
      )}

      {/* Main Container */}
      <main className="app-container">
        {/* Left Side: Chessboard & Controls */}
        <section>
          {/* Active Training Status & Prompt Card */}
          {activeView === 'training' && (
            <div className="training-status-card">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2 flex-wrap">
                  {currentStatus === 'mastered' ? (
                    <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-bold bg-emerald-500/20 text-emerald-300 border border-emerald-500/40">
                      <CheckCircle size={13} className="text-emerald-400" />
                      MASTERED ({consecutiveSolves}/3 • Spaced Refresher)
                    </span>
                  ) : currentStatus === 'reviewing' ? (
                    <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-bold bg-amber-500/20 text-amber-300 border border-amber-500/40">
                      <Clock size={13} className="text-amber-400" />
                      REVIEWING ({consecutiveSolves}/3 Solves)
                    </span>
                  ) : (
                    <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-bold bg-rose-500/20 text-rose-300 border border-rose-500/40">
                      <AlertTriangle size={13} className="text-rose-400" />
                      NEEDS WORK ({consecutiveSolves}/3 Solves)
                    </span>
                  )}

                  {currentPuzzle.isThreeMovePlan && (
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-xs font-semibold bg-cyan-500/20 text-cyan-300 border border-cyan-500/30">
                      <Flame size={12} /> 3-Move Plan Drill
                    </span>
                  )}
                </div>

                <div className="text-xs text-slate-400 font-mono bg-slate-800/80 px-2 py-0.5 rounded">
                  Move {Math.min(3, Math.floor(puzzleStep / 2) + 1)} of 3
                </div>
              </div>

              {/* Explicit Positional Prompt */}
              <div className="prompt-highlight">
                <div className="text-sm font-semibold text-cyan-200 flex items-start gap-1.5">
                  <HelpCircle size={16} className="text-cyan-400 shrink-0 mt-0.5" />
                  <span>
                    {currentPuzzle.theme === 'Most Common Game Scenario'
                      ? 'Here is a position you are likely to see based on your games: what is the three move answer to this position?'
                      : currentPuzzle.description}
                  </span>
                </div>
              </div>

              {/* Feedback Alert */}
              {puzzleFeedback && (
                <div
                  className={`mt-2 p-2 rounded-lg text-xs font-medium border transition-all ${
                    puzzleError
                      ? 'bg-rose-950/70 text-rose-300 border-rose-800'
                      : puzzleSolved
                      ? 'bg-emerald-950/70 text-emerald-300 border-emerald-800'
                      : 'bg-cyan-950/70 text-cyan-200 border-cyan-800'
                  }`}
                >
                  {puzzleFeedback}
                </div>
              )}
            </div>
          )}

          <div className="board-eval-wrapper">
            <EngineEvalBar
              evaluation={evaluation}
              orientation={boardOrientation}
            />
            <InteractiveBoard
              chess={chess}
              selectedSquare={selectedSquare}
              onSquareClick={handleSquareClick}
              validMoves={validMoves}
              orientation={boardOrientation}
              lastMove={lastMove}
              arrows={boardArrows}
            />
          </div>

          {puzzleSolved && (
            <div className="module-banner" style={{ background: 'rgba(16, 185, 129, 0.15)', borderColor: 'rgba(16, 185, 129, 0.4)', marginTop: '1rem' }}>
              <CheckCircle size={20} className="text-emerald-400" />
              <div>
                <div className="font-semibold text-emerald-400">Position Solved!</div>
                <div className="text-xs text-slate-300">{currentPuzzle.explanation}</div>
              </div>
            </div>
          )}

          {/* Move Navigation Bar (Directly below board when reviewing games) */}
          {activeView === 'insights' && moveHistory.length > 0 && (
            <div className="board-review-nav-bar flex items-center justify-between gap-1.5 mt-2.5 px-1 py-1.5 bg-slate-900/90 rounded-xl border border-slate-700/80 shadow-lg">
              <button
                type="button"
                onClick={() => handleSelectReviewMove(-1)}
                disabled={currentMoveIdx < 0}
                className="board-nav-btn p-2.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 disabled:opacity-30 disabled:pointer-events-none transition-all border border-slate-700 active:scale-95 flex items-center justify-center flex-1 sm:flex-none"
                title="First Move"
              >
                <SkipBack size={20} />
              </button>
              <button
                type="button"
                onClick={() => handleSelectReviewMove(currentMoveIdx - 1)}
                disabled={currentMoveIdx < 0}
                className="board-nav-btn board-nav-primary px-4 py-2.5 rounded-lg bg-slate-800 hover:bg-cyan-900/40 text-cyan-300 disabled:opacity-30 disabled:pointer-events-none transition-all border border-cyan-700/60 active:scale-95 flex items-center justify-center gap-1.5 font-bold text-sm flex-[2] sm:flex-none"
                title="Previous Move"
              >
                <ChevronLeft size={22} />
                <span>Prev Move</span>
              </button>
              <div className="board-nav-counter flex flex-col items-center justify-center px-3 py-1 bg-slate-950/80 rounded-lg border border-slate-800 text-center min-w-[75px]">
                <span className="text-[10px] text-slate-400 font-medium uppercase tracking-wider">Move</span>
                <span className="text-xs font-mono font-bold text-cyan-300">
                  {currentMoveIdx >= 0 ? `${currentMoveIdx + 1} / ${moveHistory.length}` : `Start`}
                </span>
              </div>
              <button
                type="button"
                onClick={() => handleSelectReviewMove(currentMoveIdx + 1)}
                disabled={currentMoveIdx >= moveHistory.length - 1}
                className="board-nav-btn board-nav-primary px-4 py-2.5 rounded-lg bg-slate-800 hover:bg-cyan-900/40 text-cyan-300 disabled:opacity-30 disabled:pointer-events-none transition-all border border-cyan-700/60 active:scale-95 flex items-center justify-center gap-1.5 font-bold text-sm flex-[2] sm:flex-none"
                title="Next Move"
              >
                <span>Next Move</span>
                <ChevronRight size={22} />
              </button>
              <button
                type="button"
                onClick={() => handleSelectReviewMove(moveHistory.length - 1)}
                disabled={currentMoveIdx >= moveHistory.length - 1}
                className="board-nav-btn p-2.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 disabled:opacity-30 disabled:pointer-events-none transition-all border border-slate-700 active:scale-95 flex items-center justify-center flex-1 sm:flex-none"
                title="Last Move"
              >
                <SkipForward size={20} />
              </button>
            </div>
          )}

          {/* Inline Move Notation Tape beneath navigation bar with Lichess / Chess.com glyphs */}
          {activeView === 'insights' && moveHistory.length > 0 && (
            <div className="board-inline-movelist-strip mt-2 px-2 py-1.5 bg-slate-950/80 rounded-xl border border-slate-800 flex items-center gap-1 overflow-x-auto shadow-inner">
              <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider shrink-0 mr-1">
                Moves:
              </span>
              <button
                type="button"
                onClick={() => handleSelectReviewMove(-1)}
                className={`inline-move-chip text-[11px] font-mono px-2 py-0.5 rounded transition-all shrink-0 ${
                  currentMoveIdx === -1
                    ? 'bg-cyan-500/25 text-cyan-300 font-bold border border-cyan-500/60'
                    : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/80'
                }`}
                title="Starting Position (Move 1)"
              >
                Start
              </button>
              {moveHistory.map((m, idx) => {
                const moveNum = Math.floor(idx / 2) + 1;
                const isWhiteMove = idx % 2 === 0;
                const isSelected = idx === currentMoveIdx;
                const annot = MOVE_NOTATION_MAP[m.rating] || MOVE_NOTATION_MAP.good;
                const evalText = formatEvalPoints(m.evalAfter ?? 0);

                return (
                  <div key={idx} className="flex items-center shrink-0">
                    {isWhiteMove && (
                      <span className="text-[10px] text-slate-500 font-mono mr-1">
                        {moveNum}.
                      </span>
                    )}
                    <button
                      type="button"
                      onClick={() => handleSelectReviewMove(idx)}
                      className={`inline-move-chip group relative inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded text-[11px] font-mono font-semibold transition-all ${
                        isSelected
                          ? 'bg-cyan-500 text-slate-950 font-bold shadow-sm'
                          : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                      }`}
                      style={
                        !isSelected && annot.glyph
                          ? { borderBottom: `2px solid ${annot.color}` }
                          : undefined
                      }
                      title={`${moveNum}${isWhiteMove ? '.' : '...'} ${m.san}${annot.glyph ? ` (${annot.glyph} ${annot.name})` : ''} • Eval: ${evalText}`}
                    >
                      <span>{m.san}</span>
                      {annot.glyph && (
                        <span
                          className={`glyph-badge font-bold px-0.5 rounded ${
                            isSelected ? 'text-slate-950' : ''
                          }`}
                          style={{
                            color: isSelected ? '#020617' : annot.color,
                            fontSize: '10px'
                          }}
                        >
                          {annot.glyph}
                        </span>
                      )}
                      {/* Rich Hover Notation Tooltip (Lichess/Chess.com style) */}
                      <span className="pointer-events-none absolute bottom-full left-1/2 -translate-x-1/2 mb-1.5 hidden group-hover:flex flex-col items-center z-50 whitespace-nowrap">
                        <span className="px-2 py-1 bg-slate-900 text-slate-100 text-[10px] font-sans font-medium rounded-md shadow-xl border border-slate-700 flex items-center gap-1.5">
                          {annot.glyph && (
                            <strong style={{ color: annot.color }}>{annot.glyph}</strong>
                          )}
                          <span>{annot.name}</span>
                          <span className="text-slate-400 font-mono">({evalText})</span>
                        </span>
                        <span className="w-1.5 h-1.5 bg-slate-900 border-r border-b border-slate-700 transform rotate-45 -mt-1" />
                      </span>
                    </button>
                    {!isWhiteMove && idx < moveHistory.length - 1 && (
                      <span className="text-slate-700 mx-0.5 font-sans">,</span>
                    )}
                  </div>
                );
              })}
            </div>
          )}

          {/* Board Actions */}
          <div className="board-actions flex flex-wrap items-center gap-2 mt-3">
            {activeView === 'training' && (
              <button
                className={`action-btn font-semibold flex items-center gap-1.5 transition-all ${
                  isBestMoveActive
                    ? 'bg-amber-500/20 text-amber-300 border-amber-500/50'
                    : 'text-amber-400 hover:bg-amber-950/40 hover:border-amber-600'
                }`}
                onClick={handleToggleBestMove}
                title="Show candidate / best move arrow for this 3-move drill"
              >
                <Lightbulb size={16} />
                <span>{isBestMoveActive ? 'Hide Best Move' : 'Best Move'}</span>
              </button>
            )}

            <button
              className="action-btn text-cyan-300 hover:bg-cyan-950/40 hover:border-cyan-600 flex items-center gap-1.5 font-semibold"
              onClick={handleSavePosition}
              title="Save this position & optimal 3-move answer to your Positional Archive"
            >
              <Bookmark size={15} />
              <span>Save to Archive</span>
            </button>

            <button className="action-btn" onClick={handleReset}>
              <RotateCcw size={16} />
              <span>Reset Board</span>
            </button>
            <button
              className="action-btn"
              onClick={() => setBoardOrientation(boardOrientation === 'w' ? 'b' : 'w')}
            >
              <span>Flip Board</span>
            </button>
          </div>
        </section>

        {/* Right Side: Insights, Playstyle & Training Panels */}
        <section className="side-card">
          <div className="view-tabs">
            <button
              className={`view-tab-btn ${activeView === 'playstyle' ? 'view-tab-active' : ''}`}
              onClick={() => setActiveView('playstyle')}
            >
              <Compass size={16} />
              <span>Opening Diagnostics</span>
            </button>
            <button
              className={`view-tab-btn ${activeView === 'games' ? 'view-tab-active' : ''}`}
              onClick={() => setActiveView('games')}
            >
              <Swords size={16} />
              <span>Recent Games</span>
            </button>
            <button
              className={`view-tab-btn ${activeView === 'challenging' ? 'view-tab-active' : ''}`}
              onClick={() => setActiveView('challenging')}
            >
              <ShieldAlert size={16} className="text-rose-400" />
              <span>Challenging Variations</span>
            </button>
            <button
              className={`view-tab-btn ${activeView === 'tree' ? 'view-tab-active' : ''}`}
              onClick={() => {
                setActiveView('tree');
                chess.reset();
                setTreeLineSan([]);
                setBoardOrientation(treeColor === 'white' ? 'w' : 'b');
                refreshBoard();
              }}
            >
              <GitBranch size={16} />
              <span>Opening Tree</span>
            </button>
            <button
              className={`view-tab-btn ${activeView === 'insights' ? 'view-tab-active' : ''}`}
              onClick={() => setActiveView('insights')}
            >
              <BarChart3 size={16} />
              <span>Game Review</span>
            </button>
            <button
              className={`view-tab-btn ${activeView === 'training' ? 'view-tab-active' : ''}`}
              onClick={() => setActiveView('training')}
            >
              <GraduationCap size={16} />
              <span>Drills</span>
            </button>
          </div>

          {activeView === 'playstyle' ? (
            <PlaystyleAnalysisPanel
              profile={playstyleProfile}
              onSelectOpening={(openingName) => {
                const found = OPENING_REPERTOIRE.find(
                  (o) =>
                    o.name.toLowerCase().includes(openingName.toLowerCase()) ||
                    openingName.toLowerCase().includes(o.name.toLowerCase())
                );
                if (found) {
                  handleSelectOpening(found);
                  setActiveView('training');
                  setTrainingTab('openings');
                }
              }}
              onInspectOpeningBranch={(opening) => {
                chess.reset();
                const branch = opening.moveBranchSan || [];
                const executedMoves: string[] = [];
                let lastPly: { from: string; to: string } | null = null;

                for (const moveSan of branch) {
                  try {
                    const m = chess.move(moveSan);
                    if (m) {
                      executedMoves.push(m.san);
                      lastPly = { from: m.from, to: m.to };
                    }
                  } catch (e) {
                    break;
                  }
                }

                const targetColor = opening.playedAs === 'Black' ? 'black' : 'white';
                setTreeColor(targetColor);
                setBoardOrientation(targetColor === 'black' ? 'b' : 'w');
                setTreeLineSan(executedMoves);
                setLastMove(lastPly);
                refreshBoard();
                setActiveView('tree');

                if (opening.problemMove) {
                  setSyncStatus(`Inspecting ${opening.name} leak: Replayed ${executedMoves.length} moves. Problem occurred at Move ${Math.floor(opening.problemMove.ply / 2) + 1} (${opening.problemMove.san}).`);
                } else {
                  setSyncStatus(`Loaded move order for ${opening.name} (${executedMoves.join(' ')}). Inspecting in Opening Tree.`);
                }
                setTimeout(() => setSyncStatus(null), 7000);
              }}
              onOpenConnectModal={() => setIsAuthOpen(true)}
              chessComUsername={chessComUsername}
              recentGames={recentGames}
              onAnalyzeGame={handleAnalyzeGame}
              activeGameUrl={loadedAnalyzedGame?.url}
            />
          ) : activeView === 'games' ? (
            <RecentGamesList
              games={recentGames}
              username={chessComUsername}
              onAnalyzeGame={handleAnalyzeGame}
              activeGameUrl={loadedAnalyzedGame?.url}
              onOpenConnectModal={() => setIsAuthOpen(true)}
              isSyncing={isSyncing}
            />
          ) : activeView === 'challenging' ? (
            <ChallengingVariationsPanel
              problematicOpenings={playstyleProfile?.problematicOpenings || []}
              username={chessComUsername}
              onPracticePatternDrill={handlePracticeChallengingPattern}
              onInspectVariationBranch={(opening) => {
                chess.reset();
                const branch = opening.moveBranchSan || [];
                const executedMoves: string[] = [];
                let lastPly: { from: string; to: string } | null = null;

                for (const moveSan of branch) {
                  try {
                    const m = chess.move(moveSan);
                    if (m) {
                      executedMoves.push(m.san);
                      lastPly = { from: m.from, to: m.to };
                    }
                  } catch (e) {
                    break;
                  }
                }

                const targetColor = opening.playedAs === 'Black' ? 'black' : 'white';
                setTreeColor(targetColor);
                setBoardOrientation(targetColor === 'black' ? 'b' : 'w');
                setTreeLineSan(executedMoves);
                setLastMove(lastPly);
                refreshBoard();
                setActiveView('tree');

                if (opening.problemMove) {
                  setSyncStatus(`Inspecting ${opening.name} challenging variation: Problem at Move ${Math.floor(opening.problemMove.ply / 2) + 1} (${opening.problemMove.san}).`);
                } else {
                  setSyncStatus(`Loaded move order for ${opening.name} in Opening Tree.`);
                }
                setTimeout(() => setSyncStatus(null), 7000);
              }}
              onOpenConnectModal={() => setIsAuthOpen(true)}
            />
          ) : activeView === 'tree' ? (
            <OpeningTreePanel
              tree={treeColor === 'white' ? openingTreeWhite : openingTreeBlack}
              totalGamesLoaded={totalGamesAnalyzed}
              currentFen={fen}
              candidateMoves={candidateMoves}
              currentLineSan={treeLineSan}
              activeColor={treeColor}
              onColorChange={(color) => {
                setTreeColor(color);
                setBoardOrientation(color === 'white' ? 'w' : 'b');
                chess.reset();
                setTreeLineSan([]);
                setLastMove(null);
                refreshBoard();
              }}
              onSelectMove={(move) => {
                try {
                  const m = chess.move(move.san);
                  if (m) {
                    setLastMove({ from: m.from, to: m.to });
                    setTreeLineSan([...treeLineSan, m.san]);
                    refreshBoard();
                  }
                } catch (e) {
                  // Ignore move error
                }
              }}
              onStepBack={() => {
                if (treeLineSan.length > 0) {
                  chess.undo();
                  const nextLine = treeLineSan.slice(0, -1);
                  setTreeLineSan(nextLine);
                  const hist = chess.history({ verbose: true });
                  if (hist.length > 0) {
                    const last = hist[hist.length - 1];
                    setLastMove({ from: last.from, to: last.to });
                  } else {
                    setLastMove(null);
                  }
                  refreshBoard();
                }
              }}
              onResetTree={() => {
                chess.reset();
                setTreeLineSan([]);
                setLastMove(null);
                refreshBoard();
              }}
              onGenerateDrillForPosition={() => {
                const best = findBestLine(chess, 3);
                if (best && best.line.length > 0) {
                  const lineStr = treeLineSan.length > 0 ? treeLineSan.join(' ') : 'Starting Tabiyah';
                  const newDrill: TacticalPuzzle = {
                    id: `tree-drill-${Date.now()}`,
                    title: `Opening Tree Drill: ${lineStr}`,
                    theme: 'Repertoire Weakness Drill',
                    rating: 1450,
                    description: 'Here is a critical position from your personal opening tree. What is the three move answer to this position?',
                    fen: chess.fen(),
                    solutionUci: best.line,
                    solutionSan: best.lineSan,
                    playerColor: chess.turn(),
                    explanation: `From your personal opening tree, the optimal 3-move continuation is ${best.lineSan.join(' ')}.`,
                    isThreeMovePlan: true
                  };
                  setPuzzlesList([newDrill, ...puzzlesList]);
                  handleSelectPuzzle(newDrill);
                  setActiveView('training');
                  setSyncStatus(`Created 3-move drill for line: ${lineStr}`);
                  setTimeout(() => setSyncStatus(null), 4000);
                }
              }}
              chessComUsername={chessComUsername}
              onOpenConnectModal={() => setIsAuthOpen(true)}
              currentFilters={gamesFilter}
              onApplyFilters={(filters) => {
                setGamesFilter(filters);
                if (chessComUsername) {
                  loadChessComGames(chessComUsername, currentUser?.uid, filters);
                }
              }}
              isSyncing={isSyncing}
              showArrows={showArrows}
              onToggleArrows={() => setShowArrows(!showArrows)}
            />
          ) : activeView === 'insights' ? (
            <GameInsightsPanel
              whiteAccuracy={whiteAcc}
              blackAccuracy={blackAcc}
              moves={moveHistory}
              currentMoveIndex={currentMoveIdx}
              onSelectMove={handleSelectReviewMove}
              evaluation={evaluation}
              loadedGame={loadedAnalyzedGame}
              onPrevMove={() => handleSelectReviewMove(currentMoveIdx - 1)}
              onNextMove={() => handleSelectReviewMove(currentMoveIdx + 1)}
              onFirstMove={() => handleSelectReviewMove(-1)}
              onLastMove={() => handleSelectReviewMove(moveHistory.length - 1)}
            />
          ) : (
            <TrainingModulesPanel
              puzzles={puzzlesList}
              currentPuzzleId={currentPuzzle.id}
              onSelectPuzzle={handleSelectPuzzle}
              openings={OPENING_REPERTOIRE}
              onSelectOpening={handleSelectOpening}
              activeTab={trainingTab}
              onTabChange={setTrainingTab}
              progressMap={progressMap}
              savedPositions={savedPositions}
              onSelectSavedPosition={handleTestSavedPosition}
              onDeleteSavedPosition={handleDeletePosition}
            />
          )}
        </section>
      </main>

      {/* Auth & Chess.com Modal */}
      <AuthModal
        isOpen={isAuthOpen}
        onClose={() => setIsAuthOpen(false)}
        currentUser={currentUser}
        chessComUsername={chessComUsername}
        onUpdateChessComUsername={(handle) => {
          setChessComUsername(handle);
          try {
            localStorage.setItem('chessfr_chesscom_username', handle);
          } catch (e) {}
          loadChessComGames(handle, currentUser?.uid);
        }}
      />
    </div>
  );
}

export default App;
