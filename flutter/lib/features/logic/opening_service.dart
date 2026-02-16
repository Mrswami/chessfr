import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpeningStats {
  final String name;
  final String eco;
  final int totalGames;

  OpeningStats({
    required this.name,
    required this.eco,
    required this.totalGames,
  });
}

class OpeningService {
  static const String _mastersUrl = 'https://explorer.lichess.ovh/masters';

  // Cache to prevent excessive requests for repeat positions
  final Map<String, OpeningStats> _cache = {};

  Future<OpeningStats?> getOpeningStats(String fen) async {
    // Check cache
    if (_cache.containsKey(fen)) return _cache[fen];

    try {
      // Use Masters by default for "Professional/Worldwide Theory"
      // Replace spaces with + or %20 for URL safety
      final fenParam = fen.replaceAll(' ', '+');
      final uri = Uri.parse('$_mastersUrl?fen=$fenParam');
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Sum top-level outcomes to get total games in database for this position
        final int white = data['white'] ?? 0;
        final int draws = data['draws'] ?? 0;
        final int black = data['black'] ?? 0;
        final int total = white + draws + black;

        String name = 'Unknown Position';
        String eco = '';

        if (data.containsKey('opening') && data['opening'] != null) {
          name = data['opening']['name'] ?? 'Unknown Position';
          eco = data['opening']['eco'] ?? '';
        } else if (total > 0) {
          name = 'Uncatalogued Position';
        }

        final stats = OpeningStats(
          name: name,
          eco: eco,
          totalGames: total,
        );
        
        _cache[fen] = stats;
        return stats;
      }
    } catch (e) {
      // Fail silently for UI purposes
      debugPrint('Error fetching opening stats: $e');
    }
    return null;
  }
}
