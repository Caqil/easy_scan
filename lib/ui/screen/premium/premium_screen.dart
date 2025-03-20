import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/services/subscription_service.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/ui/screen/premium/components/premium_feature_item.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  bool _isLoading = true;
  bool _purchasing = false;
  String? _selectedProductId;
  List<ProductDetails> _products = [];
  String _errorMessage = '';
  bool _loadingProducts = true;

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

          // Default select the monthly subscription if available
          ProductDetails? monthlyProduct;

          // Safely find the monthly product
          for (var product in products) {
            if (product.id == 'scanpro_premium_monthly') {
              monthlyProduct = product;
              break;
            }
          }

          // Fallback to the first product if monthly not found
          if (monthlyProduct == null && products.isNotEmpty) {
            monthlyProduct = products.first;
          }

          if (monthlyProduct != null) {
            _selectedProductId = monthlyProduct.id;
          }
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

    // Find the selected product safely
    ProductDetails? selectedProduct;
    for (var product in _products) {
      if (product.id == _selectedProductId) {
        selectedProduct = product;
        break;
      }
    }

    // If product not found, use the first one as fallback
    if (selectedProduct == null && _products.isNotEmpty) {
      selectedProduct = _products.first;
    }

    // Check if we have a product to purchase
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

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text('subscription.processing'.tr()),
              ],
            ),
          ),
        ),
      );

      final success =
          await subscriptionService.purchasePackage(selectedProduct);

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(); // Close the premium screen
          AppDialogs.showSnackBar(
            context,
            message: 'subscription.success'.tr(),
            type: SnackBarType.success,
          );
        } else {
          setState(() {
            _errorMessage = 'subscription.failed'.tr();
          });
        }
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e);
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
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text('subscription.restoring'.tr()),
              ],
            ),
          ),
        ),
      );

      final subscriptionService = ref.read(subscriptionServiceProvider);
      final restored = await subscriptionService.restorePurchases();

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        if (restored) {
          Navigator.of(context).pop(); // Close premium screen if restored
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
      // Close loading dialog if open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'subscription.already_purchased'.tr(),
          style: GoogleFonts.slabo27px(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _loadingProducts
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App Icon and Title
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                    child: Column(
                      children: [
                        Container(
                          width: 80.w,
                          height: 80.w,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: const Icon(
                            Icons.document_scanner,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          'subscription.main_title'.tr(),
                          style: GoogleFonts.slabo27px(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'subscription.subtitle'.tr(),
                          style: GoogleFonts.slabo27px(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Free Access Option
                  _buildOptionCard(
                    title: 'subscription.free_option'.tr(),
                    subtitle: 'subscription.free_desc'.tr(),
                    selected: false,
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),

                  // Subscription options
                  if (_products.isNotEmpty) ...[
                    // Monthly Option
                    _buildMonthlyOption(),

                    // Yearly Option
                    _buildYearlyOption(),
                  ],

                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.all(16.r),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: _purchasing ? null : _purchase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: Size(double.infinity, 50.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: _purchasing
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  'subscription.continue'.tr(),
                                  style: GoogleFonts.slabo27px(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),

                        SizedBox(height: 16.h),

                        // Terms and Restore
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed:
                                  _purchasing ? null : _showTermsAndConditions,
                              child: Text(
                                'subscription.terms'.tr(),
                                style: GoogleFonts.slabo27px(
                                  color: Colors.grey[600],
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                            Text(
                              '•',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            TextButton(
                              onPressed: _purchasing ? null : _restorePurchases,
                              child: Text(
                                'subscription.other_plans'.tr(),
                                style: GoogleFonts.slabo27px(
                                  color: Colors.grey[600],
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    String? price,
    String? label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected
              ? Colors.blue.withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.withOpacity(0.2),
            width: selected ? 2 : 1,
          ),
        ),
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            Container(
              width: 24.w,
              height: 24.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? Colors.blue : Colors.transparent,
                border: selected ? null : Border.all(color: Colors.grey),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.slabo27px(
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: GoogleFonts.slabo27px(
                        color: Colors.grey[600],
                        fontSize: 14.sp,
                      ),
                    ),
                ],
              ),
            ),
            if (price != null)
              Text(
                price,
                style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            if (label != null) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.slabo27px(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyOption() {
    ProductDetails? monthlyProduct;

    // Safely find the monthly product
    for (var product in _products) {
      if (product.id == 'scanpro_premium_monthly') {
        monthlyProduct = product;
        break;
      }
    }

    // Fallback to the first product if monthly not found
    if (monthlyProduct == null && _products.isNotEmpty) {
      monthlyProduct = _products.first;
    }

    // If we have no products at all, show a placeholder
    if (monthlyProduct == null) {
      return SizedBox.shrink();
    }

    return _buildOptionCard(
      title: 'subscription.monthly_title'.tr(),
      subtitle: 'subscription.monthly_desc'.tr(),
      price: monthlyProduct.price,
      label: 'subscription.most_popular'.tr(),
      selected: _selectedProductId == monthlyProduct.id,
      onTap: () {
        setState(() {
          _selectedProductId = monthlyProduct!.id;
        });
      },
    );
  }

  Widget _buildYearlyOption() {
    ProductDetails? yearlyProduct;
    ProductDetails? alternativeProduct;

    // Safely find products
    for (var product in _products) {
      if (product.id == 'scanpro_premium_yearly') {
        yearlyProduct = product;
      }

      if (product.id != 'scanpro_premium_monthly' &&
          alternativeProduct == null) {
        alternativeProduct = product;
      }
    }

    // Use yearly if found, otherwise use alternative, or the last product
    final selectedProduct = yearlyProduct ??
        alternativeProduct ??
        (_products.isNotEmpty ? _products.last : null);

    // If we have no products at all, show a placeholder
    if (selectedProduct == null) {
      return SizedBox.shrink();
    }

    return _buildOptionCard(
      title: 'subscription.yearly_title'.tr(),
      subtitle: 'subscription.yearly_desc'.tr(),
      price: selectedProduct.price,
      selected: _selectedProductId == selectedProduct.id,
      onTap: () {
        setState(() {
          _selectedProductId = selectedProduct.id;
        });
      },
    );
  }
}
