import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/services/subscription_service.dart';

/// Service to manage share limits for free users
class ShareLimitService {
  static const String _shareCountKey = 'document_share_count';
  static const int _freeUserShareLimit = 5;

  /// Get the number of times the user has shared documents
  Future<int> getShareCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_shareCountKey) ?? 0;
    } catch (e) {
      logger.error('Error getting share count: $e');
      return 0;
    }
  }

  /// Increment the share count by 1
  Future<void> incrementShareCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final int currentCount = prefs.getInt(_shareCountKey) ?? 0;
      await prefs.setInt(_shareCountKey, currentCount + 1);
      logger.info('Share count incremented to ${currentCount + 1}');
    } catch (e) {
      logger.error('Error incrementing share count: $e');
    }
  }

  /// Reset the share count to 0
  Future<void> resetShareCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_shareCountKey, 0);
      logger.info('Share count reset to 0');
    } catch (e) {
      logger.error('Error resetting share count: $e');
    }
  }

  /// Check if the user has reached their share limit
  Future<bool> hasReachedShareLimit() async {
    try {
      final subscriptionService = SubscriptionService();
      final hasSubscription =
          await subscriptionService.hasActiveTrialOrSubscription();

      // Premium users have unlimited shares
      if (hasSubscription) {
        return false;
      }

      // Check free user limit
      final shareCount = await getShareCount();
      return shareCount >= _freeUserShareLimit;
    } catch (e) {
      logger.error('Error checking share limit: $e');
      return false;
    }
  }

  /// Get the number of shares remaining for free users
  Future<int> getRemainingShares() async {
    try {
      final subscriptionService = SubscriptionService();
      final hasSubscription =
          await subscriptionService.hasActiveTrialOrSubscription();

      // Premium users have unlimited shares
      if (hasSubscription) {
        return -1; // -1 indicates unlimited
      }

      // Calculate remaining for free users
      final shareCount = await getShareCount();
      return _freeUserShareLimit - shareCount;
    } catch (e) {
      logger.error('Error calculating remaining shares: $e');
      return 0;
    }
  }
}

/// Provider for the share limit service
final shareLimitServiceProvider = Provider<ShareLimitService>((ref) {
  return ShareLimitService();
});

/// Provider to track remaining shares
final remainingSharesProvider = FutureProvider<int>((ref) async {
  final shareLimitService = ref.watch(shareLimitServiceProvider);
  return await shareLimitService.getRemainingShares();
});

/// Provider to check if user has reached share limit
final hasReachedShareLimitProvider = FutureProvider<bool>((ref) async {
  final shareLimitService = ref.watch(shareLimitServiceProvider);
  return await shareLimitService.hasReachedShareLimit();
});
