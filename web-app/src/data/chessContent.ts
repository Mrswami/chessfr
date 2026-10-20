export interface TacticalPuzzle {
  id: string;
  title: string;
  theme: string;
  rating: number;
  description: string;
  fen: string;
  solutionUci: string[]; // sequence e.g. ['d1d8', 'f8d8', 'e1e8']
  solutionSan?: string[];
  playerColor: 'w' | 'b';
  explanation: string;
  isThreeMovePlan?: boolean;
  playedBlunder?: string;
  opponent?: string;
  gameDate?: string;
  gameOutcome?: 'win' | 'loss' | 'draw';
  frequencyScore?: number;
  gameUrl?: string;
}

export const SAMPLE_PUZZLES: TacticalPuzzle[] = [
  {
    id: 'back-rank-1',
    title: 'Operatic Back-Rank Clearance',
    theme: 'Back-Rank Mate',
    rating: 1250,
    description: 'White has major piece control along the open files. Exploit the trapped black king.',
    fen: '3r2k1/5ppp/8/8/8/8/4QPPP/6K1 w - - 0 1',
    solutionUci: ['e2e8', 'd8e8'],
    playerColor: 'w',
    explanation: 'The black king is suffocated by its own pawn shield. White sacrifices queen to force checkmate.'
  },
  {
    id: 'smothered-mate-1',
    title: 'Philidor’s Legacy (Smothered Mate)',
    theme: 'Knight Smother',
    rating: 1650,
    description: 'Black’s King is boxed in. Execute the classic royal knight checkmate.',
    fen: '6k1/5ppp/8/8/5N2/8/8/6QK w - - 0 1',
    solutionUci: ['f4h5', 'g8h8'],
    playerColor: 'w',
    explanation: 'Knight maneuver restricts escape squares.'
  },
  {
    id: 'greek-gift-1',
    title: 'The Greek Gift Sacrifice (Bxh7+)',
    theme: 'King Attack',
    rating: 1500,
    description: 'Rip open the black kingside with a classic bishop sacrifice.',
    fen: 'r1bq1rk1/ppp2ppp/2np4/2b1p1N1/2B1P1n1/2NP4/PPP2PPP/R1BQK2R w KQ - 0 8',
    solutionUci: ['c4f7', 'f8f7'],
    playerColor: 'w',
    explanation: 'Shattering the defensive barrier allows rapid piece coordination.'
  },
  {
    id: 'endgame-perpetual-1',
    title: 'Rook vs Pawn Bridge Building',
    theme: 'Endgame Lucena',
    rating: 1750,
    description: 'Protect the promoting pawn and build the winning shelter.',
    fen: '1K6/1P1k4/8/8/8/8/2r5/7R w - - 0 1',
    solutionUci: ['h1d1', 'd7e7'],
    playerColor: 'w',
    explanation: 'Lucena technique guarantees promotion by blocking enemy rook checks.'
  }
];

export interface OpeningLine {
  id: string;
  name: string;
  eco: string;
  moves: string[]; // ['e4', 'c5', 'Nf3', 'd6']
  description: string;
  idealIdeas: string[];
}

export const OPENING_REPERTOIRE: OpeningLine[] = [
  {
    id: 'sicilian-najdorf',
    name: 'Sicilian Defense: Najdorf Variation',
    eco: 'B90',
    moves: ['e4', 'c5', 'Nf3', 'd6', 'd4', 'cxd4', 'Nxd4', 'Nf6', 'Nc3', 'a6'],
    description: 'The sharpest and most deeply analyzed weapon in chess, famously championed by Fischer and Kasparov.',
    idealIdeas: ['Control central dark squares', 'Queenside counterplay with ...b5', 'Maintain dynamic tension']
  },
  {
    id: 'queens-gambit',
    name: 'Queen’s Gambit Declined',
    eco: 'D30',
    moves: ['d4', 'd5', 'c4', 'e6', 'Nc3', 'Nf6', 'Bg5', 'Be7'],
    description: 'The pinnacle of classical chess strategy. High solidity and long-term positional maneuvering.',
    idealIdeas: ['Solid d5 fortress', 'Eventual ...c5 break', 'Careful bishop development']
  },
  {
    id: 'kings-indian',
    name: 'King’s Indian Defense',
    eco: 'E60',
    moves: ['d4', 'Nf6', 'c4', 'g6', 'Nc3', 'Bg7', 'e4', 'd6'],
    description: 'A dynamic counter-attacking hypermodern system yielding explosive kingside attacks.',
    idealIdeas: ['Fianchetto dark-squared bishop', 'Pawn storm via ...f5 break', 'Sacrificial tactical attacks']
  }
];
