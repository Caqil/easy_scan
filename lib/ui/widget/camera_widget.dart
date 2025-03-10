import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../../models/scan_settings.dart';

class CameraWidget extends StatefulWidget {
  final List<CameraDescription> cameras;
  final ScanMode scanMode;
  final Function(File) onImageCaptured;

  const CameraWidget({
    super.key,
    required this.cameras,
    required this.scanMode,
    required this.onImageCaptured,
  });

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget>
    with WidgetsBindingObserver {
  late CameraController _controller;
  bool _isInitialized = false;
  bool _isTakingPicture = false;
  int _selectedCameraIndex = 0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentZoom = 1.0;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera(_selectedCameraIndex);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize the camera
    if (!_controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(_selectedCameraIndex);
    }
  }

  Future<void> _initCamera(int cameraIndex) async {
    _controller = CameraController(
      widget.cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller.initialize();

      // Get zoom settings
      await _controller
          .getMinZoomLevel()
          .then((value) => _minAvailableZoom = value);
      await _controller
          .getMaxZoomLevel()
          .then((value) => _maxAvailableZoom = value);
      _currentZoom = _minAvailableZoom;

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      // Handle camera initialization error
    }
  }

  void _toggleCameraDirection() {
    if (widget.cameras.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
    _isInitialized = false;

    _initCamera(_selectedCameraIndex);
  }

  void _toggleFlash() {
    if (!_controller.value.isInitialized) return;

    setState(() {
      _isFlashOn = !_isFlashOn;
    });

    _isFlashOn
        ? _controller.setFlashMode(FlashMode.torch)
        : _controller.setFlashMode(FlashMode.off);
  }

  Future<void> _takePicture() async {
    if (!_controller.value.isInitialized || _isTakingPicture) {
      return;
    }

    setState(() {
      _isTakingPicture = true;
    });

    try {
      final XFile file = await _controller.takePicture();
      widget.onImageCaptured(File(file.path));
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isTakingPicture = false;
      });
    }
  }

  void _setZoom(double zoom) {
    if (!_controller.value.isInitialized) return;

    setState(() {
      _currentZoom = zoom;
    });

    _controller.setZoomLevel(zoom);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        // Camera preview
        Center(
          child: CameraPreview(_controller),
        ),

        // Overlay with document corners (placeholder)
        if (widget.scanMode == ScanMode.auto ||
            widget.scanMode == ScanMode.manual)
          Positioned.fill(
            child: CustomPaint(
              painter: DocumentOverlayPainter(),
            ),
          ),

        // Flash button
        Positioned(
          top: 16,
          right: 16,
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: Icon(
                _isFlashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              onPressed: _toggleFlash,
            ),
          ),
        ),

        // Zoom slider
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Slider(
                value: _currentZoom,
                min: _minAvailableZoom,
                max: _maxAvailableZoom,
                onChanged: _setZoom,
                activeColor: Colors.white,
                inactiveColor: Colors.white30,
              ),
            ),
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Gallery button (placeholder)
              CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    // Import from gallery instead of taking a picture
                  },
                ),
              ),

              // Capture button
              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                  ),
                  child: _isTakingPicture
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Container(
                          margin: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              ),

              // Camera toggle button
              CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                  ),
                  onPressed: _toggleCameraDirection,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DocumentOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw document corners (placeholder)
    final double margin = size.width * 0.15;
    final double cornerSize = 20;

    final rect = Rect.fromLTRB(
      margin,
      size.height * 0.2,
      size.width - margin,
      size.height * 0.8,
    );

    // Top-left corner
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerSize),
      Offset(rect.left, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerSize, rect.top),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rect.right - cornerSize, rect.top),
      Offset(rect.right, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerSize),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right, rect.bottom - cornerSize),
      Offset(rect.right, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right - cornerSize, rect.bottom),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left + cornerSize, rect.bottom),
      Offset(rect.left, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left, rect.bottom - cornerSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
