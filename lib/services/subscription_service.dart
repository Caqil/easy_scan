import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/utils/constants.dart';

// Product IDs
const String kMonthlyProductId = 'scanpro_premium_monthly';
const String kYearlyProductId = 'scanpro_premium_yearly';

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
          productId: null,
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
  static const String _kTrialStartTimeKey = 'trial_start_time';
  static const String _kTrialDurationDays = 'trial_duration_days';
  static const String _kSubscriptionActiveKey = 'subscription_active';
  static const String _kSubscriptionProductIdKey = 'subscription_product_id';
  static const String _kSubscriptionExpirationKey = 'subscription_expiration';
  static const int _trialDurationDays = 7; // 7-day free trial

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];

  // Initialize the service
  Future<void> initialize() async {
    logger.info('Initializing in_app_purchase...');

    final isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      logger.error('In-app purchases not available');
      return;
    }

    // Set up purchase stream listener
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        logger.error('Error in purchase stream: $error');
      },
    );

    // Load products
    await _loadProducts();

    // Check current subscription status
    await refreshSubscriptionStatus();

    logger.info('In-app purchase initialized successfully');
  }

  void dispose() {
    _subscription?.cancel();
  }

  // Load available products
  Future<void> _loadProducts() async {
    try {
      final Set<String> productIds = {kMonthlyProductId, kYearlyProductId};
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        logger.warning('Some product IDs not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      logger.info('Loaded ${_products.length} product(s)');

      // Debug log of loaded products
      for (final product in _products) {
        logger.info('Product: ${product.id}, Price: ${product.price}');
      }
    } catch (e) {
      logger.error('Error loading products: $e');
    }
  }

  // Get all available subscription packages
  Future<List<ProductDetails>> getSubscriptionPackages() async {
    if (_products.isEmpty) {
      await _loadProducts();
    }
    return _products;
  }

  // Get categorized subscription packages
  Future<Map<String, List<ProductDetails>>> getSubscriptionOptions() async {
    final Map<String, List<ProductDetails>> result = {
      'monthly': [],
      'yearly': [],
      'other': [],
    };

    final products = await getSubscriptionPackages();

    for (final product in products) {
      if (product.id == kMonthlyProductId) {
        result['monthly']!.add(product);
      } else if (product.id == kYearlyProductId) {
        result['yearly']!.add(product);
      } else {
        result['other']!.add(product);
      }
    }

    return result;
  }

  // Purchase a product
  Future<bool> purchasePackage(ProductDetails product) async {
    final provider = ProviderContainer();
    provider.read(subscriptionLoadingProvider.notifier).state = true;
    provider.read(subscriptionErrorProvider.notifier).state = null;

    try {
      logger.info('Purchasing package: ${product.id}');

      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: null,
      );

      bool success = false;

      // Start the purchase flow
      try {
        if (Platform.isIOS) {
          success = await _inAppPurchase.buyNonConsumable(
              purchaseParam: purchaseParam);
        } else {
          success =
              await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
        }
      } catch (purchaseError) {
        logger.error('Purchase API error: $purchaseError');
        // Try alternative purchase method if the first one fails
        try {
          if (Platform.isIOS) {
            success = await _inAppPurchase.buyConsumable(
                purchaseParam: purchaseParam);
          } else {
            success = await _inAppPurchase.buyNonConsumable(
                purchaseParam: purchaseParam);
          }
        } catch (secondError) {
          logger.error('Alternative purchase method also failed: $secondError');
          throw secondError;
        }
      }

      // Result will be handled in the purchase update listener
      return success;
    } catch (e) {
      logger.error('Error purchasing package: $e');
      provider.read(subscriptionErrorProvider.notifier).state = e.toString();
      return false;
    } finally {
      provider.read(subscriptionLoadingProvider.notifier).state = false;
    }
  }

  // Start a free trial
  Future<bool> startTrial() async {
    final provider = ProviderContainer();
    provider.read(subscriptionLoadingProvider.notifier).state = true;

    try {
      // Find a yearly subscription to start the trial
      ProductDetails? yearlyProduct;
      for (final product in _products) {
        if (product.id == kYearlyProductId) {
          yearlyProduct = product;
          break;
        }
      }

      if (yearlyProduct == null) {
        // If no yearly, try monthly
        for (final product in _products) {
          if (product.id == kMonthlyProductId) {
            yearlyProduct = product;
            break;
          }
        }
      }

      if (yearlyProduct == null) {
        throw Exception('No suitable subscription product found for trial');
      }

      // Save trial start time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _kTrialStartTimeKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_kTrialDurationDays, _trialDurationDays);
      await prefs.setBool(_kSubscriptionActiveKey, false);
      await prefs.setBool('trial_active', true);

      // Update status
      final status = SubscriptionStatus(
        isActive: false,
        isTrialActive: true,
        expirationDate: DateTime.now().add(Duration(days: _trialDurationDays)),
        productId: yearlyProduct.id,
      );

      final provider = ProviderContainer();
      provider.read(subscriptionStatusProvider.notifier).updateStatus(status);

      return true;
    } catch (e) {
      logger.error('Error starting trial: $e');
      return false;
    } finally {
      provider.read(subscriptionLoadingProvider.notifier).state = false;
    }
  }

  // Restore purchases
  Future<bool> restorePurchases() async {
    final provider = ProviderContainer();
    provider.read(subscriptionLoadingProvider.notifier).state = true;

    try {
      logger.info('Restoring purchases...');
      await _inAppPurchase.restorePurchases();

      // Result will be handled in the purchase update listener
      // We'll wait a moment for the restore to complete
      await Future.delayed(const Duration(seconds: 2));

      // Check if we have an active subscription after restore
      final status = await _checkSubscriptionStatus();
      return status.isActive;
    } catch (e) {
      logger.error('Error restoring purchases: $e');
      return false;
    } finally {
      provider.read(subscriptionLoadingProvider.notifier).state = false;
    }
  }

  // Check if user has an active subscription
  Future<bool> hasActiveSubscription() async {
    final status = await _checkSubscriptionStatus();
    return status.isActive;
  }

  // Check if user has trial or subscription
  Future<bool> hasActiveTrialOrSubscription() async {
    final status = await _checkSubscriptionStatus();
    return status.isActive || status.isTrialActive;
  }

  // Refresh subscription status
  Future<void> refreshSubscriptionStatus() async {
    final status = await _checkSubscriptionStatus();

    final provider = ProviderContainer();
    provider.read(subscriptionStatusProvider.notifier).updateStatus(status);
  }

  // Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      logger.info(
          'Purchase update: ${purchaseDetails.status} for ${purchaseDetails.productID}');

      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Show pending UI
        logger.info('Purchase pending for ${purchaseDetails.productID}');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // Handle error
          logger.error('Purchase error: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // Verify purchase
          await _verifyPurchase(purchaseDetails);
        }

        // Complete the purchase
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }

    // Refresh subscription status after handling purchases
    await refreshSubscriptionStatus();
  }

  // Verify purchase and update subscription status
  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // In a real app, you might want to verify the receipt with your server
    // For now, we'll just accept the purchase

    final prefs = await SharedPreferences.getInstance();

    // Save subscription data
    await prefs.setBool(_kSubscriptionActiveKey, true);
    await prefs.setBool('trial_active', false);
    await prefs.setString(
        _kSubscriptionProductIdKey, purchaseDetails.productID);

    // Set an expiration date (normally this would come from the receipt)
    // We'll just set it to 1 month for monthly, 1 year for yearly
    DateTime expirationDate;
    if (purchaseDetails.productID == kMonthlyProductId) {
      expirationDate = DateTime.now().add(const Duration(days: 30));
    } else {
      expirationDate = DateTime.now().add(const Duration(days: 365));
    }

    await prefs.setString(
        _kSubscriptionExpirationKey, expirationDate.toIso8601String());

    logger.info(
        'Subscription verified and active until ${expirationDate.toIso8601String()}');
  }

  // Check current subscription status
  Future<SubscriptionStatus> _checkSubscriptionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check active subscription
      final isActive = prefs.getBool(_kSubscriptionActiveKey) ?? false;

      // If subscription is active, get its details
      if (isActive) {
        final productId = prefs.getString(_kSubscriptionProductIdKey);

        DateTime? expirationDate;
        final expirationString = prefs.getString(_kSubscriptionExpirationKey);
        if (expirationString != null) {
          expirationDate = DateTime.tryParse(expirationString);

          // Check if subscription has expired
          if (expirationDate != null &&
              expirationDate.isBefore(DateTime.now())) {
            // Subscription has expired
            await prefs.setBool(_kSubscriptionActiveKey, false);
            return SubscriptionStatus(
              isActive: false,
              isTrialActive: false,
              productId: productId,
              expirationDate: expirationDate,
            );
          }
        }

        return SubscriptionStatus(
          isActive: true,
          isTrialActive: false,
          productId: productId,
          expirationDate: expirationDate,
        );
      }

      // Check if trial is active
      final trialStartTime = prefs.getInt(_kTrialStartTimeKey);
      final trialDurationDays =
          prefs.getInt(_kTrialDurationDays) ?? _trialDurationDays;
      final isTrialActive = prefs.getBool('trial_active') ?? false;

      if (isTrialActive && trialStartTime != null) {
        final trialStartDate =
            DateTime.fromMillisecondsSinceEpoch(trialStartTime);
        final trialEndDate =
            trialStartDate.add(Duration(days: trialDurationDays));

        // Check if trial has expired
        if (DateTime.now().isAfter(trialEndDate)) {
          // Trial has expired
          await prefs.setBool('trial_active', false);
          return SubscriptionStatus(
            isActive: false,
            isTrialActive: false,
            expirationDate: trialEndDate,
          );
        }

        return SubscriptionStatus(
          isActive: false,
          isTrialActive: true,
          expirationDate: trialEndDate,
        );
      }

      // No active subscription or trial
      return SubscriptionStatus(
        isActive: false,
        isTrialActive: false,
      );
    } catch (e) {
      logger.error('Error checking subscription status: $e');
      return SubscriptionStatus(
        isActive: false,
        isTrialActive: false,
      );
    }
  }
}
