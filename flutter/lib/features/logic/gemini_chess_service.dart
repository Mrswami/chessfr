import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// The result of a Gemini chess position analysis.
class ChessAnalysisResult {
  final String category;
  final String suggestedName;
  final String openingDetected;
  final String sideToMove;
  final CoreScore coreScore;
  final String psychologicalVibe;
  final List<String> patternsDetected;
  final List<String> blindspotFlags;
  final String opponentArchetype;
  final bool cavernDetected;
  final String coachingPriority;
  final String structuralLesson;
  final List<String> tags;
  final bool nsfw;
  final Map<String, dynamic> rawJson;

  ChessAnalysisResult({
    required this.category,
    required this.suggestedName,
    required this.openingDetected,
    required this.sideToMove,
    required this.coreScore,
    required this.psychologicalVibe,
    required this.patternsDetected,
    required this.blindspotFlags,
    required this.opponentArchetype,
    required this.cavernDetected,
    required this.coachingPriority,
    required this.structuralLesson,
    required this.tags,
    required this.nsfw,
    required this.rawJson,
  });

  factory ChessAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ChessAnalysisResult(
      category: json['category'] ?? 'Chess Position',
      suggestedName: json['suggested_name'] ?? 'Unknown_Position',
      openingDetected: json['opening_detected'] ?? 'Unknown',
      sideToMove: json['side_to_move'] ?? 'Unknown',
      coreScore: CoreScore.fromJson(json['core_score'] ?? {}),
      psychologicalVibe: json['psychological_vibe'] ?? 'Standard',
      patternsDetected: List<String>.from(json['patterns_detected'] ?? []),
      blindspotFlags: List<String>.from(json['blindspot_flags'] ?? []),
      opponentArchetype: json['opponent_archetype'] ?? 'Unknown',
      cavernDetected: json['cavern_detected'] == true || json['cavern_detected'] == 'true',
      coachingPriority: json['coaching_priority'] ?? '',
      structuralLesson: json['structural_lesson'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      nsfw: json['nsfw'] == true,
      rawJson: json,
    );
  }

  factory ChessAnalysisResult.error(String message) {
    return ChessAnalysisResult(
      category: 'Error',
      suggestedName: 'Analysis_Failed',
      openingDetected: 'Unknown',
      sideToMove: 'Unknown',
      coreScore: CoreScore.empty(),
      psychologicalVibe: 'Unknown',
      patternsDetected: [],
      blindspotFlags: [],
      opponentArchetype: 'Unknown',
      cavernDetected: false,
      coachingPriority: message,
      structuralLesson: '',
      tags: [],
      nsfw: false,
      rawJson: {'error': message},
    );
  }
}

class CoreScore {
  final String centerDynamics;
  final String operationalSpace;
  final String redMistTrigger;
  final String endgameIntegrity;

  CoreScore({
    required this.centerDynamics,
    required this.operationalSpace,
    required this.redMistTrigger,
    required this.endgameIntegrity,
  });

  factory CoreScore.fromJson(Map<String, dynamic> json) {
    return CoreScore(
      centerDynamics: json['center_dynamics'] ?? 'Unknown',
      operationalSpace: json['operational_space'] ?? 'Unknown',
      redMistTrigger: json['red_mist_trigger'] ?? 'Unknown',
      endgameIntegrity: json['endgame_integrity'] ?? 'Unknown',
    );
  }

  factory CoreScore.empty() {
    return CoreScore(
      centerDynamics: 'Unknown',
      operationalSpace: 'Unknown',
      redMistTrigger: 'Unknown',
      endgameIntegrity: 'Unknown',
    );
  }
}

/// Service that calls the Gemini API with the ChessLessons system instruction
/// to analyze submitted chess position screenshots.
class GeminiChessService {
  static const String _geminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  final String apiKey;
  String? _systemInstruction;
  bool _loaded = false;

  GeminiChessService({required this.apiKey});

  /// Loads the chess system instruction from assets once at startup.
  Future<void> initialize() async {
    if (_loaded) return;
    try {
      _systemInstruction = await rootBundle.loadString(
        'assets/chess_system_instruction.md',
      );
      _loaded = true;
    } catch (e) {
      _systemInstruction = _fallbackInstruction;
      _loaded = true;
    }
  }

  /// Analyzes a chess screenshot from a [File] and returns a [ChessAnalysisResult].
  Future<ChessAnalysisResult> analyzeScreenshot(File imageFile) async {
    await initialize();
    final Uint8List imageBytes = await imageFile.readAsBytes();
    return _callGemini(imageBytes, imageFile.path.split('.').last);
  }

  /// Analyzes a chess screenshot from raw [Uint8List] bytes.
  Future<ChessAnalysisResult> analyzeScreenshotBytes(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) async {
    await initialize();
    return _callGemini(imageBytes, mimeType.split('/').last);
  }

  Future<ChessAnalysisResult> _callGemini(
    Uint8List imageBytes,
    String extension,
  ) async {
    final String base64Image = base64Encode(imageBytes);
    final String mimeType = _mimeTypeFromExtension(extension);

    final Map<String, dynamic> requestBody = {
      'system_instruction': {
        'parts': [
          {'text': _systemInstruction ?? _fallbackInstruction},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              },
            },
            {
              'text':
                  'Analyze this chess position screenshot using the AmateurSwami ChessLessons grounding. Return only a valid JSON object matching the required schema.',
            },
          ],
        },
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.3,
        'maxOutputTokens': 1024,
      },
    };

    try {
      final response = await http.post(
        Uri.parse('$_geminiEndpoint?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        return ChessAnalysisResult.error(
          'Gemini API error ${response.statusCode}: ${response.body}',
        );
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final candidates = responseData['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return ChessAnalysisResult.error('No analysis candidates returned.');
      }

      final parts = candidates[0]['content']['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        return ChessAnalysisResult.error('No content parts in response.');
      }

      final String jsonText = parts[0]['text'] as String? ?? '';
      // Strip markdown fences if present
      final String cleanJson = jsonText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final Map<String, dynamic> parsed = jsonDecode(cleanJson);
      return ChessAnalysisResult.fromJson(parsed);
    } on SocketException {
      return ChessAnalysisResult.error(
        'Network error: Could not reach Gemini API.',
      );
    } on FormatException catch (e) {
      return ChessAnalysisResult.error('JSON parse error: $e');
    } catch (e) {
      return ChessAnalysisResult.error('Unexpected error: $e');
    }
  }

  String _mimeTypeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  static const String _fallbackInstruction = '''
You are DankFish, the AI coaching engine for ChessTrainerXL.
Analyze the chess position screenshot and return a JSON object with these fields:
category, suggested_name, opening_detected, side_to_move, core_score (center_dynamics, operational_space, red_mist_trigger, endgame_integrity), psychological_vibe, patterns_detected (array), blindspot_flags (array), opponent_archetype, cavern_detected, coaching_priority, structural_lesson, tags (array), nsfw.
Return ONLY valid JSON. No markdown fences.
''';
}
