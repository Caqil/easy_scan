import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scanpro/main.dart';

// Product IDs
const String kWeeklyProductId = 'scanpro_premium_weekly';
const String kMonthlyProductId = 'scanpro_premium_monthly';
const String kYearlyProductId = 'scanpro_premium_yearly';

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
  static const String _kTrialStartTimeKey = 'trial_start_time';
  static const String _kTrialDurationDays = 'trial_duration_days';
  static const String _kSubscriptionActiveKey = 'subscription_active';
  static const String _kSubscriptionProductIdKey = 'subscription_product_id';
  static const String _kSubscriptionExpirationKey = 'subscription_expiration';
  static const int _trialDurationDays = 7; // 7-day free trial

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  var _purchaseCompleter = Completer<bool>();

  // Initialize the service
  Future<void> initialize() async {
    logger.info('Starting SubscriptionService initialization');

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
        logger.info('Purchase stream completed');
        _subscription?.cancel();
      },
      onError: (error) {
        logger.error('Error in purchase stream: $error');
        if (!_purchaseCompleter.isCompleted) {
          _purchaseCompleter.complete(false);
        }
      },
    );

    await _loadProducts();
    await refreshSubscriptionStatus();

    logger.info('SubscriptionService initialized successfully');
  }

  void dispose() {
    logger.info('Disposing SubscriptionService');
    _subscription?.cancel();
    logger.info('Subscription stream cancelled');
  }

  Future<void> _loadProducts() async {
    logger.info('Loading products');
    try {
      final Set<String> productIds = {
        kWeeklyProductId,
        kMonthlyProductId,
        kYearlyProductId
      };
      logger.info('Querying product details for IDs: $productIds');
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        logger.warning('Some product IDs not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      logger.info('Loaded ${_products.length} product(s)');

      // Debug log of loaded products
      for (final product in _products) {
        logger.debug('Product: ${product.id}, Price: ${product.price}');
      }
    } catch (e) {
      logger.error('Error loading products: $e');
    }
  }

  // Get all available subscription packages
  Future<List<ProductDetails>> getSubscriptionPackages() async {
    logger.info('Getting subscription packages');
    if (_products.isEmpty) {
      logger.info('Products empty, loading products');
      await _loadProducts();
    }
    logger.info('Returning ${_products.length} subscription packages');
    return _products;
  }

  // Get categorized subscription packages
  Future<Map<String, List<ProductDetails>>> getSubscriptionOptions() async {
    logger.info('Getting subscription options');
    final Map<String, List<ProductDetails>> result = {
      'weekly': [],
      'monthly': [],
      'yearly': [],
    };

    final products = await getSubscriptionPackages();

    for (final product in products) {
      logger.debug('Categorizing product: ${product.id}');
      if (product.id == kWeeklyProductId) {
        result['weekly']!.add(product);
      } else if (product.id == kMonthlyProductId) {
        result['monthly']!.add(product);
      } else if (product.id == kYearlyProductId) {
        result['yearly']!.add(product);
      }
    }

    logger.info('Returning subscription options: ${result.keys}');
    return result;
  }

  Future<bool> purchasePackage(ProductDetails product) async {
    logger.info('Starting purchase for package: ${product.id}');
    final provider = ProviderContainer();
    provider.read(subscriptionLoadingProvider.notifier).state = true;
    provider.read(subscriptionErrorProvider.notifier).state = null;

    final completer = Completer<bool>();
    _purchaseCompleter = completer;

    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
        applicationUserName: null,
      );

      bool purchaseStarted = false;

      try {
        logger.info('Attempting initial purchase method');
        if (Platform.isIOS) {
          purchaseStarted = await _inAppPurchase.buyNonConsumable(
              purchaseParam: purchaseParam);
        } else {
          purchaseStarted =
              await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
        }
      } catch (purchaseError) {
        logger.error('Initial purchase method failed: $purchaseError');
        try {
          logger.info('Attempting alternative purchase method');
          if (Platform.isIOS) {
            purchaseStarted = await _inAppPurchase.buyConsumable(
                purchaseParam: purchaseParam);
          } else {
            purchaseStarted = await _inAppPurchase.buyNonConsumable(
                purchaseParam: purchaseParam);
          }
        } catch (secondError) {
          logger.error('Alternative purchase method failed: $secondError');
          throw secondError;
        }
      }

      if (!purchaseStarted) {
        logger.error('Failed to start purchase for ${product.id}');
        completer.complete(false);
        return false;
      }

      logger.info('Purchase started, awaiting completion');
      return await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          logger.error('Purchase timed out for ${product.id}');
          return false;
        },
      );
    } catch (e) {
      logger.error('Error purchasing package ${product.id}: $e');
      provider.read(subscriptionErrorProvider.notifier).state = e.toString();
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      return false;
    } finally {
      logger.info('Purchase process completed for ${product.id}');
      provider.read(subscriptionLoadingProvider.notifier).state = false;
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    logger.info(
        'Processing purchase update for ${purchaseDetailsList.length} items');
    bool purchaseSuccess = false;

    for (final purchaseDetails in purchaseDetailsList) {
      logger.info(
          'Purchase update: ${purchaseDetails.status} for ${purchaseDetails.productID}');

      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          logger.info('Purchase pending for ${purchaseDetails.productID}');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          logger.info('Purchase successful: ${purchaseDetails.productID}');
          await _verifyPurchase(purchaseDetails);
          purchaseSuccess = true;
          if (!_purchaseCompleter.isCompleted) {
            _purchaseCompleter.complete(true);
          }
          break;

        case PurchaseStatus.error:
          logger.error(
              'Purchase error for ${purchaseDetails.productID}: ${purchaseDetails.error?.message ?? "Unknown error"}');
          purchaseSuccess = false;
          if (!_purchaseCompleter.isCompleted) {
            _purchaseCompleter.complete(false);
          }
          break;

        case PurchaseStatus.canceled:
          logger.info('Purchase canceled for ${purchaseDetails.productID}');
          purchaseSuccess = false;
          if (!_purchaseCompleter.isCompleted) {
            _purchaseCompleter.complete(false);
          }
          break;
      }

      if (purchaseDetails.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchaseDetails);
        logger.info('Purchase completed for ${purchaseDetails.productID}');
      }
    }

    if (purchaseDetailsList.isNotEmpty && !_purchaseCompleter.isCompleted) {
      logger.info('Completing purchase with result: $purchaseSuccess');
      _purchaseCompleter.complete(purchaseSuccess);
    }

    await refreshSubscriptionStatus();
  }

  // Start a free trial
  Future<bool> startTrial() async {
    logger.info('Starting free trial');
    final provider = ProviderContainer();
    provider.read(subscriptionLoadingProvider.notifier).state = true;

    try {
      ProductDetails? yearlyProduct;
      for (final product in _products) {
        if (product.id == kYearlyProductId) {
          yearlyProduct = product;
          break;
        }
      }

      if (yearlyProduct == null) {
        for (final product in _products) {
          if (product.id == kMonthlyProductId) {
            yearlyProduct = product;
            break;
          }
        }
      }

      if (yearlyProduct == null) {
        logger.error('No suitable subscription product found for trial');
        throw Exception('No suitable subscription product found for trial');
      }

      logger.info('Starting trial with product: ${yearlyProduct.id}');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _kTrialStartTimeKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_kTrialDurationDays, _trialDurationDays);
      await prefs.setBool(_kSubscriptionActiveKey, false);
      await prefs.setBool('trial_active', true);

      final status = SubscriptionStatus(
        isActive: false,
        isTrialActive: true,
        expirationDate: DateTime.now().add(Duration(days: _trialDurationDays)),
        productId: yearlyProduct.id,
      );

      provider.read(subscriptionStatusProvider.notifier).updateStatus(status);
      logger.info('Trial started successfully');
      return true;
    } catch (e) {
      logger.error('Error starting trial: $e');
      return false;
    } finally {
      logger.info('Trial process completed');
      provider.read(subscriptionLoadingProvider.notifier).state = false;
    }
  }

  // Restore purchases
  Future<bool> restorePurchases() async {
    logger.info('Starting purchase restoration');
    final provider = ProviderContainer();
    provider.read(subscriptionLoadingProvider.notifier).state = true;

    try {
      await _inAppPurchase.restorePurchases();
      logger.info('Restore purchases initiated');

      await Future.delayed(const Duration(seconds: 2));
      final status = await _checkSubscriptionStatus();
      logger.info('Restored status: $status');
      return status.isActive;
    } catch (e) {
      logger.error('Error restoring purchases: $e');
      return false;
    } finally {
      logger.info('Restore process completed');
      provider.read(subscriptionLoadingProvider.notifier).state = false;
    }
  }

  // Check if user has an active subscription
  Future<bool> hasActiveSubscription() async {
    logger.info('Checking active subscription');
    final status = await _checkSubscriptionStatus();
    logger.info('Active subscription status: ${status.isActive}');
    return status.isActive;
  }

  // Check if user has trial or subscription
  Future<bool> hasActiveTrialOrSubscription() async {
    logger.info('Checking active trial or subscription');
    final status = await _checkSubscriptionStatus();
    logger.info(
        'Trial or subscription active: ${status.isActive || status.isTrialActive}');
    return status.isActive || status.isTrialActive;
  }

  // Refresh subscription status
  Future<void> refreshSubscriptionStatus() async {
    logger.info('Refreshing subscription status');
    final status = await _checkSubscriptionStatus();
    final provider = ProviderContainer();
    provider.read(subscriptionStatusProvider.notifier).updateStatus(status);
    logger.info('Subscription status refreshed: $status');
  }

  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    logger.info('Verifying purchase: ${purchaseDetails.productID}');
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_kSubscriptionActiveKey, true);
    await prefs.setBool('trial_active', false);
    await prefs.setString(
        _kSubscriptionProductIdKey, purchaseDetails.productID);

    DateTime expirationDate;
    if (purchaseDetails.productID == kWeeklyProductId) {
      expirationDate = DateTime.now().add(const Duration(days: 7));
    } else if (purchaseDetails.productID == kMonthlyProductId) {
      expirationDate = DateTime.now().add(const Duration(days: 30));
    } else {
      expirationDate = DateTime.now().add(const Duration(days: 365));
    }

    await prefs.setString(
        _kSubscriptionExpirationKey, expirationDate.toIso8601String());

    logger.info(
        'Purchase verified, active until ${expirationDate.toIso8601String()}');
  }

  // Check current subscription status
  Future<SubscriptionStatus> _checkSubscriptionStatus() async {
    logger.info('Checking subscription status');
    try {
      final prefs = await SharedPreferences.getInstance();
      final isActive = prefs.getBool(_kSubscriptionActiveKey) ?? false;

      if (isActive) {
        final productId = prefs.getString(_kSubscriptionProductIdKey);
        final expirationString = prefs.getString(_kSubscriptionExpirationKey);
        DateTime? expirationDate = expirationString != null
            ? DateTime.tryParse(expirationString)
            : null;

        if (expirationDate != null && expirationDate.isBefore(DateTime.now())) {
          logger.info('Subscription expired: $expirationDate');
          await prefs.setBool(_kSubscriptionActiveKey, false);
          return SubscriptionStatus(
            isActive: false,
            isTrialActive: false,
            productId: productId,
            expirationDate: expirationDate,
          );
        }

        logger.info('Active subscription found: $productId');
        return SubscriptionStatus(
          isActive: true,
          isTrialActive: false,
          productId: productId,
          expirationDate: expirationDate,
        );
      }

      final trialStartTime = prefs.getInt(_kTrialStartTimeKey);
      final trialDurationDays =
          prefs.getInt(_kTrialDurationDays) ?? _trialDurationDays;
      final isTrialActive = prefs.getBool('trial_active') ?? false;

      if (isTrialActive && trialStartTime != null) {
        final trialStartDate =
            DateTime.fromMillisecondsSinceEpoch(trialStartTime);
        final trialEndDate =
            trialStartDate.add(Duration(days: trialDurationDays));

        if (DateTime.now().isAfter(trialEndDate)) {
          logger.info('Trial expired: $trialEndDate');
          await prefs.setBool('trial_active', false);
          return SubscriptionStatus(
            isActive: false,
            isTrialActive: false,
            expirationDate: trialEndDate,
          );
        }

        logger.info('Active trial found, expires: $trialEndDate');
        return SubscriptionStatus(
          isActive: false,
          isTrialActive: true,
          expirationDate: trialEndDate,
        );
      }

      logger.info('No active subscription or trial found');
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
