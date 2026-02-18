import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/chess_vision_service.dart';
import '../services/game_recorder.dart';

class CameraRecognitionScreen extends StatefulWidget {
  const CameraRecognitionScreen({super.key});

  @override
  State<CameraRecognitionScreen> createState() =>
      _CameraRecognitionScreenState();
}

class _CameraRecognitionScreenState extends State<CameraRecognitionScreen> {
  CameraController? _cameraController;
  final ChessVisionService _visionService = ChessVisionService();
  final GameRecorder _gameRecorder = GameRecorder();
  
  List<ChessPieceDetection> _detectedPieces = [];
  bool _isInitializing = true;
  bool _isDetecting = false;
  String? _errorMessage;
  double _fps = 0;
  DateTime? _lastFrameTime;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      // Request camera permission using permission_handler
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Camera permission denied';
          _isInitializing = false;
        });
        return;
      }

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'No cameras found';
          _isInitializing = false;
        });
        return;
      }

      // Use the back camera (usually better for board recognition)
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // Initialize camera controller
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, // Required for image processing
      );

      await _cameraController!.initialize();

      // Initialize vision service
      await _visionService.initialize();

      // Start image stream processing
      if (mounted) {
        _cameraController!.startImageStream(_processFrame);
      }

      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });

      debugPrint('✅ Camera and vision initialized successfully');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to initialize: $e';
        _isInitializing = false;
      });
      debugPrint('❌ Initialization error: $e');
    }
  }

  void _processFrame(CameraImage image) async {
    if (_isDetecting || !mounted) return;

    setState(() {
      _isDetecting = true;
    });

    // Calculate FPS
    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final elapsed = now.difference(_lastFrameTime!).inMilliseconds;
      if (elapsed > 0) {
        _fps = 1000 / elapsed;
      }
    }
    _lastFrameTime = now;

    try {
      // Detect pieces in the frame
      final rawDetections = await _visionService.detectPiecesFromFrame(image);
      final detections = _visionService.parseDetections(rawDetections);

      // Pass detection data to recorder (Future: Construct FEN from detections)
      // For now, we are just visualizing. In a full implementation, we'd map
      // bounding boxes to board squares here.
      
      if (mounted) {
        setState(() {
          _detectedPieces = detections;
          _isDetecting = false;
        });
      }
    } catch (e) {
      debugPrint('Error processing frame: $e');
      if (mounted) {
        setState(() {
          _isDetecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Chess Vision'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          // FPS counter
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${_fps.toStringAsFixed(1)} FPS',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _cameraController != null &&
              _cameraController!.value.isInitialized
          ? FloatingActionButton(
              onPressed: _toggleRecording,
              backgroundColor: _gameRecorder.isRecording ? Colors.red : Colors.cyan,
              child: Icon(_gameRecorder.isRecording ? Icons.stop : Icons.videocam),
            )
          : null,
    );
  }

  void _toggleRecording() {
    setState(() {
      if (_gameRecorder.isRecording) {
        _gameRecorder.stopRecording();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session Ended. saved to History.')),
        );
      } else {
        _gameRecorder.startNewGame();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Live Session Started! Broadcasting...')),
        );
      }
    });
  }

  Widget _buildBody() {
    // Show error state
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    // Show loading state
    if (_isInitializing) {
      return _buildLoadingState();
    }

    // Show camera preview with detections
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      return _buildCameraPreview();
    }

    return _buildErrorState();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.cyan),
          SizedBox(height: 16),
          Text('Initializing Optical Neural Network...', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _initializeCamera,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan.withOpacity(0.2),
              foregroundColor: Colors.cyanAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final camera = _cameraController!;
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        CameraPreview(camera),

        // HUD Overlay
        LayoutBuilder(
          builder: (context, constraints) {
            return CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: DetectionOverlayPainter(
                detections: _detectedPieces,
                imageSize: Size(
                  camera.value.previewSize!.height, // Height becomes width in portrait
                  camera.value.previewSize!.width,
                ),
              ),
            );
          }
        ),

        // Bottom Info Panel
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
              ),
            ),
            child: _buildDetectionsList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetectionsList() {
    if (_detectedPieces.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 60),
        child: Text(
          'Scanning for pieces...',
          style: TextStyle(color: Colors.white54, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Group pieces by color
    final whitePieces = _detectedPieces.where((p) => p.isWhite).length;
    final blackPieces = _detectedPieces.where((p) => p.isBlack).length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 60),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPieceCount('White', whitePieces, Colors.white),
          Container(width: 1, height: 20, color: Colors.white24),
          _buildPieceCount('Black', blackPieces, Colors.grey[400]!),
        ],
      ),
    );
  }
  
  Widget _buildPieceCount(String label, int count, Color color) {
      return Row(
          children: [
              Icon(Icons.circle, size: 8, color: color),
              const SizedBox(width: 8),
              Text(
                  '$label: $count',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                  ),
              ),
          ],
      );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _visionService.dispose();
    super.dispose();
  }
}

class DetectionOverlayPainter extends CustomPainter {
  final List<ChessPieceDetection> detections;
  final Size imageSize;

  DetectionOverlayPainter({
    required this.detections,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageSize.width == 0 || imageSize.height == 0) return;

    for (final detection in detections) {
      final box = detection.boundingBox;
      
      final scaleX = size.width / imageSize.width;
      final scaleY = size.height / imageSize.height;

      final left = box.left * scaleX;
      final top = box.top * scaleY;
      final width = box.width * scaleX;
      final height = box.height * scaleY;

      // Choose color based on piece color - Cyan/Gold theme
      final isWhite = detection.isWhite;
      final color = isWhite ? const Color(0xFF0D9488) : const Color(0xFFF59E0B);

      // Draw bounding box (High tech feel)
      final paint = Paint()
        ..color = color.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
        
      // Draw corners only for a cleaner look could be better, but full box for now
      canvas.drawRect(
        Rect.fromLTWH(left, top, width, height),
        paint,
      );

      // Label with confidence
      final textSpan = TextSpan(
        text: '${detection.pieceType.toUpperCase()} ${(detection.confidence * 100).toInt()}%',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          backgroundColor: Colors.black54,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(left, top - 14),
      );
    }
  }

  @override
  bool shouldRepaint(DetectionOverlayPainter oldDelegate) {
    return detections != oldDelegate.detections;
  }
}
