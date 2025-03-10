import 'dart:io';
import 'package:camera/camera.dart';
import '../utils/file_utils.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;

  /// Initialize available cameras
  Future<bool> initializeCameras() async {
    try {
      _cameras = await availableCameras();
      return _cameras != null && _cameras!.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Create a camera controller
  CameraController? createController({
    ResolutionPreset resolution = ResolutionPreset.high,
    int cameraIndex = 0,
  }) {
    if (_cameras == null ||
        _cameras!.isEmpty ||
        cameraIndex >= _cameras!.length) {
      return null;
    }

    _controller = CameraController(
      _cameras![cameraIndex],
      resolution,
      enableAudio: false,
    );

    return _controller;
  }

  /// Check if camera is initialized
  bool get isCameraInitialized => _controller?.value.isInitialized ?? false;

  /// Get current camera controller
  CameraController? get controller => _controller;

  /// Capture an image and save it to a temporary file
  Future<File?> captureImage() async {
    if (_controller == null || !isCameraInitialized) {
      return null;
    }

    try {
      // Capture the image
      final XFile file = await _controller!.takePicture();

      // Create a unique filename
      final String filePath = await FileUtils.getUniqueFilePath(
        documentName: 'scan_${DateTime.now().millisecondsSinceEpoch}',
        extension: 'jpg',
        inTempDirectory: true,
      );

      // Copy the captured image to our filepath
      final File capturedFile = File(file.path);
      return capturedFile.copy(filePath);
    } catch (e) {
      return null;
    }
  }

  /// Dispose of the camera controller
  void disposeController() {
    _controller?.dispose();
    _controller = null;
  }
}
