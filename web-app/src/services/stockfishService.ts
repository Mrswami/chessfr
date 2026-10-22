/**
 * Stockfish Web Worker Service for ChessFr
 * Communicates with the Stockfish 19 WebAssembly engine via UCI protocol
 */

export interface StockfishEvaluation {
  depth: number;
  scoreCp: number; // Centipawns from White's perspective
  isMate: boolean;
  mateIn?: number;
  bestMoveSan?: string;
  bestMoveUci: string;
  pv: string[];
}

export interface StockfishEngineLine {
  rank: number;
  moveSan: string;
  moveUci: string;
  eval: number; // Centipawns from White's perspective
  pvSan: string[];
}

class StockfishEngineService {
  private worker: Worker | null = null;
  private isReady: boolean = false;
  private readyCallbacks: (() => void)[] = [];
  private currentResolver: ((evalData: StockfishEvaluation) => void) | null = null;
  private currentEval: StockfishEvaluation | null = null;
  private isSearching: boolean = false;

  constructor() {
    this.initWorker();
  }

  private initWorker() {
    if (typeof window === 'undefined') return;

    try {
      this.worker = new Worker('/stockfish/stockfish.js');
      
      this.worker.onmessage = (event) => {
        const line = typeof event.data === 'string' ? event.data : '';
        this.handleMessage(line);
      };

      this.worker.onerror = (err) => {
        console.warn('Stockfish worker error, falling back:', err);
      };

      // Initialize UCI
      this.worker.postMessage('uci');
      this.worker.postMessage('isready');
    } catch (err) {
      console.warn('Failed to spawn Stockfish Web Worker:', err);
    }
  }

  private handleMessage(line: string) {
    if (line === 'readyok') {
      this.isReady = true;
      while (this.readyCallbacks.length > 0) {
        const cb = this.readyCallbacks.shift();
        if (cb) cb();
      }
      return;
    }

    // Parse info depth ... multipv ... score ... pv ...
    if (line.startsWith('info') && line.includes('score')) {
      const depthMatch = line.match(/depth\s+(\d+)/);
      const cpMatch = line.match(/score\s+cp\s+(-?\d+)/);
      const mateMatch = line.match(/score\s+mate\s+(-?\d+)/);
      const pvMatch = line.match(/pv\s+(.+)$/);
      const multipvMatch = line.match(/multipv\s+(\d+)/);

      const depth = depthMatch ? parseInt(depthMatch[1], 10) : 0;
      const multipv = multipvMatch ? parseInt(multipvMatch[1], 10) : 1;

      let scoreCp = 0;
      let isMate = false;
      let mateIn: number | undefined;

      if (mateMatch) {
        isMate = true;
        mateIn = parseInt(mateMatch[1], 10);
        scoreCp = mateIn > 0 ? 30000 : -30000;
      } else if (cpMatch) {
        scoreCp = parseInt(cpMatch[1], 10);
      }

      const pv = pvMatch ? pvMatch[1].trim().split(/\s+/) : [];
      const bestMoveUci = pv.length > 0 ? pv[0] : '';

      // Only update top eval on multipv 1
      if (multipv === 1) {
        this.currentEval = {
          depth,
          scoreCp,
          isMate,
          mateIn,
          bestMoveUci,
          pv
        };
      }
    }

    // Parse bestmove <uci>
    if (line.startsWith('bestmove')) {
      const parts = line.split(' ');
      const bestMoveUci = parts[1] || '';
      this.isSearching = false;

      if (this.currentResolver) {
        const result: StockfishEvaluation = this.currentEval || {
          depth: 10,
          scoreCp: 0,
          isMate: false,
          bestMoveUci,
          pv: [bestMoveUci]
        };
        result.bestMoveUci = bestMoveUci;

        const resolver = this.currentResolver;
        this.currentResolver = null;
        resolver(result);
      }
    }
  }

  private currentLines: Map<number, StockfishEngineLine> = new Map();
  private multiLineResolver: ((lines: StockfishEngineLine[]) => void) | null = null;

  // Handle multiPV lines
  private handleMultiPvLine(line: string, isBlackToMove: boolean) {
    if (!line.startsWith('info') || !line.includes('score')) return;

    const depthMatch = line.match(/depth\s+(\d+)/);
    const cpMatch = line.match(/score\s+cp\s+(-?\d+)/);
    const mateMatch = line.match(/score\s+mate\s+(-?\d+)/);
    const pvMatch = line.match(/pv\s+(.+)$/);
    const multipvMatch = line.match(/multipv\s+(\d+)/);

    const rank = multipvMatch ? parseInt(multipvMatch[1], 10) : 1;
    let scoreCp = 0;

    if (mateMatch) {
      const mateIn = parseInt(mateMatch[1], 10);
      scoreCp = mateIn > 0 ? 30000 : -30000;
    } else if (cpMatch) {
      scoreCp = parseInt(cpMatch[1], 10);
    }

    if (isBlackToMove) {
      scoreCp = -scoreCp;
    }

    const pv = pvMatch ? pvMatch[1].trim().split(/\s+/) : [];
    const moveUci = pv.length > 0 ? pv[0] : '';

    if (moveUci) {
      this.currentLines.set(rank, {
        rank,
        moveSan: moveUci,
        moveUci,
        eval: scoreCp,
        pvSan: pv
      });
    }
  }

  public ensureReady(): Promise<void> {
    if (this.isReady) return Promise.resolve();
    return new Promise((resolve) => {
      this.readyCallbacks.push(resolve);
      if (this.worker) {
        this.worker.postMessage('isready');
      }
    });
  }

  /**
   * Evaluates a FEN position with Stockfish to a specific depth (e.g. 10 or 12)
   * Returns centipawns normalized from White's perspective
   */
  public async evaluateFen(fen: string, depth: number = 10, moveTimeMs?: number): Promise<StockfishEvaluation> {
    await this.ensureReady();

    if (!this.worker) {
      throw new Error('Stockfish worker not available');
    }

    if (this.isSearching) {
      this.worker.postMessage('stop');
    }

    this.currentEval = null;
    this.isSearching = true;

    // UCI evaluates from the perspective of the side whose turn it is in the FEN.
    // We normalize to White's perspective (positive = White ahead, negative = Black ahead).
    const isBlackToMove = fen.includes(' b ');

    return new Promise((resolve) => {
      this.currentResolver = (evalData) => {
        if (isBlackToMove) {
          evalData.scoreCp = -evalData.scoreCp;
        }
        resolve(evalData);
      };

      this.worker!.postMessage(`position fen ${fen}`);
      if (moveTimeMs && moveTimeMs > 0) {
        this.worker!.postMessage(`go movetime ${moveTimeMs}`);
      } else {
        this.worker!.postMessage(`go depth ${depth}`);
      }
    });
  }

  /**
   * Computes top N engine lines using Stockfish MultiPV
   */
  public async getTopLines(fen: string, topN: number = 3, depth: number = 10): Promise<StockfishEngineLine[]> {
    await this.ensureReady();
    if (!this.worker) return [];

    if (this.isSearching) {
      this.worker.postMessage('stop');
    }

    this.currentLines.clear();
    this.isSearching = true;
    const isBlackToMove = fen.includes(' b ');

    this.worker.postMessage(`setoption name MultiPV value ${topN}`);
    this.worker.postMessage(`position fen ${fen}`);

    return new Promise((resolve) => {
      const lineListener = (event: MessageEvent) => {
        const msg = typeof event.data === 'string' ? event.data : '';
        this.handleMultiPvLine(msg, isBlackToMove);

        if (msg.startsWith('bestmove')) {
          this.worker?.removeEventListener('message', lineListener);
          this.isSearching = false;
          // Return sorted lines by rank
          const results = Array.from(this.currentLines.values()).sort((a, b) => a.rank - b.rank);
          resolve(results);
        }
      };

      this.worker!.addEventListener('message', lineListener);
      this.worker!.postMessage(`go depth ${depth}`);
    });
  }

  /**
   * Stop any running search immediately
   */
  public stop() {
    if (this.worker && this.isSearching) {
      this.worker.postMessage('stop');
      this.isSearching = false;
    }
  }
}

export const stockfishService = new StockfishEngineService();
