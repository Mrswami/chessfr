// Feature exports
export '../features/training/training_screen.dart';
export '../features/analysis/screenshot_analysis_screen.dart';

import '../features/logic/gemini_chess_service.dart';

class AppConstants {
  static const String appName = 'Chess FR';
  static const String supabaseUrl = 'https://jcrkoclchttokwzeddlr.supabase.co';

  /// Singleton instance of the Gemini chess analysis service.
  /// Reads GEMINI_API_KEY from the environment (loaded via flutter_dotenv).
  static GeminiChessService? _geminiService;
  static GeminiChessService getGeminiService(String apiKey) {
    _geminiService ??= GeminiChessService(apiKey: apiKey);
    return _geminiService!;
  }
}
