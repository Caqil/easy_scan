import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  /// Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request storage permissions
  static Future<bool> requestStoragePermissions() async {
    // Request both read and write permissions
    final storageStatus = await Permission.storage.request();

    // On Android 13+ we need to request separate permissions
    final photosStatus = await Permission.photos.request();

    return storageStatus.isGranted || photosStatus.isGranted;
  }

  /// Check if camera permission is granted
  static Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  /// Check if storage permissions are granted
  static Future<bool> hasStoragePermissions() async {
    return await Permission.storage.isGranted ||
        await Permission.photos.isGranted;
  }

  /// Open app settings
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }
}
