import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'warehouse_game.dart';

class LichessService {
  final String _baseUrl = 'https://lichess.org/api';

  /// Fetches the most recent [limit] rated/unrated games for [username].
  /// Uses the NDJSON streaming endpoint.
  Future<List<WarehouseGame>> getRecentGames(
    String username, {
    int limit = 50,
    bool ratedOnly = false,
  }) async {
    final params = {
      'max':        '$limit',
      'pgnInJson':  'true',
      'clocks':     'false', // keep payload light
      'evals':      'false',
      if (ratedOnly) 'rated': 'true',
    };
    final url = Uri.parse('$_baseUrl/games/user/$username').replace(queryParameters: params);

    try {
      final response = await http.get(
        url,
        headers: {'Accept': 'application/x-ndjson'},
      );

      if (response.statusCode == 200) {
        final games = <WarehouseGame>[];
        final lines = const LineSplitter().convert(response.body);

        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          final game = _fromNdjson(line);
          if (game != null) games.add(game);
        }
        return games;
      } else {
        debugPrint('LichessService.getRecentGames HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('LichessService.getRecentGames error: $e');
    }
    return [];
  }

  // -------------------------------------------------------
  // Internal parser — Lichess NDJSON line → WarehouseGame
  // -------------------------------------------------------
  WarehouseGame? _fromNdjson(String line) {
    try {
      final j = jsonDecode(line) as Map<String, dynamic>;

      final id      = j['id'] as String? ?? '';
      final pgn     = j['pgn'] as String? ?? '';
      final speed   = j['speed'] as String? ?? 'blitz';
      final rated   = j['rated'] as bool? ?? false;

      // Timestamps: Lichess provides milliseconds
      final createdAtMs = (j['createdAt'] as num? ?? 0).toInt();

      final players     = j['players'] as Map<String, dynamic>? ?? {};
      final white       = players['white'] as Map<String, dynamic>? ?? {};
      final black       = players['black'] as Map<String, dynamic>? ?? {};
      final whiteUser   = white['user'] as Map<String, dynamic>? ?? {};
      final blackUser   = black['user'] as Map<String, dynamic>? ?? {};

      final whiteUsername = whiteUser['name'] as String? ?? 'Unknown';
      final blackUsername = blackUser['name'] as String? ?? 'Unknown';
      final whiteRating   = (white['rating'] as num? ?? 0).toInt();
      final blackRating   = (black['rating'] as num? ?? 0).toInt();

      final winner = j['winner'] as String?;
      final result = winner == 'white'
          ? '1-0'
          : (winner == 'black' ? '0-1' : '1/2-1/2');

      return WarehouseGame(
        platformId:    'https://lichess.org/$id',
        platform:      GamePlatform.lichess,
        pgn:           pgn,
        whiteUsername: whiteUsername,
        blackUsername: blackUsername,
        whiteRating:   whiteRating,
        blackRating:   blackRating,
        timeControl:   speed,
        rated:         rated,
        result:        result,
        playedAt:      DateTime.fromMillisecondsSinceEpoch(createdAtMs),
      );
    } catch (e) {
      debugPrint('LichessService._fromNdjson error: $e');
      return null;
    }
  }
}
