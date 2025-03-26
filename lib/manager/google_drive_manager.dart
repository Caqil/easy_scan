import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:scanpro/main.dart';
import 'package:scanpro/utils/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

/// A service class to handle Google Drive backup operations
class GoogleDriveManager {
  static final GoogleDriveManager _instance = GoogleDriveManager._internal();
  factory GoogleDriveManager() => _instance;

  GoogleDriveManager._internal();

  // Google Sign In instance with required scopes for Drive access
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
      drive.DriveApi.driveAppdataScope,
    ],
  );

  // Flag to track authentication status
  bool _isSignedIn = false;

  /// Initialize Google Drive service
  Future<bool> initialize() async {
    try {
      // Check if user is already signed in
      _isSignedIn = await _googleSignIn.isSignedIn();
      logger.info('Google Drive initialized, signed in: $_isSignedIn');
      return _isSignedIn;
    } catch (e) {
      logger.error('Error initializing Google Drive: $e');
      return false;
    }
  }

  /// Check if Google Drive is available
  Future<bool> isDriveAvailable() async {
    try {
      // If already signed in, return true
      if (_isSignedIn) return true;

      // Try silent sign in first to check availability
      try {
        final account = await _googleSignIn.signInSilently();
        _isSignedIn = account != null;
        return _isSignedIn;
      } catch (e) {
        logger.warning('Silent sign-in failed: $e');
        // If silent sign-in fails, Drive may still be available
        // but requires explicit authentication
        return true;
      }
    } catch (e) {
      logger.error('Error checking Google Drive availability: $e');
      return false;
    }
  }

  /// Sign in to Google Drive
  Future<bool> signIn() async {
    try {
      // If already signed in, return true
      if (_isSignedIn) return true;

      final account = await _googleSignIn.signIn();
      _isSignedIn = account != null;
      logger.info(
          'Google Drive sign in ${_isSignedIn ? 'successful' : 'failed'}');
      return _isSignedIn;
    } catch (e) {
      logger.error('Error signing in to Google Drive: $e');
      return false;
    }
  }

  /// Sign out from Google Drive
  Future<bool> signOut() async {
    try {
      await _googleSignIn.signOut();
      _isSignedIn = false;
      logger.info('Google Drive signed out');
      return true;
    } catch (e) {
      logger.error('Error signing out from Google Drive: $e');
      return false;
    }
  }

  /// Get Google Drive API client
  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      // Ensure signed in
      if (!_isSignedIn) {
        final success = await signIn();
        if (!success) return null;
      }

      // Get authenticated HTTP client
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        logger.error('Failed to get authenticated HTTP client');
        return null;
      }

      // Create Drive API client
      return drive.DriveApi(httpClient);
    } catch (e) {
      logger.error('Error getting Drive API client: $e');
      return null;
    }
  }

  /// Upload a file to Google Drive
  Future<bool> uploadFileToDrive(
    File file,
    String mimeType,
    String name, {
    Function(double)? onProgress,
  }) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        logger.error('Drive API not available');
        return false;
      }

      onProgress?.call(0.1);

      // Create file metadata
      final fileMedia = drive.Media(
        file.openRead(),
        await file.length(),
      );

      // Create file with proper mime type and name
      var driveFile = drive.File();
      driveFile.name = name;
      driveFile.mimeType = mimeType;

      // Add a custom property to identify our app's backups
      driveFile.appProperties = {
        'appName': 'scanpro',
        'backupType': 'full',
      };

      onProgress?.call(0.2);

      // Upload the file
      final result = await driveApi.files.create(
        driveFile,
        uploadMedia: fileMedia,
      );

      onProgress?.call(1.0);

      logger.info('File uploaded to Google Drive with ID: ${result.id}');
      return result.id != null;
    } catch (e) {
      logger.error('Error uploading file to Google Drive: $e');
      return false;
    }
  }

  /// Download a file from Google Drive
  Future<String?> downloadFileFromDrive(
    String fileId, {
    Function(double)? onProgress,
  }) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        logger.error('Drive API not available');
        return null;
      }

      onProgress?.call(0.1);

      // Get file metadata
      final file = await driveApi.files.get(fileId) as drive.File;
      if (file.name == null) {
        logger.error('Drive file has no name');
        return null;
      }

      onProgress?.call(0.2);

      // Download the file content
      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      // Create a temporary file path
      final tempDir = await getTemporaryDirectory();
      final filePath = path.join(tempDir.path, file.name!);

      // Create file and write the contents
      final bytes = await media.stream.toList();
      final byteData = bytes.expand((e) => e).toList();

      onProgress?.call(0.8);

      // Write the data to a file
      final tempFile = File(filePath);
      await tempFile.writeAsBytes(byteData);

      onProgress?.call(1.0);

      logger.info('File downloaded from Google Drive: $filePath');
      return filePath;
    } catch (e) {
      logger.error('Error downloading file from Google Drive: $e');
      return null;
    }
  }

  /// List available backups from Google Drive
  Future<List<Map<String, dynamic>>> listDriveBackups() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        logger.error('Drive API not available');
        return [];
      }

      // Query for our app's backup files
      final fileList = await driveApi.files.list(
        q: "appProperties has { key='appName' and value='scanpro' } and trashed=false",
        $fields: 'files(id, name, size, createdTime, modifiedTime)',
      );

      final files = fileList.files ?? [];
      logger.info('Found ${files.length} backup files in Google Drive');

      List<Map<String, dynamic>> backups = [];

      for (var file in files) {
        if (file.name != null &&
            file.name!.contains(AppConstants.backupFilePrefix)) {
          backups.add({
            'id': file.id ?? '',
            'name': file.name ?? 'Unknown',
            'date': file.modifiedTime?.toIso8601String() ?? 'Unknown date',
            'size': file.size != null
                ? _formatSize(int.parse(file.size!))
                : 'Unknown size',
          });
        }
      }

      // Sort by date (newest first)
      backups.sort((a, b) {
        if (a['date'] == 'Unknown date' || b['date'] == 'Unknown date') {
          return 0;
        }
        return DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']));
      });

      return backups;
    } catch (e) {
      logger.error('Error listing backups from Google Drive: $e');
      return [];
    }
  }

  /// Delete a file from Google Drive
  Future<bool> deleteFileFromDrive(String fileId) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        logger.error('Drive API not available');
        return false;
      }

      await driveApi.files.delete(fileId);
      logger.info('File deleted from Google Drive: $fileId');
      return true;
    } catch (e) {
      logger.error('Error deleting file from Google Drive: $e');
      return false;
    }
  }

  // Helper method to format file size
  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }
}
