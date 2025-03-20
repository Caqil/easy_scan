import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:scanpro/services/subscription_service.dart';
import 'package:scanpro/ui/common/dialogs.dart';

import 'package:easy_localization/easy_localization.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  _PremiumScreenState createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  String _selectedPlan = 'monthly';
  bool _isLoading = false;
  List<Package> _packages = [];

  // Premium features specific to the app
  final List<Map<String, String>> _premiumFeatures = [
    {
      'icon': 'assets/icons/ocr.png',
      'title': 'premium.advanced_ocr'.tr(),
      'description': 'premium.advanced_ocr_desc'.tr(),
    },
    {
      'icon': 'assets/icons/security.png',
      'title': 'premium.enhanced_security'.tr(),
      'description': 'premium.enhanced_security_desc'.tr(),
    },
    {
      'icon': 'assets/icons/cloud.png',
      'title': 'premium.cloud_sync'.tr(),
      'description': 'premium.cloud_sync_desc'.tr(),
    },
    {
      'icon': 'assets/icons/unlimited.png',
      'title': 'premium.unlimited_scans'.tr(),
      'description': 'premium.unlimited_scans_desc'.tr(),
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final packages = await subscriptionService.getSubscriptionPackages();

      // Debug print to understand available packages
      debugPrint('Available Packages:');
      for (var pkg in packages) {
        debugPrint(
            'Package Type: ${pkg.packageType}, Identifier: ${pkg.identifier}');
      }

      setState(() {
        _packages = packages;
      });
    } catch (e) {
      AppDialogs.showSnackBar(
        context,
        message: 'premium.packages_fetch_error'.tr(),
        type: SnackBarType.error,
      );
    }
  }

  void _selectPlan(String plan) {
    setState(() {
      _selectedPlan = plan;
    });
  }

  Future<void> _subscribe() async {
    if (_packages.isEmpty) {
      AppDialogs.showSnackBar(
        context,
        message: 'premium.no_packages'.tr(),
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);

      // Find the correct package based on selected plan
      Package? selectedPackage;

      // Check packages to find the correct one
      for (var pkg in _packages) {
        // Log package details for debugging
        debugPrint(
            'Checking package: ${pkg.packageType}, Identifier: ${pkg.identifier}');

        // Logic to match the selected plan type
        if (_selectedPlan == 'monthly' &&
            (pkg.packageType == PackageType.monthly ||
                pkg.identifier.toLowerCase().contains('monthly'))) {
          selectedPackage = pkg;
          break;
        } else if (_selectedPlan == 'yearly' &&
            (pkg.packageType == PackageType.annual ||
                pkg.identifier.toLowerCase().contains('yearly'))) {
          selectedPackage = pkg;
          break;
        }
      }

      // If no specific package found, fall back to first package
      selectedPackage ??= _packages.first;

      // Log selected package for debugging
      debugPrint(
          'Selected Package: ${selectedPackage.packageType}, Identifier: ${selectedPackage.identifier}');

      // Attempt to purchase the selected package
      await subscriptionService.purchasePackage(selectedPackage);

      // Navigate away or show success
      if (mounted) {
        Navigator.of(context).pop();
        AppDialogs.showSnackBar(
          context,
          message: 'premium.subscription_success'.tr(),
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      AppDialogs.showSnackBar(
        context,
        message: 'premium.subscription_failed'
            .tr(namedArgs: {'error': e.toString()}),
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPlanOption({
    required String planType,
    required String title,
    required String details,
    String? savings,
  }) {
    return GestureDetector(
      onTap: () => _selectPlan(planType),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedPlan == planType
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: _selectedPlan == planType
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.white,
        ),
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            if (_selectedPlan == planType)
              Icon(Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.slabo27px(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    details,
                    style: GoogleFonts.slabo27px(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (savings != null)
              Text(
                savings,
                style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('premium.title'.tr()),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Features Section
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text(
                  'premium.features_title'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Features List
              ...(_premiumFeatures
                  .map((feature) => _buildFeatureItem(feature))),

              // Subscription Plans
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Text(
                  'premium.choose_plan'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Monthly Plan
              _buildPlanOption(
                planType: 'monthly',
                title: 'premium.monthly_plan'.tr(),
                details: 'premium.monthly_plan_details'.tr(),
              ),
              SizedBox(height: 16),

              // Yearly Plan
              _buildPlanOption(
                planType: 'yearly',
                title: 'premium.yearly_plan'.tr(),
                details: 'premium.yearly_plan_details'.tr(),
                savings: 'premium.yearly_savings'.tr(),
              ),

              // Continue Button
              Padding(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _subscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'premium.continue'.tr(),
                          style: GoogleFonts.slabo27px(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                ),
              ),

              // Additional Options
              Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _showTerms(),
                      child: Text(
                        'premium.terms'.tr(),
                        style: GoogleFonts.slabo27px(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _restorePurchases(),
                      child: Text(
                        'premium.restore'.tr(),
                        style: GoogleFonts.slabo27px(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(Map<String, String> feature) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Image.asset(
            feature['icon']!,
            width: 40.w,
            height: 40.h,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature['title']!,
                  style: GoogleFonts.slabo27px(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  feature['description']!,
                  style: GoogleFonts.slabo27px(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTerms() {}

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final restored = await subscriptionService.restorePurchases();

      if (restored) {
        if (mounted) {
          AppDialogs.showSnackBar(
            context,
            message: 'premium.restore_success'.tr(),
            type: SnackBarType.success,
          );
        }
      } else {
        if (mounted) {
          AppDialogs.showSnackBar(
            context,
            message: 'premium.restore_failed'.tr(),
            type: SnackBarType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message:
              'premium.restore_error'.tr(namedArgs: {'error': e.toString()}),
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
