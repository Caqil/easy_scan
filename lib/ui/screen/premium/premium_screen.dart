import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
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
  String? _selectedPackageId;
  List<Package> _packages = [];
  String _errorMessage = '';
  bool _loadingPackages = true;
  bool _isTrialEnabled = true; // Trial toggle state

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() {
      _loadingPackages = true;
      _errorMessage = '';
    });

    try {
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null) {
        logger.error('No offerings available from RevenueCat');
        throw Exception('No subscription offerings found');
      }

      final packages = offerings.current!.availablePackages;

      if (mounted) {
        setState(() {
          _packages = packages;
          _loadingPackages = false;

          // Default select the yearly package for better value
          Package? yearlyPackage;
          Package? monthlyPackage;
          Package? weeklyPackage;

          // Find packages based on type
          for (var package in packages) {
            if (package.packageType == PackageType.annual ||
                package.identifier.contains('yearly')) {
              yearlyPackage = package;
            } else if (package.packageType == PackageType.monthly ||
                package.identifier.contains('monthly')) {
              monthlyPackage = package;
            } else if (package.packageType == PackageType.weekly ||
                package.identifier.contains('weekly')) {
              weeklyPackage = package;
            }
          }

          // Prioritize yearly, then monthly, then first available
          _selectedPackageId = yearlyPackage?.identifier ??
              monthlyPackage?.identifier ??
              weeklyPackage?.identifier ??
              packages.first.identifier;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingPackages = false;
          _errorMessage = 'subscription.load_error'.tr();
          logger.error('Error loading packages: $e');
        });
      }
    }
  }

  Future<void> _purchase() async {
    if (_selectedPackageId == null || _packages.isEmpty) {
      setState(() {
        _errorMessage = 'subscription.select_plan'.tr();
      });
      return;
    }

    Package? selectedPackage;
    for (var package in _packages) {
      if (package.identifier == _selectedPackageId) {
        selectedPackage = package;
        break;
      }
    }

    if (selectedPackage == null) {
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

      final success =
          await subscriptionService.purchasePackage(selectedPackage);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
          AppDialogs.showSnackBar(
            context,
            message: 'subscription.success'.tr(),
            type: SnackBarType.success,
          );
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

          // Close the premium screen since the user has restored their subscription
          Future.delayed(Duration(seconds: 1), () {
            if (mounted) Navigator.of(context).pop();
          });
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
      body: _loadingPackages
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

                              // Update selected package based on trial state
                              if (_isTrialEnabled) {
                                // Find yearly package
                                for (var package in _packages) {
                                  if (package.packageType ==
                                          PackageType.annual ||
                                      package.identifier.contains('yearly')) {
                                    _selectedPackageId = package.identifier;
                                    break;
                                  }
                                }
                              } else {
                                // Find monthly package
                                for (var package in _packages) {
                                  if (package.packageType ==
                                          PackageType.monthly ||
                                      package.identifier.contains('monthly')) {
                                    _selectedPackageId = package.identifier;
                                    break;
                                  }
                                }
                              }
                            });
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: RevenueCatSubscriptionOptions(
                            packages: _packages,
                            selectedPackageId: _selectedPackageId,
                            isTrialEnabled: _isTrialEnabled,
                            onFreePlanSelected: () =>
                                Navigator.of(context).pop(),
                            onPackageSelected: (packageId) {
                              setState(() => _selectedPackageId = packageId);
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
                              child: AutoSizeText(
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
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
