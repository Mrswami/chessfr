import 'move_ranker.dart';

class StockfishService {
  Future<List<EngineMove>> getTopMoves(String fen) async {
    // Mocking Stockfish response for now
    // In production, this would call the binary/WASM or API
    await Future.delayed(const Duration(milliseconds: 500));
    
    return [
      EngineMove(san: 'e4', evaluation: 35),
      EngineMove(san: 'Nf3', evaluation: 20),
      EngineMove(san: 'd4', evaluation: 15),
    ];
  }
}
