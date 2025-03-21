import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:scanpro/providers/barcode_provider.dart';
import 'package:scanpro/providers/document_provider.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/services/subscription_service.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/models/barcode_scan.dart';

/// Service to manage file limits for free users
class FileLimitService {
  static const String _fileCountKey = 'total_files_count';
  static const int _freeUserFileLimit = 5;

  /// Get the current number of documents
  int getDocumentsCount(List<Document> documents) {
    return documents.length;
  }

  /// Get the total number of files
  int getTotalFilesCount(List<Document> documents) {
    final docCount = getDocumentsCount(documents);
    final total = docCount;

    print("DEBUG FILE COUNT: Documents: $docCount");

    return total;
  }

  /// Force immediate check of file limits without using providers
  Future<bool> forceCheckFileLimitReached(Box<Document> documentsBox) async {
    final documents = documentsBox.values.toList();

    final totalCount = documents.length;
    print("FORCE CHECK: Total files: $totalCount");

    final subscriptionService = SubscriptionService();
    final isPremium = await subscriptionService.hasActiveSubscription();

    if (isPremium) return false;
    return totalCount >= _freeUserFileLimit;
  }

  /// Check if the user has reached their file limit
  Future<bool> hasReachedFileLimit(int totalFiles) async {
    try {
      final subscriptionService = SubscriptionService();
      final hasSubscription = await subscriptionService.hasActiveSubscription();

      // Premium users have unlimited files
      if (hasSubscription) {
        return false;
      }

      // Check free user limit
      return totalFiles >= _freeUserFileLimit;
    } catch (e) {
      logger.error('Error checking file limit: $e');
      return false; // Default to allowing files if there's an error
    }
  }

  /// Get the number of files remaining for free users
  Future<int> getRemainingFiles(int totalFiles) async {
    try {
      final subscriptionService = SubscriptionService();
      final hasSubscription = await subscriptionService.hasActiveSubscription();

      // Premium users have unlimited files
      if (hasSubscription) {
        return -1; // -1 indicates unlimited
      }

      // Calculate remaining for free users
      return _freeUserFileLimit - totalFiles;
    } catch (e) {
      logger.error('Error calculating remaining files: $e');
      return 0;
    }
  }

  /// Get the maximum allowed files for the current user
  Future<int> getMaxAllowedFiles() async {
    try {
      final subscriptionService = SubscriptionService();
      final hasSubscription = await subscriptionService.hasActiveSubscription();

      // Premium users have unlimited files
      if (hasSubscription) {
        return -1; // -1 indicates unlimited
      }

      // Free users have the limit
      return _freeUserFileLimit;
    } catch (e) {
      logger.error('Error getting max allowed files: $e');
      return _freeUserFileLimit;
    }
  }
}

/// Provider for the file limit service
final fileLimitServiceProvider = Provider<FileLimitService>((ref) {
  return FileLimitService();
});

/// Provider to get all documents
final allDocumentsProvider = Provider<List<Document>>((ref) {
  return ref.watch(documentsProvider);
});

/// Provider to get all barcodes
final allBarcodesProvider = Provider<List<BarcodeScan>>((ref) {
  return ref.watch(barcodeScanHistoryProvider);
});

/// Provider to get the total number of files
final totalFilesProvider = Provider<int>((ref) {
  final documents = ref.watch(allDocumentsProvider);
  final fileLimitService = ref.watch(fileLimitServiceProvider);

  return fileLimitService.getTotalFilesCount(documents);
});

/// Provider to track remaining files
final remainingFilesProvider = FutureProvider<int>((ref) async {
  final fileLimitService = ref.watch(fileLimitServiceProvider);
  final totalFiles = ref.watch(totalFilesProvider);

  return await fileLimitService.getRemainingFiles(totalFiles);
});

/// Provider to check if user has reached file limit
final hasReachedFileLimitProvider = FutureProvider<bool>((ref) async {
  final fileLimitService = ref.watch(fileLimitServiceProvider);
  final totalFiles = ref.watch(totalFilesProvider);

  return await fileLimitService.hasReachedFileLimit(totalFiles);
});

/// Provider for maximum allowed files based on subscription status
final maxAllowedFilesProvider = FutureProvider<int>((ref) async {
  final fileLimitService = ref.watch(fileLimitServiceProvider);
  return await fileLimitService.getMaxAllowedFiles();
});
