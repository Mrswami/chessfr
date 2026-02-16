import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:flutter/foundation.dart';

/// Service for chess piece detection using YOLOv8
class ChessVisionService {
  late FlutterVision _vision;
  bool _isInitialized = false;
  bool _isProcessing = false;

  bool get isInitialized => _isInitialized;
  bool get isProcessing => _isProcessing;

  /// Initialize the vision model
  Future<void> initialize() async {
    try {
      _vision = FlutterVision();
      
      // NOTE: You need to download a chess model first!
      // See assets/models/README.md for instructions
      await _vision.loadYoloModel(
        labels: 'assets/models/labels.txt',
        modelPath: 'assets/models/chess_yolov8.tflite',
        modelVersion: "yolov8",
        quantization: false,
        numThreads: 2,
        useGpu: true,
      );
      
      _isInitialized = true;
      debugPrint('✅ Chess vision model initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize chess vision model: $e');
      debugPrint('💡 Make sure to download the model file to assets/models/');
      debugPrint('   See assets/models/README.md for instructions');
      rethrow;
    }
  }

  /// Detect chess pieces in a camera frame
  Future<List<Map<String, dynamic>>> detectPiecesFromFrame(
    CameraImage image,
  ) async {
    if (!_isInitialized) {
      throw Exception('Vision service not initialized. Call initialize() first.');
    }

    if (_isProcessing) {
      return []; // Skip frame if still processing
    }

    _isProcessing = true;

    try {
      final result = await _vision.yoloOnFrame(
        bytesList: image.planes.map((plane) => plane.bytes).toList(),
        imageHeight: image.height,
        imageWidth: image.width,
        iouThreshold: 0.4, // Intersection over Union threshold
        confThreshold: 0.5, // Confidence threshold
        classThreshold: 0.5, // Class probability threshold
      );

      _isProcessing = false;
      return result;
    } catch (e) {
      _isProcessing = false;
      debugPrint('Error detecting pieces: $e');
      return [];
    }
  }

  /// Detect chess pieces from a static image (Uint8List)
  Future<List<Map<String, dynamic>>> detectPiecesFromImage(
    Uint8List imageBytes,
  ) async {
    if (!_isInitialized) {
      throw Exception('Vision service not initialized. Call initialize() first.');
    }

    try {
      final result = await _vision.yoloOnImage(
        bytesList: imageBytes,
        imageHeight: 640,
        imageWidth: 640,
        iouThreshold: 0.4,
        confThreshold: 0.5,
        classThreshold: 0.5,
      );

      return result;
    } catch (e) {
      debugPrint('Error detecting pieces from image: $e');
      return [];
    }
  }

  /// Parse detection results into structured data
  List<ChessPieceDetection> parseDetections(
    List<Map<String, dynamic>> rawDetections,
  ) {
    return rawDetections.map((detection) {
      // The output format from FlutterVision depends on the plugin version.
      // Usually it's: {'box': [x1, y1, x2, y2, conf], 'tag': 'label'}
      // But the typed output handled below assumes:
      // {'box': [x1, y1, x2, y2, conf], 'tag': 'class_name'}
      
      final box = detection['box']; // List<dynamic>
      final tag = detection['tag']; // String

      double x1 = 0, y1 = 0, x2 = 0, y2 = 0, conf = 0;
      
      if (box is List && box.length >= 5) {
        x1 = (box[0] as num).toDouble();
        y1 = (box[1] as num).toDouble();
        x2 = (box[2] as num).toDouble();
        y2 = (box[3] as num).toDouble();
        conf = (box[4] as num).toDouble();
      }

      // Calculate center and dimensions for our BoundingBox class
      final width = x2 - x1;
      final height = y2 - y1;
      final centerX = x1 + (width / 2);
      final centerY = y1 + (height / 2);

      return ChessPieceDetection(
        className: tag ?? 'unknown',
        confidence: conf,
        boundingBox: BoundingBox(
          x: centerX,
          y: centerY,
          width: width,
          height: height,
        ),
      );
    }).toList();
  }

  /// Clean up resources
  Future<void> dispose() async {
    if (_isInitialized) {
      await _vision.closeYoloModel();
      _isInitialized = false;
      debugPrint('Chess vision model disposed');
    }
  }
}

/// Represents a detected chess piece
class ChessPieceDetection {
  final String className; // e.g., "white-king", "black-pawn"
  final double confidence; // 0.0 to 1.0
  final BoundingBox boundingBox;

  ChessPieceDetection({
    required this.className,
    required this.confidence,
    required this.boundingBox,
  });

  /// Get the piece type (king, queen, etc.)
  String get pieceType {
    if (className.contains('-')) {
        return className.split('-').last;
    }
    return className;
  }

  /// Get the piece color (white or black)
  String get color {
    if (className.contains('-')) {
        return className.split('-').first;
    }
    return 'unknown';
  }

  /// Check if this is a white piece
  bool get isWhite => color == 'white';

  /// Check if this is a black piece
  bool get isBlack => color == 'black';

  @override
  String toString() {
    return 'ChessPieceDetection($className, conf: ${confidence.toStringAsFixed(2)}, '
        'box: ${boundingBox.toString()})';
  }
}

/// Represents a bounding box for a detected object
class BoundingBox {
  final double x; // Center X
  final double y; // Center Y
  final double width;
  final double height;

  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Get top-left corner coordinates
  double get left => x - (width / 2);
  double get top => y - (height / 2);

  /// Get bottom-right corner coordinates
  double get right => x + (width / 2);
  double get bottom => y + (height / 2);

  @override
  String toString() {
    return 'BoundingBox(x: ${x.toStringAsFixed(0)}, y: ${y.toStringAsFixed(0)}, w: ${width.toStringAsFixed(0)}, h: ${height.toStringAsFixed(0)})';
  }
}
