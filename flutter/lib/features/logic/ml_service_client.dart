import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class MLPredictResponse {
  final String fen;
  final List<MLMovePrediction> topMoves;

  MLPredictResponse({required this.fen, required this.topMoves});

  factory MLPredictResponse.fromJson(Map<String, dynamic> json) {
    final list = json['top_moves'] as List? ?? [];
    return MLPredictResponse(
      fen: json['fen'] ?? '',
      topMoves: list.map((e) => MLMovePrediction.fromJson(e)).toList(),
    );
  }
}

class MLMovePrediction {
  final String uci;
  final String san;
  final double probability;
  final String insights;
  final MLMoveVisualOverlay visuals;

  MLMovePrediction({
    required this.uci,
    required this.san,
    required this.probability,
    required this.insights,
    required this.visuals,
  });

  factory MLMovePrediction.fromJson(Map<String, dynamic> json) {
    return MLMovePrediction(
      uci: json['uci'] ?? '',
      san: json['san'] ?? '',
      probability: (json['probability'] as num? ?? 0.0).toDouble(),
      insights: json['insights'] ?? '',
      visuals: MLMoveVisualOverlay.fromJson(json['visuals'] ?? {}),
    );
  }
}

class MLMoveVisualOverlay {
  final String color;
  final double blunderRisk;
  final bool cognitiveTunnel;

  MLMoveVisualOverlay({
    required this.color,
    required this.blunderRisk,
    required this.cognitiveTunnel,
  });

  factory MLMoveVisualOverlay.fromJson(Map<String, dynamic> json) {
    return MLMoveVisualOverlay(
      color: json['probability_color'] ?? 'sapphire',
      blunderRisk: (json['blunder_risk'] as num? ?? 0.0).toDouble(),
      cognitiveTunnel: json['cognitive_tunnel'] ?? false,
    );
  }
}

class MLServiceClient {
  static final MLServiceClient _instance = MLServiceClient._internal();
  factory MLServiceClient() => _instance;
  MLServiceClient._internal();

  String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Loopback to host machine inside Android emulator
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  /// Sends the current chess FEN and playstyle parameters to the DankFish API service.
  Future<MLPredictResponse> predictHumanMove({
    required String fen,
    int elo = 1200,
    String archetype = 'London Squeezer',
  }) async {
    final url = Uri.parse('$_baseUrl/api/v1/predict/human-move');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fen': fen,
          'elo': elo,
          'archetype': archetype,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return MLPredictResponse.fromJson(decoded);
      } else {
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('MLServiceClient Error hitting predictions API: $e');
      rethrow;
    }
  }
}
