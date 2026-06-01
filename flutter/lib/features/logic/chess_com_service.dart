import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'warehouse_game.dart';

class ChessComService {
  final String _baseUrl = 'https://api.chess.com/pub';

  /// Fetches monthly archive URLs for a user (newest first).
  Future<List<String>> getArchives(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/player/$username/games/archives'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> archives = data['archives'];
        return archives.map((e) => e.toString()).toList().reversed.toList();
      }
    } catch (e) {
      debugPrint('ChessComService.getArchives error: $e');
    }
    return [];
  }

  /// Fetches games from a specific monthly archive URL.
  Future<List<WarehouseGame>> getGamesFromArchive(String archiveUrl) async {
    try {
      final response = await http.get(Uri.parse(archiveUrl));
      if (response.statusCode == 200) {
        final data     = json.decode(response.body);
        final List<dynamic> games = data['games'];
        return games
            .map((j) => _fromJson(j as Map<String, dynamic>))
            .whereType<WarehouseGame>()
            .toList();
      }
    } catch (e) {
      debugPrint('ChessComService.getGamesFromArchive error: $e');
    }
    return [];
  }

  /// Fetches the most recent [limit] games for [username].
  Future<List<WarehouseGame>> getRecentGames(
    String username, {
    int limit = 50,
  }) async {
    final archives = await getArchives(username);
    final all = <WarehouseGame>[];

    for (final url in archives) {
      if (all.length >= limit) break;
      final batch = await getGamesFromArchive(url);
      batch.sort((a, b) => b.playedAt.compareTo(a.playedAt));
      all.addAll(batch);
    }

    return all.take(limit).toList();
  }

  // -------------------------------------------------------
  // Internal parser — Chess.com JSON → WarehouseGame
  // -------------------------------------------------------
  WarehouseGame? _fromJson(Map<String, dynamic> j) {
    try {
      final whiteResult = j['white']?['result'] as String? ?? '';
      final blackResult = j['black']?['result'] as String? ?? '';
      String result = '1/2-1/2';
      if (whiteResult == 'win') result = '1-0';
      if (blackResult == 'win') result = '0-1';

      final endTimeSec = (j['end_time'] as num? ?? 0).toInt();

      return WarehouseGame(
        platformId:    j['url'] ?? '',
        platform:      GamePlatform.chessCom,
        pgn:           j['pgn'] ?? '',
        whiteUsername: j['white']?['username'] ?? 'Unknown',
        blackUsername: j['black']?['username'] ?? 'Unknown',
        whiteRating:   (j['white']?['rating'] as num? ?? 0).toInt(),
        blackRating:   (j['black']?['rating'] as num? ?? 0).toInt(),
        timeControl:   j['time_control']?.toString() ?? '',
        rated:         j['rated'] as bool? ?? false,
        result:        result,
        playedAt:      DateTime.fromMillisecondsSinceEpoch(endTimeSec * 1000),
      );
    } catch (e) {
      debugPrint('ChessComService._fromJson error: $e');
      return null;
    }
  }
}
