import 'dart:convert';
import 'package:flutter/services.dart';

class ChessPattern {
  final String category;
  final String name;
  final String description;
  final String link;
  final String fen;
  bool isUnlocked;
  bool isMastered;

  ChessPattern({
    required this.category,
    required this.name,
    required this.description,
    required this.link,
    required this.fen,
    this.isUnlocked = false,
    this.isMastered = false,
  });

  factory ChessPattern.fromJson(Map<String, dynamic> json) {
    return ChessPattern(
      category: json['category'] ?? 'General',
      name: json['name'] ?? 'Unknown Pattern',
      description: json['description'] ?? '',
      link: json['link'] ?? '',
      fen: json['fen'] ?? '',
    );
  }
}

class PatternsProvider {
  List<ChessPattern> _patterns = [];
  bool _isLoading = true;

  List<ChessPattern> get patterns => _patterns;
  bool get isLoading => _isLoading;

  Future<void> loadPatterns() async {
    try {
      final String response = await rootBundle.loadString('assets/chess_patterns_clean.json');
      final List<dynamic> data = json.decode(response);
      _patterns = data.map((json) => ChessPattern.fromJson(json)).toList();
      _isLoading = false;
    } catch (e) {
      print("Error loading patterns: $e");
      _isLoading = false;
    }
  }

  List<ChessPattern> getByCategory(String category) {
    return _patterns.where((p) => p.category == category).toList();
  }

  List<String> getCategories() {
    return _patterns.map((p) => p.category).toSet().toList();
  }
  
  ChessPattern? findByFen(String fen) {
    // Basic FEN comparison (ignoring move clocks and half-moves for pattern matching)
    String normalize(String f) => f.split(' ').first;
    final normalizedTarget = normalize(fen);
    
    try {
      return _patterns.firstWhere((p) => p.fen.isNotEmpty && normalize(p.fen) == normalizedTarget);
    } catch (_) {
      return null;
    }
  }
}
