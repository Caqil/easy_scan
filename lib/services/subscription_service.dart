import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:scanpro/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for the subscription service
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

// Provider for the current subscription status
final subscriptionStatusProvider =
    StateNotifierProvider<SubscriptionStatusNotifier, SubscriptionStatus>(
        (ref) {
  return SubscriptionStatusNotifier();
});

// Subscription status notifier
class SubscriptionStatusNotifier extends StateNotifier<SubscriptionStatus> {
  SubscriptionStatusNotifier()
      : super(SubscriptionStatus(
          isActive: false,
          isTrialActive: false,
          expirationDate: null,
        ));

  void updateStatus(SubscriptionStatus newStatus) {
    state = newStatus;
  }
}

// Subscription status model
class SubscriptionStatus {
  final bool isActive;
  final bool isTrialActive;
  final DateTime? expirationDate;

  SubscriptionStatus({
    required this.isActive,
    required this.isTrialActive,
    this.expirationDate,
  });

  bool get hasFullAccess => isActive || isTrialActive;
}

class SubscriptionService {
  // RevenueCat API keys
  static const String _apiKeyIOS = 'appl_EHJrAaVNEkhAmFiQKziJNYRVULB';
  static const String _apiKeyAndroid = 'your_android_api_key';

  // Product IDs
  static const String _monthlyProductId = 'scanpro_premium_monthly';
  static const String _yearlyProductId = 'scanpro_premium_yearly';
  static const String _trialEntitlementId = 'premium_access';

  // Keys for tracking trial in SharedPreferences if needed
  static const String _trialStartedKey = 'trial_started';
  static const String _trialExpirationKey = 'trial_expiration';

  // Initialize the RevenueCat SDK
  Future<void> initialize() async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);

      PurchasesConfiguration configuration;
      if (Platform.isIOS) {
        configuration = PurchasesConfiguration(_apiKeyIOS);
      } else {
        configuration = PurchasesConfiguration(_apiKeyAndroid);
      }

      await Purchases.configure(configuration);

      // Setup a listener for purchasing events
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _updateSubscriptionStatus(customerInfo);
      });

      // Check current status
      await refreshSubscriptionStatus();

      logger.info('RevenueCat initialized successfully.');
    } catch (e) {
      logger.error('Error initializing RevenueCat: $e');
    }
  }

  // Check if trial or subscription is active
  Future<bool> hasActiveTrialOrSubscription() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return _checkAccessEntitlement(customerInfo);
    } catch (e) {
      logger.error('Error checking subscription: $e');
      // Fall back to local preference check
      return _checkLocalTrialStatus();
    }
  }

  // Start a free trial
  Future<void> startTrial() async {
    try {
      // First check if the user already had a trial
      if (await hasActiveTrialOrSubscription()) {
        // Trial or subscription already active
        return;
      }

      // Try to make a purchase for a free trial
      // In a real implementation, this would use Purchases.purchasePackage()
      // For simplicity in this example, we'll simulate it

      final offerings = await Purchases.getOfferings();
      if (offerings.current?.availablePackages.isNotEmpty == true) {
        // Find the package with a free trial
        final trialPackage = offerings.current?.availablePackages.firstWhere(
            (package) => package.storeProduct.introductoryPrice != null,
            orElse: () => offerings.current!.availablePackages.first);

        if (trialPackage != null) {
          try {
            // Attempt to purchase the package
            final purchaseResult =
                await Purchases.purchasePackage(trialPackage);

            // Update status based on purchase result
            _updateSubscriptionStatus(purchaseResult);
          } catch (e) {
            // Handle purchase errors
            logger.error('Error purchasing package: $e');
            throw Exception('Failed to start trial subscription');
          }
        } else {
          // No trial package available, fallback to local simulation
          await _simulateTrialLocally();
        }
      } else {
        // No offerings available, fallback to local simulation
        await _simulateTrialLocally();
      }
    } catch (e) {
      logger.error('Error starting trial: $e');
      // Fallback to local simulation if RevenueCat fails
      await _simulateTrialLocally();
    }
  }

  // Simulate a trial period locally (fallback if RevenueCat fails)
  Future<void> _simulateTrialLocally() async {
    final prefs = await SharedPreferences.getInstance();

    // Set trial start date to now
    final now = DateTime.now();
    await prefs.setString(_trialStartedKey, now.toIso8601String());

    // Set trial expiration date to 7 days from now
    final expiration = now.add(const Duration(days: 7));
    await prefs.setString(_trialExpirationKey, expiration.toIso8601String());

    logger.info('Local trial simulation started, expires: $expiration');

    // Update the subscription status
    final provider = ProviderContainer();
    provider.read(subscriptionStatusProvider.notifier).updateStatus(
          SubscriptionStatus(
            isActive: false,
            isTrialActive: true,
            expirationDate: expiration,
          ),
        );
  }

  // Check locally stored trial status (fallback)
  Future<bool> _checkLocalTrialStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trialExpirationString = prefs.getString(_trialExpirationKey);

      if (trialExpirationString != null) {
        final expiration = DateTime.parse(trialExpirationString);
        return DateTime.now().isBefore(expiration);
      }

      return false;
    } catch (e) {
      logger.error('Error checking local trial status: $e');
      return false;
    }
  }

  // Check if the user has the premium entitlement
  bool _checkAccessEntitlement(CustomerInfo customerInfo) {
    return customerInfo.entitlements.all[_trialEntitlementId]?.isActive ??
        false;
  }

  // Update the subscription status based on customer info
  void _updateSubscriptionStatus(CustomerInfo customerInfo) {
    final isActive = _checkAccessEntitlement(customerInfo);

    // Check if this is a trial or regular subscription
    bool isTrialActive = false;
    DateTime? expirationDate;

    if (isActive) {
      // Get subscription expiration date if available
      final activeSubscription =
          customerInfo.entitlements.all[_trialEntitlementId];
      if (activeSubscription != null) {
        expirationDate = DateTime.tryParse(activeSubscription.expirationDate!);

        // Check if this is a trial period
        isTrialActive = activeSubscription.periodType == PeriodType.trial;
      }
    }

    // Update the subscription status provider
    final provider = ProviderContainer();
    provider.read(subscriptionStatusProvider.notifier).updateStatus(
          SubscriptionStatus(
            isActive: isActive,
            isTrialActive: isTrialActive,
            expirationDate: expirationDate,
          ),
        );

    logger.info(
        'Subscription status updated: active=$isActive, trial=$isTrialActive');
  }

  // Refresh subscription status
  Future<void> refreshSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _updateSubscriptionStatus(customerInfo);
    } catch (e) {
      logger.error('Error refreshing subscription status: $e');
    }
  }

  // Get available subscription packages
  Future<List<Package>> getSubscriptionPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? [];
    } catch (e) {
      logger.error('Error getting subscription packages: $e');
      return [];
    }
  }

  // Purchase a subscription package
  Future<void> purchasePackage(Package package) async {
    try {
      final purchaseResult = await Purchases.purchasePackage(package);
      _updateSubscriptionStatus(purchaseResult);
    } catch (e) {
      logger.error('Error purchasing subscription: $e');
      throw Exception('Failed to purchase subscription');
    }
  }

  // Restore purchases
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _updateSubscriptionStatus(customerInfo);
      return _checkAccessEntitlement(customerInfo);
    } catch (e) {
      logger.error('Error restoring purchases: $e');
      return false;
    }
  }
}
