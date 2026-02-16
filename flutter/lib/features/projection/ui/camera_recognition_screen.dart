import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/chess_vision_service.dart';

class CameraRecognitionScreen extends StatefulWidget {
  const CameraRecognitionScreen({super.key});

  @override
  State<CameraRecognitionScreen> createState() =>
      _CameraRecognitionScreenState();
}

class _CameraRecognitionScreenState extends State<CameraRecognitionScreen> {
  CameraController? _cameraController;
  final ChessVisionService _visionService = ChessVisionService();
  
  List<ChessPieceDetection> _detectedPieces = [];
  bool _isInitializing = true;
  bool _isDetecting = false;
  String? _errorMessage;
  int _frameCount = 0;
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
      _frameCount++;
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
      appBar: AppBar(
        title: const Text('Camera Chess Recognition'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          // FPS counter
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_fps.toStringAsFixed(1)} FPS',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
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
              onPressed: _toggleDetection,
              child: Icon(_isDetecting ? Icons.pause : Icons.play_arrow),
            )
          : null,
    );
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
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing camera and AI model...'),
          SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
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
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _initializeCamera,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final camera = _cameraController!;
    final size = MediaQuery.of(context).size;
    
    // Calculate scale to fit camera preview
    // Note: This scaling logic is tricky in Flutter camera. 
    // Usually need to handle aspect ratios carefully.
    // For now, using a simplified Fit.
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        CameraPreview(camera),

        // Detection overlay
        // We need to ensure the overlay size matches the PREVIEW size, not just screen size.
        // But for UI overlay, we paint on screen coords.
        LayoutBuilder(
          builder: (context, constraints) {
            return CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: DetectionOverlayPainter(
                detections: _detectedPieces,
                // The preview size is rotated 90deg on portrait phones usually.
                // We pass the raw image size from the camera.
                imageSize: Size(
                  camera.value.previewSize!.height, // Height becomes width in portrait
                  camera.value.previewSize!.width,
                ),
              ),
            );
          }
        ),

        // Stats overlay
        Positioned(
          top: 16,
          left: 16,
          child: _buildStatsCard(),
        ),

        // Detected pieces list
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: _buildDetectionsList(),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detected: ${_detectedPieces.length} pieces',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Frames: $_frameCount',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionsList() {
    if (_detectedPieces.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          '🎯 Point camera at chess board',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Group pieces by color
    final whitePieces = _detectedPieces.where((p) => p.isWhite).toList();
    final blackPieces = _detectedPieces.where((p) => p.isBlack).toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (whitePieces.isNotEmpty) ...[
              Text(
                '⚪ White (${whitePieces.length}):',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                whitePieces.map((p) => p.pieceType).join(', '),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
            ],
            if (blackPieces.isNotEmpty) ...[
              Text(
                '⚫ Black (${blackPieces.length}):',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                blackPieces.map((p) => p.pieceType).join(', '),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleDetection() {
    // This could pause/resume detection in a future enhancement
    debugPrint('Toggle detection (future feature)');
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

      // Scale coordinates from image space to screen space
      // Note: This scaling assumes the image fills the screen (fitHeight / fitWidth).
      // Since we use CameraPreview, it typically covers.
      // However, we need to match the aspect ratio logic of the preview.
      // Usually, CameraPreview scales to cover.
      
      final scaleX = size.width / imageSize.width;
      final scaleY = size.height / imageSize.height;

      final left = box.left * scaleX;
      final top = box.top * scaleY;
      final width = box.width * scaleX;
      final height = box.height * scaleY;

      // Choose color based on piece color
      final color = detection.isWhite ? Colors.white : Colors.black;

      // Draw bounding box
      final paint = Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawRect(
        Rect.fromLTWH(left, top, width, height),
        paint,
      );

      // Draw filled background for label
      final labelPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      const labelHeight = 24.0;
      canvas.drawRect(
        Rect.fromLTWH(left, top - labelHeight, width, labelHeight),
        labelPaint,
      );

      // Draw label text
      final textStyle = TextStyle(
        color: detection.isWhite ? Colors.black : Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      );

      final textSpan = TextSpan(
        text: '${detection.pieceType} ${(detection.confidence * 100).toStringAsFixed(0)}%',
        style: textStyle,
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(left + 4, top - labelHeight + 4),
      );
    }
  }

  @override
  bool shouldRepaint(DetectionOverlayPainter oldDelegate) {
    return detections != oldDelegate.detections;
  }
}
