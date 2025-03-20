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

// Provider to track loading state of subscription operations
final subscriptionLoadingProvider = StateProvider<bool>((ref) => false);

// Provider to track any subscription error
final subscriptionErrorProvider = StateProvider<String?>((ref) => null);

// Subscription status notifier
class SubscriptionStatusNotifier extends StateNotifier<SubscriptionStatus> {
  SubscriptionStatusNotifier()
      : super(SubscriptionStatus(
          isActive: false,
          isTrialActive: false,
          expirationDate: null,
          productIdentifier: null,
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
  final String? productIdentifier;
  final Map<String, dynamic>? entitlementInfo;

  SubscriptionStatus({
    required this.isActive,
    required this.isTrialActive,
    this.expirationDate,
    this.productIdentifier,
    this.entitlementInfo,
  });

  bool get hasFullAccess => isActive || isTrialActive;

  SubscriptionStatus copyWith({
    bool? isActive,
    bool? isTrialActive,
    DateTime? expirationDate,
    String? productIdentifier,
    Map<String, dynamic>? entitlementInfo,
  }) {
    return SubscriptionStatus(
      isActive: isActive ?? this.isActive,
      isTrialActive: isTrialActive ?? this.isTrialActive,
      expirationDate: expirationDate ?? this.expirationDate,
      productIdentifier: productIdentifier ?? this.productIdentifier,
      entitlementInfo: entitlementInfo ?? this.entitlementInfo,
    );
  }

  @override
  String toString() {
    return 'SubscriptionStatus(isActive: $isActive, isTrialActive: $isTrialActive, productIdentifier: $productIdentifier, expirationDate: $expirationDate)';
  }
}

// Subscription service class
class SubscriptionService {
  // RevenueCat API keys
  static const String _apiKeyIOS = 'appl_EHJrAaVNEkhAmFiQKziJNYRVULB';
  static const String _apiKeyAndroid = 'goog_UAPeVjCHEOETJqaQXHHqZKaxEJO';
  static const String _premiumEntitlementId = 'premium_access';

  // Initialize the RevenueCat SDK
  Future<void> initialize() async {
    try {
      logger.info('Initializing RevenueCat SDK...');

      // Set log level based on environment (debug or production)
      await Purchases.setLogLevel(LogLevel.debug);

      // Configure RevenueCat with appropriate API key
      PurchasesConfiguration configuration;
      if (Platform.isIOS || Platform.isMacOS) {
        configuration = PurchasesConfiguration(_apiKeyIOS);
      } else {
        configuration = PurchasesConfiguration(_apiKeyAndroid);
      }

      // Configure the SDK
      await Purchases.configure(configuration);

      // Setup a listener for purchasing events
      Purchases.addCustomerInfoUpdateListener((customerInfo) async {
        logger.info('Customer info updated: ${customerInfo.originalAppUserId}');
        await _updateSubscriptionStatus(customerInfo);
      });

      // Refresh subscription status at initialization
      await refreshSubscriptionStatus();

      logger.info('RevenueCat initialized successfully!');
    } catch (e) {
      logger.error('Error initializing RevenueCat: $e');
      // Even on error, we still consider the service initialized
      // but we'll have default statuses until we can recover
    }
  }

  // Get customer info from RevenueCat
  Future<CustomerInfo> _getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      logger.error('Error retrieving customer info: $e');
      rethrow;
    }
  }

  // Check if user has an active subscription or trial
  Future<bool> hasActiveTrialOrSubscription() async {
    try {
      final customerInfo = await _getCustomerInfo();
      return _checkEntitlementActive(customerInfo);
    } catch (e) {
      logger.error('Error checking subscription status: $e');
      return false;
    }
  }

  // Check specific entitlement is active
  bool _checkEntitlementActive(CustomerInfo customerInfo) {
    return customerInfo.entitlements.all[_premiumEntitlementId]?.isActive ??
        false;
  }

  // Start a free trial by purchasing the appropriate package
  Future<void> startTrial() async {
    final provider = ProviderContainer();
    provider.read(subscriptionLoadingProvider.notifier).state = true;
    provider.read(subscriptionErrorProvider.notifier).state = null;

    try {
      // Get product offerings from RevenueCat
      logger.info('Fetching product offerings from RevenueCat...');
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null) {
        logger.error('No offerings available from RevenueCat');
        throw Exception(
            'No subscription offerings available at this time. Please try again later.');
      }

      logger.info(
          'Available packages: ${offerings.current!.availablePackages.length}');

      // Find a package with a free trial
      final trialPackage = offerings.current!.availablePackages.firstWhere(
          (package) => package.storeProduct.introductoryPrice != null,
          orElse: () => offerings.current!.availablePackages.first);

      if (trialPackage == null) {
        logger.error('No trial package found');
        throw Exception(
            'No trial package found. Please try a regular subscription.');
      }

      logger.info('Selected trial package: ${trialPackage.identifier}');

      // Attempt to purchase the trial package
      final purchaseResult = await Purchases.purchasePackage(trialPackage);

      logger.info(
          'Purchase completed successfully: ${purchaseResult.originalAppUserId}');

      // Update subscription status with the purchase result
      await _updateSubscriptionStatus(purchaseResult);
    } catch (e) {
      logger.error('Error starting trial: $e');
      final provider = ProviderContainer();
      provider.read(subscriptionErrorProvider.notifier).state = e.toString();
      rethrow;
    } finally {
      final provider = ProviderContainer();
      provider.read(subscriptionLoadingProvider.notifier).state = false;
    }
  }

  // Update subscription status based on CustomerInfo from RevenueCat
  Future<void> _updateSubscriptionStatus(CustomerInfo customerInfo) async {
    try {
      final isActive = _checkEntitlementActive(customerInfo);

      // Default values for subscription status
      bool isTrialActive = false;
      DateTime? expirationDate;
      String? productIdentifier;
      Map<String, dynamic>? entitlementInfo;

      if (isActive) {
        final activeEntitlement =
            customerInfo.entitlements.all[_premiumEntitlementId];

        if (activeEntitlement != null) {
          // Get product identifier
          productIdentifier = activeEntitlement.productIdentifier;

          // Get expiration date if available
          if (activeEntitlement.expirationDate != null &&
              activeEntitlement.expirationDate!.isNotEmpty) {
            expirationDate =
                DateTime.tryParse(activeEntitlement.expirationDate!);
          }

          // Check if this is a trial period
          isTrialActive = activeEntitlement.periodType == PeriodType.trial;

          // Store full entitlement info for reference
          entitlementInfo = {
            'identifier': activeEntitlement.identifier,
            'isActive': activeEntitlement.isActive,
            'willRenew': activeEntitlement.willRenew,
            'periodType': activeEntitlement.periodType.toString(),
            'latestPurchaseDate': activeEntitlement.latestPurchaseDate,
            'originalPurchaseDate': activeEntitlement.originalPurchaseDate,
            'expirationDate': activeEntitlement.expirationDate,
            'store': activeEntitlement.store.toString(),
            'productIdentifier': activeEntitlement.productIdentifier,
            'isSandbox': activeEntitlement.isSandbox,
          };
        }
      }

      // Create the new status
      final newStatus = SubscriptionStatus(
        isActive: isActive,
        isTrialActive: isTrialActive,
        expirationDate: expirationDate,
        productIdentifier: productIdentifier,
        entitlementInfo: entitlementInfo,
      );

      logger.info('Subscription status updated: $newStatus');

      // Update the provider
      final provider = ProviderContainer();
      provider
          .read(subscriptionStatusProvider.notifier)
          .updateStatus(newStatus);

      // Save key subscription information to SharedPreferences for offline reference
      _saveSubscriptionToPrefs(newStatus);
    } catch (e) {
      logger.error('Error updating subscription status: $e');
      // On error, we don't update the status
    }
  }

  // Save basic subscription info to SharedPreferences
  Future<void> _saveSubscriptionToPrefs(SubscriptionStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('subscription_active', status.isActive);
      await prefs.setBool('trial_active', status.isTrialActive);

      if (status.expirationDate != null) {
        await prefs.setString('subscription_expiration',
            status.expirationDate!.toIso8601String());
      } else {
        await prefs.remove('subscription_expiration');
      }

      if (status.productIdentifier != null) {
        await prefs.setString('product_identifier', status.productIdentifier!);
      } else {
        await prefs.remove('product_identifier');
      }
    } catch (e) {
      logger.error('Error saving subscription to prefs: $e');
    }
  }

  // Load basic subscription info from SharedPreferences
  Future<SubscriptionStatus> _loadSubscriptionFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isActive = prefs.getBool('subscription_active') ?? false;
      final isTrialActive = prefs.getBool('trial_active') ?? false;

      DateTime? expirationDate;
      final expirationStr = prefs.getString('subscription_expiration');
      if (expirationStr != null) {
        expirationDate = DateTime.tryParse(expirationStr);
      }

      final productIdentifier = prefs.getString('product_identifier');

      return SubscriptionStatus(
        isActive: isActive,
        isTrialActive: isTrialActive,
        expirationDate: expirationDate,
        productIdentifier: productIdentifier,
      );
    } catch (e) {
      logger.error('Error loading subscription from prefs: $e');
      return SubscriptionStatus(
        isActive: false,
        isTrialActive: false,
        expirationDate: null,
        productIdentifier: null,
      );
    }
  }

  // Refresh subscription status from RevenueCat
  Future<void> refreshSubscriptionStatus() async {
    try {
      // First check if we have cached info
      final cachedStatus = await _loadSubscriptionFromPrefs();

      // Update the provider with cached data first for immediate UI response
      if (cachedStatus.isActive || cachedStatus.isTrialActive) {
        final provider = ProviderContainer();
        provider
            .read(subscriptionStatusProvider.notifier)
            .updateStatus(cachedStatus);
      }

      // Then get fresh data from RevenueCat
      final customerInfo = await _getCustomerInfo();
      await _updateSubscriptionStatus(customerInfo);
    } catch (e) {
      logger.error('Error refreshing subscription status: $e');
      // If we can't refresh from network, we still have the cached status
    }
  }

  Future<List<Package>> getSubscriptionPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? [];
      // Logging for debugging
      if (packages.isNotEmpty) {
        for (final package in packages) {
          logger.info(
              'Package: ${package.identifier}, Product: ${package.storeProduct.identifier}');
        }
      } else {
        logger.warning('No subscription packages available');
      }
      return packages;
    } catch (e) {
      logger.error('Error getting subscription packages: $e');
      return [];
    }
  }

  // Purchase a specific package
  Future<void> purchasePackage(Package package) async {
    final provider = ProviderContainer();
    provider.read(subscriptionLoadingProvider.notifier).state = true;
    provider.read(subscriptionErrorProvider.notifier).state = null;

    try {
      logger.info('Purchasing package: ${package.identifier}');

      final purchaseResult = await Purchases.purchasePackage(package);

      logger.info('Purchase completed successfully');

      // Update subscription status
      await _updateSubscriptionStatus(purchaseResult);
    } catch (e) {
      logger.error('Error purchasing package: $e');

      // Set error state
      provider.read(subscriptionErrorProvider.notifier).state = e.toString();

      // Check if the error was due to user cancellation
      if (e is PurchasesError) {
        if (e.code == PurchasesErrorCode.purchaseCancelledError) {
          logger.info('Purchase was cancelled by user');
          provider.read(subscriptionErrorProvider.notifier).state =
              'Purchase cancelled';
        }
      }

      rethrow;
    } finally {
      provider.read(subscriptionLoadingProvider.notifier).state = false;
    }
  }

  // Restore previous purchases
  Future<bool> restorePurchases() async {
    final provider = ProviderContainer();
    provider.read(subscriptionLoadingProvider.notifier).state = true;
    provider.read(subscriptionErrorProvider.notifier).state = null;

    try {
      logger.info('Restoring purchases...');

      final customerInfo = await Purchases.restorePurchases();

      logger.info('Purchases restored successfully');

      // Update subscription status
      await _updateSubscriptionStatus(customerInfo);

      return _checkEntitlementActive(customerInfo);
    } catch (e) {
      logger.error('Error restoring purchases: $e');
      provider.read(subscriptionErrorProvider.notifier).state = e.toString();
      return false;
    } finally {
      provider.read(subscriptionLoadingProvider.notifier).state = false;
    }
  }

  Future<Map<String, List<Package>>> getSubscriptionOptions() async {
    final Map<String, List<Package>> result = {
      'monthly': [],
      'yearly': [],
      'other': [],
    };
    try {
      final packages = await getSubscriptionPackages();
      for (final package in packages) {
        if (package.identifier.contains('monthly') ||
            package.storeProduct.identifier.contains('monthly')) {
          result['monthly']!.add(package);
        } else if (package.identifier.contains('yearly') ||
            package.storeProduct.identifier.contains('yearly')) {
          result['yearly']!.add(package);
        } else {
          result['other']!.add(package);
        }
      }
    } catch (e) {
      logger.error('Error getting subscription options: $e');
    }
    return result;
  }

  // Check if a specific entitlement feature is available
  Future<bool> checkFeatureAccess(String featureKey) async {
    try {
      final status = await hasActiveTrialOrSubscription();
      return status;
    } catch (e) {
      logger.error('Error checking feature access: $e');
      return false;
    }
  }
}
