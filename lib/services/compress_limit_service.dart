import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanpro/config/helper.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/services/subscription_service.dart';


/// Service to manage compression limits for free users
class CompressionLimitService {
  /// Check if a specific compression level is available for the user
  Future<bool> isCompressionLevelAvailable(CompressionLevel level) async {
    try {
      // Low compression is available to all users
      if (level == CompressionLevel.low) {
        return true;
      }

      // For all other levels, check if user has premium
      final subscriptionService = SubscriptionService();
      return await subscriptionService.hasActiveSubscription();
    } catch (e) {
      logger.error('Error checking compression level availability: $e');
      return level ==
          CompressionLevel.low; // Fallback to allow only low level on error
    }
  }

  /// Get all available compression levels for the current user
  Future<List<CompressionLevel>> getAvailableCompressionLevels() async {
    try {
      final subscriptionService = SubscriptionService();
      final isPremium = await subscriptionService.hasActiveSubscription();

      if (isPremium) {
        // Premium users have access to all compression levels
        return CompressionLevel.values;
      } else {
        // Free users only have access to low compression
        return [CompressionLevel.low];
      }
    } catch (e) {
      logger.error('Error getting available compression levels: $e');
      return [CompressionLevel.low]; // Default to low compression only
    }
  }

  /// Check if the user needs to upgrade to access a specific compression level
  Future<bool> needsUpgradeForCompressionLevel(CompressionLevel level) async {
    // If it's low compression, no upgrade needed
    if (level == CompressionLevel.low) {
      return false;
    }

    // For other levels, check subscription status
    try {
      final subscriptionService = SubscriptionService();
      final isPremium = await subscriptionService.hasActiveSubscription();
      return !isPremium;
    } catch (e) {
      logger.error('Error checking if upgrade needed: $e');
      return true; // Default to requiring upgrade
    }
  }
}

/// Provider for the compression limit service
final compressionLimitServiceProvider =
    Provider<CompressionLimitService>((ref) {
  return CompressionLimitService();
});

/// Provider to get all available compression levels for current user
final availableCompressionLevelsProvider =
    FutureProvider<List<CompressionLevel>>((ref) async {
  final compressionLimitService = ref.watch(compressionLimitServiceProvider);
  return await compressionLimitService.getAvailableCompressionLevels();
});

/// Provider to check if a specific compression level is available
final isCompressionLevelAvailableProvider =
    FutureProvider.family<bool, CompressionLevel>((ref, level) async {
  final compressionLimitService = ref.watch(compressionLimitServiceProvider);
  return await compressionLimitService.isCompressionLevelAvailable(level);
});

/// Provider to check if upgrade is needed for a compression level
final needsUpgradeForCompressionLevelProvider =
    FutureProvider.family<bool, CompressionLevel>((ref, level) async {
  final compressionLimitService = ref.watch(compressionLimitServiceProvider);
  return await compressionLimitService.needsUpgradeForCompressionLevel(level);
});
