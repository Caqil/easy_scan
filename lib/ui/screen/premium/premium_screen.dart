import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/services/subscription_service.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/ui/screen/premium/components/bottom_links.dart';
import 'package:scanpro/ui/screen/premium/components/premium_features.dart';
import 'package:scanpro/ui/screen/premium/components/premium_header.dart';
import 'package:scanpro/ui/screen/premium/components/purchase_button.dart';
import 'package:scanpro/ui/screen/premium/components/subscription_option.dart';
import 'package:scanpro/ui/screen/premium/components/trial_toggle.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _purchasing = false;
  String? _selectedProductId;
  bool _purchasePending = false;
  List<ProductDetails> _products = [];
  String _errorMessage = '';
  bool _loadingProducts = true;
  bool _isTrialEnabled = true; // Added trial toggle state

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loadingProducts = true;
      _errorMessage = '';
    });

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final products = await subscriptionService.getSubscriptionPackages();

      if (mounted) {
        setState(() {
          _products = products;
          _loadingProducts = false;

          // Default select the yearly product if available for better value
          ProductDetails? yearlyProduct;
          ProductDetails? monthlyProduct;
          ProductDetails? weeklyProduct;
          // Find monthly and yearly products
          for (var product in products) {
            if (product.id == 'scanpro_premium_yearly') {
              yearlyProduct = product;
            } else if (product.id == 'scanpro_premium_monthly') {
              monthlyProduct = product;
            } else if (product.id == 'scanpro_premium_weekly') {
              weeklyProduct = product;
            }
          }

          // Prioritize yearly, then monthly, then first available
          _selectedProductId =
              yearlyProduct?.id ?? monthlyProduct?.id ?? weeklyProduct!.id;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingProducts = false;
          _errorMessage = 'subscription.load_error'.tr();
          logger.error('Error loading products: $e');
        });
      }
    }
  }

  Future<void> _purchase() async {
    if (_selectedProductId == null || _products.isEmpty) {
      setState(() {
        _errorMessage = 'subscription.select_plan'.tr();
      });
      return;
    }

    ProductDetails? selectedProduct;
    for (var product in _products) {
      if (product.id == _selectedProductId) {
        selectedProduct = product;
        break;
      }
    }

    if (selectedProduct == null) {
      setState(() {
        _errorMessage = 'subscription.no_product'.tr();
      });
      return;
    }

    setState(() {
      _purchasing = true;
      _errorMessage = '';
    });

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);

      await subscriptionService.purchasePackage(selectedProduct);
      await Future.delayed(const Duration(seconds: 1));
      final subscriptionStatus = ref.read(subscriptionStatusProvider);
      final isSuccess =
          subscriptionStatus.isActive || subscriptionStatus.isTrialActive;
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        if (isSuccess) {
          Navigator.of(context).pop();
          AppDialogs.showSnackBar(
            context,
            message: 'subscription.success'.tr(),
            type: SnackBarType.success,
          );
        } else if (_purchasePending) {
          setState(() {
            _purchasing = true;
            _errorMessage = '';
          });
        } else {
          setState(() {
            _purchasing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e);
          _purchasing = false;
        });
        AppDialogs.showSnackBar(
          context,
          message: _getErrorMessage(e),
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _purchasing = false;
        });
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('cancel') ||
        errorString.contains('user canceled')) {
      return 'subscription.canceled'.tr();
    } else if (errorString.contains('network')) {
      return 'subscription.network_error'.tr();
    } else if (errorString.contains('already purchased')) {
      return 'subscription.already_purchased'.tr();
    }

    return 'subscription.error'.tr();
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _purchasing = true;
      _errorMessage = '';
    });

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final restored = await subscriptionService.restorePurchases();

      if (mounted) {
        if (restored) {
          AppDialogs.showSnackBar(
            context,
            message: 'subscription.restore_success'.tr(),
            type: SnackBarType.success,
          );
        } else {
          AppDialogs.showSnackBar(
            context,
            message: 'subscription.no_purchases'.tr(),
            type: SnackBarType.warning,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'subscription.restore_error'.tr(),
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _purchasing = false;
        });
      }
    }
  }

  void _showTermsAndConditions() {
    AppDialogs.showSnackBar(
      context,
      message: 'subscription.terms_info'.tr(),
      type: SnackBarType.normal,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loadingProducts
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 40.h),
                        const PremiumHeader(),
                        SizedBox(height: 20.h),
                        const PremiumFeatures(),
                        SizedBox(height: 20.h),
                        TrialToggle(
                          isTrialEnabled: _isTrialEnabled,
                          onChanged: (value) {
                            setState(() {
                              _isTrialEnabled = value;
                              // Update selected product based on trial state
                              _selectedProductId = _isTrialEnabled
                                  ? _products
                                      .firstWhere(
                                        (p) => p.id == 'scanpro_premium_yearly',
                                      )
                                      .id
                                  : _products
                                      .firstWhere(
                                        (p) =>
                                            p.id == 'scanpro_premium_monthly',
                                      )
                                      .id;
                            });
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: SubscriptionOptionsWidget(
                            products: _products,
                            selectedProductId: _selectedProductId,
                            isTrialEnabled: _isTrialEnabled,
                            onFreePlanSelected: () =>
                                Navigator.of(context).pop(),
                            onProductSelected: (productId) {
                              setState(() => _selectedProductId = productId);
                            },
                          ),
                        ),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.all(16.r),
                            child: Container(
                              padding: EdgeInsets.all(10.r),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                _errorMessage,
                                style: GoogleFonts.slabo27px(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        PurchaseButton(
                          isPurchasing: _purchasing,
                          isTrialEnabled: _isTrialEnabled,
                          onPressed: _purchase,
                        ),
                        SizedBox(height: 16.h),
                        BottomLinks(
                          isPurchasing: _purchasing,
                          onTermsPressed: _showTermsAndConditions,
                          onRestorePressed: _restorePurchases,
                        ),
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
