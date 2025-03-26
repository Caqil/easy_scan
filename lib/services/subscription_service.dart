import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:scanpro/main.dart';

// Product IDs - Keep the same IDs for consistent tracking
const String kWeeklyProductId = 'scanpro_premium_weekly';
const String kMonthlyProductId = 'scanpro_premium_monthly';
const String kYearlyProductId = 'scanpro_premium_yearly';

// Entitlement IDs - These should match what you configure in RevenueCat dashboard
const String kPremiumEntitlementId = 'premium_access';
final isPremiumProvider = FutureProvider<bool>((ref) async {
  final subscriptionService = ref.watch(subscriptionServiceProvider);
  return await subscriptionService.hasActiveSubscription();
});
// Provider for the subscription service
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  logger.info('Creating SubscriptionService provider');
  return SubscriptionService();
});

// Provider for the current subscription status
final subscriptionStatusProvider =
    StateNotifierProvider<SubscriptionStatusNotifier, SubscriptionStatus>(
        (ref) {
  logger.info('Creating SubscriptionStatusNotifier provider');
  return SubscriptionStatusNotifier();
});

// Provider to track loading state of subscription operations
final subscriptionLoadingProvider = StateProvider<bool>((ref) {
  logger.info('Creating subscriptionLoadingProvider');
  return false;
});

// Provider to track any subscription error
final subscriptionErrorProvider = StateProvider<String?>((ref) {
  logger.info('Creating subscriptionErrorProvider');
  return null;
});

// Subscription status notifier
class SubscriptionStatusNotifier extends StateNotifier<SubscriptionStatus> {
  SubscriptionStatusNotifier()
      : super(SubscriptionStatus(
          isActive: false,
          isTrialActive: false,
          expirationDate: null,
          productId: null,
        )) {
    logger.info('SubscriptionStatusNotifier initialized');
  }

  void updateStatus(SubscriptionStatus newStatus) {
    logger.info('Updating subscription status: $newStatus');
    state = newStatus;
  }
}

// Subscription status model
class SubscriptionStatus {
  final bool isActive;
  final bool isTrialActive;
  final DateTime? expirationDate;
  final String? productId;

  SubscriptionStatus({
    required this.isActive,
    required this.isTrialActive,
    this.expirationDate,
    this.productId,
  });

  bool get hasFullAccess => isActive || isTrialActive;

  SubscriptionStatus copyWith({
    bool? isActive,
    bool? isTrialActive,
    DateTime? expirationDate,
    String? productId,
  }) {
    logger.info('Creating copy of SubscriptionStatus');
    return SubscriptionStatus(
      isActive: isActive ?? this.isActive,
      isTrialActive: isTrialActive ?? this.isTrialActive,
      expirationDate: expirationDate ?? this.expirationDate,
      productId: productId ?? this.productId,
    );
  }

  @override
  String toString() {
    return 'SubscriptionStatus(isActive: $isActive, isTrialActive: $isTrialActive, productId: $productId, expirationDate: $expirationDate)';
  }
}

class SubscriptionService {
  // Configuration - Replace this with your actual RevenueCat API key
  static final String _apiKey = Platform.isIOS
      ? 'appl_EHJrAaVNEkhAmFiQKziJNYRVULB'
      : 'goog_oqxxNnycSOdmcwEIUtkHvKmkkTn';
  static const bool _debugLogsEnabled = true;

  // Initialize the service
  Future<void> initialize() async {
    logger.info('Starting SubscriptionService initialization');

    try {
      await Purchases.setLogLevel(
          _debugLogsEnabled ? LogLevel.debug : LogLevel.info);

      await Purchases.configure(PurchasesConfiguration(_apiKey));

      logger.info('RevenueCat SDK configured successfully');

      // Refresh subscription status after initialization
      await refreshSubscriptionStatus();

      logger.info('SubscriptionService initialized successfully');
    } catch (e) {
      logger.error('Error initializing RevenueCat: $e');
    }
  }

  Future<List<Package>> getSubscriptionPackages() async {
    logger.info('Getting subscription packages');

    try {
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null) {
        logger.warning('No current offering available from RevenueCat');
        return [];
      }

      final packages = offerings.current!.availablePackages;

      // Important: Log each package found to help with debugging
      logger.info('Found ${packages.length} packages from RevenueCat:');
      for (final package in packages) {
        logger.info(
            'Package: ${package.identifier}, Type: ${package.packageType}, Price: ${package.storeProduct.priceString}');
      }

      // Make sure to return ALL packages, not just filtering to the default
      return packages;
    } catch (e) {
      logger.error('Error loading packages from RevenueCat: $e');
      return [];
    }
  }

  // Get categorized subscription packages
  Future<Map<String, List<Package>>> getSubscriptionOptions() async {
    logger.info('Getting subscription options');

    final Map<String, List<Package>> result = {
      'weekly': [],
      'monthly': [],
      'yearly': [],
    };

    try {
      final packages = await getSubscriptionPackages();

      for (final package in packages) {
        logger.debug('Categorizing package: ${package.identifier}');

        // Categorize based on package identifier or duration
        if (package.identifier.contains('weekly') ||
            package.packageType == PackageType.weekly) {
          result['weekly']!.add(package);
        } else if (package.identifier.contains('monthly') ||
            package.packageType == PackageType.monthly) {
          result['monthly']!.add(package);
        } else if (package.identifier.contains('yearly') ||
            package.packageType == PackageType.annual) {
          result['yearly']!.add(package);
        }
      }

      logger.info('Returning subscription options: ${result.keys}');
      return result;
    } catch (e) {
      logger.error('Error getting subscription options: $e');
      return result;
    }
  }

  // Purchase a package
  Future<bool> purchasePackage(Package package) async {
    logger.info('Starting purchase for package: ${package.identifier}');
    final provider = ProviderContainer();
    provider.read(subscriptionLoadingProvider.notifier).state = true;
    provider.read(subscriptionErrorProvider.notifier).state = null;

    try {
      // Make the purchase
      final purchaseResult = await Purchases.purchasePackage(package);

      logger.info('Purchase completed: ${purchaseResult.entitlements.all}');

      // Check if the user now has access to the premium entitlement
      final isPremium =
          purchaseResult.entitlements.active.containsKey(kPremiumEntitlementId);

      await refreshSubscriptionStatus();

      return isPremium;
    } catch (e) {
      if (e is PurchasesErrorCode) {
        // Handle RevenueCat specific errors
        if (e == PurchasesErrorCode.purchaseCancelledError) {
          logger.info('User cancelled purchase');
        } else if (e == PurchasesErrorCode.paymentPendingError) {
          logger.info('Payment is pending');
        } else {
          logger.error('RevenueCat purchase error: $e');
        }
      } else {
        logger.error('Error purchasing package: $e');
      }

      provider.read(subscriptionErrorProvider.notifier).state = e.toString();
      return false;
    } finally {
      provider.read(subscriptionLoadingProvider.notifier).state = false;
    }
  }

  // Start a free trial
  Future<bool> startTrial() async {
    logger.info('Starting free trial');
    final provider = ProviderContainer();
    provider.read(subscriptionLoadingProvider.notifier).state = true;

    try {
      // Get packages and find one with a trial
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null) {
        throw Exception('No offerings available');
      }

      // Look for a package with a trial
      Package? trialPackage;
      for (var package in offerings.current!.availablePackages) {
        if (package.storeProduct.introductoryPrice != null) {
          trialPackage = package;
          break;
        }
      }

      trialPackage ??= offerings.current!.availablePackages.firstWhere(
          (p) =>
              p.identifier.contains('yearly') ||
              p.packageType == PackageType.annual,
          orElse: () => offerings.current!.availablePackages.first);

      // Make the purchase for the trial
      final purchaseResult = await Purchases.purchasePackage(trialPackage);

      // Check if the user now has access to the premium entitlement
      final isPremium =
          purchaseResult.entitlements.active.containsKey(kPremiumEntitlementId);

      await refreshSubscriptionStatus();

      return isPremium;
    } catch (e) {
      logger.error('Error starting trial: $e');
      return false;
    } finally {
      provider.read(subscriptionLoadingProvider.notifier).state = false;
    }
  }

  // Restore purchases
  Future<bool> restorePurchases() async {
    logger.info('Starting purchase restoration');
    final provider = ProviderContainer();
    provider.read(subscriptionLoadingProvider.notifier).state = true;

    try {
      final customerInfo = await Purchases.restorePurchases();

      // Check if the user has premium access
      final isPremium =
          customerInfo.entitlements.active.containsKey(kPremiumEntitlementId);

      await refreshSubscriptionStatus();

      return isPremium;
    } catch (e) {
      logger.error('Error restoring purchases: $e');
      return false;
    } finally {
      provider.read(subscriptionLoadingProvider.notifier).state = false;
    }
  }

  // Check if user has an active subscription
  Future<bool> hasActiveSubscription() async {
    logger.info('Checking active subscription');

    try {
      final customerInfo = await Purchases.getCustomerInfo();

      // Check if the user has premium access
      final isPremium =
          customerInfo.entitlements.active.containsKey(kPremiumEntitlementId);
      logger.info(customerInfo.originalAppUserId);
      return isPremium;
    } catch (e) {
      logger.error('Error checking for active subscription: $e');
      return false;
    }
  }

  // Check if user has trial or subscription
  Future<bool> hasActiveTrialOrSubscription() async {
    logger.info('Checking active trial or subscription');

    try {
      return await hasActiveSubscription();
    } catch (e) {
      logger.error('Error checking for active trial or subscription: $e');
      return false;
    }
  }

  // Refresh subscription status
  Future<void> refreshSubscriptionStatus() async {
    logger.info('Refreshing subscription status');

    try {
      final customerInfo = await Purchases.getCustomerInfo();

      // Check if user has premium entitlement
      final entitlements = customerInfo.entitlements.active;
      final isPremium = entitlements.containsKey(kPremiumEntitlementId);

      // Get product ID from purchases if available
      String? productId;
      DateTime? expirationDate;

      // Get the active subscription info if available
      if (isPremium && entitlements[kPremiumEntitlementId] != null) {
        final entitlement = entitlements[kPremiumEntitlementId]!;
        productId = entitlement.productIdentifier;

        // Get expiration date if available
        if (entitlement.expirationDate != null) {
          expirationDate = DateTime.parse(entitlement.expirationDate!);
        }
      }

      // Check if user is in trial period
      bool isTrialActive = false;
      if (isPremium &&
          customerInfo.entitlements.active[kPremiumEntitlementId]?.periodType ==
              PeriodType.trial) {
        isTrialActive = true;
      }

      // Update the status
      final status = SubscriptionStatus(
        isActive: isPremium && !isTrialActive,
        isTrialActive: isTrialActive,
        productId: productId,
        expirationDate: expirationDate,
      );

      final provider = ProviderContainer();
      provider.read(subscriptionStatusProvider.notifier).updateStatus(status);

      logger.info('Subscription status refreshed: $status');
    } catch (e) {
      logger.error('Error refreshing subscription status: $e');
    }
  }
}
