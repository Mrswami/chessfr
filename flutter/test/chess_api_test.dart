import 'package:chess/chess.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Inspect State', () {
    final chess = Chess();
    chess.load('rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1');
    // chess.move('e4'); // Already moved in FEN? No wait.
    // 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq' is AFTER e4.
    
    // Let's just make moves from start
    final game = Chess();
    game.move('e4');
    
    final hist = game.history;
    if (hist.isNotEmpty) {
      final state = hist.last;
      print('State keys/props: ${state.toString()}');
      // Try to access move
      print('Move in state: ${state.move}');
      print('Move type: ${state.move.runtimeType}');
      // Inspect Move object
      final m = state.move;
      print('Move from: ${m.from}');
      print('Move to: ${m.to}');
      print('Move san: ${m.san}');
    }
  });
}
