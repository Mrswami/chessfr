import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ChessComService {
  final String _baseUrl = 'https://api.chess.com/pub';

  /// Fetches monthly archives for a user.
  Future<List<String>> getArchives(String username) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/player/$username/games/archives'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> archives = data['archives'];
        // Return most recent first
        return archives.map((e) => e.toString()).toList().reversed.toList();
      }
    } catch (e) {
      debugPrint('Error fetching archives: $e');
    }
    return [];
  }

  /// Fetches games from a specific monthly archive URL.
  Future<List<ChessComGame>> getGamesFromArchive(String archiveUrl) async {
    try {
      final response = await http.get(Uri.parse(archiveUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> games = data['games'];
        return games.map((json) => ChessComGame.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching games: $e');
    }
    return [];
  }

  /// Fetches last 50 games for a user by iterating archives.
  Future<List<ChessComGame>> getRecentGames(String username) async {
    final archives = await getArchives(username);
    final allGames = <ChessComGame>[];
    
    // Iterate archives from newest to oldest until we have enough
    for (final url in archives) {
      if (allGames.length >= 50) break;
      final games = await getGamesFromArchive(url);
      // Sort games by end time (newest first) within the archive
      games.sort((a, b) => b.endTime.compareTo(a.endTime));
      allGames.addAll(games);
    }
    
    return allGames.take(50).toList();
  }
}

class ChessComGame {
  final String url;
  final String pgn;
  final String timeControl;
  final int endTime;
  final bool rated;
  final String whiteUsername;
  final String blackUsername;
  final int whiteRating;
  final int blackRating;
  final String? result; // win, checkmated, resigned, timeout, etc.

  ChessComGame({
    required this.url,
    required this.pgn,
    required this.timeControl,
    required this.endTime,
    required this.rated,
    required this.whiteUsername,
    required this.blackUsername,
    required this.whiteRating,
    required this.blackRating,
    this.result,
  });

  factory ChessComGame.fromJson(Map<String, dynamic> json) {
    return ChessComGame(
      url: json['url'] ?? '',
      pgn: json['pgn'] ?? '',
      timeControl: json['time_control'] ?? '',
      endTime: json['end_time'] ?? 0,
      rated: json['rated'] ?? false,
      whiteUsername: json['white']['username'] ?? 'Unknown',
      blackUsername: json['black']['username'] ?? 'Unknown',
      whiteRating: json['white']['rating'] ?? 0,
      blackRating: json['black']['rating'] ?? 0,
      result: json['white']['result'] == 'win' ? '1-0' : (json['black']['result'] == 'win' ? '0-1' : '1/2-1/2'), 
    );
  }
  
  DateTime get date => DateTime.fromMillisecondsSinceEpoch(endTime * 1000);
}
