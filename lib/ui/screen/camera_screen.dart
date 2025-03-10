import 'dart:io';
import 'package:easy_scan/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';

import '../../models/scan_settings.dart';
import '../../providers/scan_provider.dart';
import '../../services/camera_service.dart';
import '../../services/image_service.dart';
import '../../utils/permission_utils.dart';
import '../common/app_bar.dart';
import '../widget/camera_widget.dart';
import '../widget/scan_options.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final CameraService _cameraService = CameraService();
  final ImageService _imageService = ImageService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isInitialized = false;
  bool _hasPermission = false;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Check camera permission
    final hasPermission = await PermissionUtils.hasCameraPermission();
    if (!hasPermission) {
      final granted = await PermissionUtils.requestCameraPermission();
      if (!granted) {
        setState(() {
          _isInitialized = true;
          _hasPermission = false;
        });
        return;
      }
    }

    // Initialize camera
    final initialized = await _cameraService.initializeCameras();
    if (initialized) {
      setState(() {
        _isInitialized = true;
        _hasPermission = true;
        _cameras = _cameraService.cameras;
      });
    } else {
      setState(() {
        _isInitialized = true;
        _hasPermission = false;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        final scanState = ref.read(scanProvider);
        ref.read(scanProvider.notifier).setScanning(true);

        for (var image in images) {
          final File imageFile = File(image.path);
          final File processedFile = await _imageService.enhanceImage(
            imageFile,
            scanState.settings.colorMode,
            quality: scanState.settings.quality,
          );
          ref.read(scanProvider.notifier).addPage(processedFile);
        }

        ref.read(scanProvider.notifier).setScanning(false);

        // Navigate to edit screen
        if (ref.read(scanProvider).scannedPages.isNotEmpty) {
          // ignore: use_build_context_synchronously
          AppRoutes.navigateToEdit(context);
        }
      }
    } catch (e) {
      ref.read(scanProvider.notifier).setScanning(false);
      ref.read(scanProvider.notifier).setError(e.toString());
    }
  }

  void _showScanOptions() {
    final scanState = ref.read(scanProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: ScanOptionsWidget(
          settings: scanState.settings,
          onSettingsChanged: (newSettings) {
            ref.read(scanProvider.notifier).updateSettings(newSettings);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Scan Document'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showScanOptions,
          ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickImages,
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : !_hasPermission
              ? _buildNoPermissionView()
              : _cameras == null || _cameras!.isEmpty
                  ? _buildNoCameraView()
                  : CameraWidget(
                      cameras: _cameras!,
                      scanMode: scanState.settings.scanMode,
                      onImageCaptured: (File imageFile) async {
                        ref.read(scanProvider.notifier).setScanning(true);

                        try {
                          final File processedFile =
                              await _imageService.enhanceImage(
                            imageFile,
                            scanState.settings.colorMode,
                            quality: scanState.settings.quality,
                          );

                          ref
                              .read(scanProvider.notifier)
                              .addPage(processedFile);

                          if (scanState.settings.scanMode == ScanMode.batch) {
                            // In batch mode, stay on camera to take more pictures
                            // Show a small indicator of how many photos were taken
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Page ${ref.read(scanProvider).scannedPages.length} captured',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          } else {
                            // In other modes, go to edit screen
                            // ignore: use_build_context_synchronously
                            AppRoutes.navigateToEdit(context);
                          }
                        } catch (e) {
                          ref
                              .read(scanProvider.notifier)
                              .setError(e.toString());
                        } finally {
                          ref.read(scanProvider.notifier).setScanning(false);
                        }
                      },
                    ),
      floatingActionButton: scanState.settings.scanMode == ScanMode.batch &&
              scanState.scannedPages.isNotEmpty
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.check),
              label: Text('Done (${scanState.scannedPages.length})'),
              onPressed: () {
                AppRoutes.navigateToEdit(context);
              },
            )
          : null,
    );
  }

  Widget _buildNoPermissionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.no_photography,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera Permission Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please grant camera permission to scan documents',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final granted = await PermissionUtils.requestCameraPermission();
                if (granted) {
                  await _initializeCamera();
                } else {
                  // Open app settings
                  // ignore: use_build_context_synchronously
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Permission Required'),
                      content: const Text(
                        'Camera permission is needed to scan documents. '
                        'Please grant this permission in app settings.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            PermissionUtils.openAppSettings();
                          },
                          child: const Text('Open Settings'),
                        ),
                      ],
                    ),
                  );
                }
              },
              child: const Text('Grant Permission'),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Import from Gallery'),
              onPressed: _pickImages,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCameraView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.no_photography,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No camera available',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.photo_library),
            label: const Text('Import from Gallery'),
            onPressed: _pickImages,
          ),
        ],
      ),
    );
  }
}
