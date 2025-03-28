import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hive/hive.dart';
import 'package:scanpro/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/services/file_limit_service.dart';
import 'package:scanpro/utils/constants.dart';
import 'package:scanpro/utils/premium_upgrade_utils.dart';

import '../providers/scan_provider.dart';
import '../ui/common/dialogs.dart';
import '../utils/permission_utils.dart';
import '../config/routes.dart';

/// A global service for handling document scanning and image picking
class ScanService {
  final ImagePicker _imagePicker = ImagePicker();

  /// Show permission dialog if camera permission is denied
  void showPermissionDialog(BuildContext context) {
    AppDialogs.showConfirmDialog(
      context,
      title: 'permissions.permission_required'.tr(),
      message:
          'Camera permission is needed to scan documents. Would you like to open app settings?',
      confirmText: 'Open Settings',
      cancelText: 'Cancel',
    ).then((confirmed) {
      if (confirmed) {
        PermissionUtils.openAppSettings();
      }
    });
  }

  Future<void> scanDocuments({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) setLoading,
    VoidCallback? onSuccess,
  }) async {
    final fileLimitService = FileLimitService();
    final result = await fileLimitService.forceCheckFileLimitReached(
      Hive.box<Document>(AppConstants.documentsBoxName),
    );
    if (result) {
      PremiumUpgradeUtils.showFileLimitReachedDialog(context);
      return;
    }

    final hasPermission = await PermissionUtils.hasCameraPermission();
    if (!hasPermission) {
      final granted = await PermissionUtils.requestCameraPermission();
      if (!granted) {
        showPermissionDialog(context);
        return;
      }
    }

    try {
      setLoading(true);
      List<String> imagePaths = [];
      try {
        // Use cunning_document_scanner instead of flutter_doc_scanner
        imagePaths = await CunningDocumentScanner.getPictures() ?? [];
        logger.info('Scanned images: $imagePaths');
      } catch (e) {
        if (context.mounted) {
          AppDialogs.showSnackBar(
            context,
            message: 'Error scanning: ${e.toString()}',
          );
        }
        setLoading(false);
        return;
      }

      // User canceled or no images captured
      if (imagePaths.isEmpty) {
        setLoading(false);
        return;
      }

      // Pre-process path validation
      List<File> validImageFiles = [];
      for (String path in imagePaths) {
        final File file = File(path);
        if (await file.exists()) {
          validImageFiles.add(file);
        }
      }

      if (validImageFiles.isEmpty) {
        if (context.mounted) {
          AppDialogs.showSnackBar(
            context,
            message: 'errors.no_valid_images'.tr(),
          );
        }
        setLoading(false);
        return;
      }

      // Process all images and add to scan provider
      ref.read(scanProvider.notifier).clearPages(); // Clear any existing pages

      for (File imageFile in validImageFiles) {
        try {
          ref.read(scanProvider.notifier).addPage(imageFile);
        } catch (e) {
          // Just skip failed images to improve reliability
          logger.info('Failed to process image: $e');
        }
      }

      setLoading(false);

      // If we have pages, navigate to edit screen or call success callback
      if (ref.read(scanProvider).hasPages) {
        if (onSuccess != null) {
          onSuccess();
        } else if (context.mounted) {
          AppRoutes.navigateToEdit(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'Error: ${e.toString()}',
        );
      }
      setLoading(false);
    }
  }

  /// Pick images from gallery
  Future<void> pickImages({
    required BuildContext context,
    required WidgetRef ref,
    required Function(bool) setLoading,
    VoidCallback? onSuccess,
  }) async {
    final fileLimitService = FileLimitService();
    final result = await fileLimitService.forceCheckFileLimitReached(
      Hive.box<Document>(AppConstants.documentsBoxName),
    );
    if (result) {
      PremiumUpgradeUtils.showFileLimitReachedDialog(context);
      return;
    }
    try {
      setLoading(true);

      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isEmpty || !context.mounted) {
        setLoading(false);
        return;
      }

      // Clear any existing pages
      ref.read(scanProvider.notifier).clearPages();

      for (var image in images) {
        final File imageFile = File(image.path);
        ref.read(scanProvider.notifier).addPage(imageFile);
      }

      if (context.mounted) {
        setLoading(false);

        if (ref.read(scanProvider).hasPages) {
          if (onSuccess != null) {
            onSuccess();
          } else if (context.mounted) {
            AppRoutes.navigateToEdit(context);
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppDialogs.showSnackBar(context, message: 'Error: ${e.toString()}');
        setLoading(false);
      }
    }
  }
}

/// Provider for the scan service
final scanServiceProvider = Provider<ScanService>((ref) {
  return ScanService();
});
