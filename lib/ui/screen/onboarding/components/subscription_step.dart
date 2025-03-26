import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:scanpro/services/subscription_service.dart';
import 'package:scanpro/ui/common/dialogs.dart';

class SubscriptionStep extends ConsumerStatefulWidget {
  final VoidCallback onSubscriptionHandled;

  const SubscriptionStep({
    super.key,
    required this.onSubscriptionHandled,
  });

  @override
  ConsumerState<SubscriptionStep> createState() => _SubscriptionStepState();
}

class _SubscriptionStepState extends ConsumerState<SubscriptionStep>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasSubscription = false;
  bool _showPackages = false;
  bool _isTrialEnabled = true; // Added trial toggle state
  List<Package> _packages = [];
  late AnimationController _animationController;
  String? _selectedPackageId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _checkSubscriptionStatus();
    _loadPackages();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkSubscriptionStatus() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final hasActiveSubscription =
          await subscriptionService.hasActiveTrialOrSubscription();

      setState(() {
        _hasSubscription = hasActiveSubscription;
        _isLoading = false;
      });

      if (hasActiveSubscription) {
        widget.onSubscriptionHandled();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });

      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'onboarding.subscription_check_error'.tr(),
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _loadPackages() async {
    try {
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null ||
          offerings.current!.availablePackages.isEmpty) {
        return;
      }

      if (mounted) {
        setState(() {
          _packages = offerings.current!.availablePackages;

          // Find default package based on trial preference
          Package? yearlyPackage;
          Package? monthlyPackage;

          for (var package in _packages) {
            // Look for yearly package
            if (package.packageType == PackageType.annual ||
                package.identifier.contains('yearly')) {
              yearlyPackage = package;
            }
            // Look for monthly package
            else if (package.packageType == PackageType.monthly ||
                package.identifier.contains('monthly')) {
              monthlyPackage = package;
            }
          }

          if (_isTrialEnabled) {
            _selectedPackageId = yearlyPackage?.identifier ??
                (_packages.isNotEmpty ? _packages.first.identifier : null);
          } else {
            _selectedPackageId = monthlyPackage?.identifier ??
                yearlyPackage?.identifier ??
                (_packages.isNotEmpty ? _packages.first.identifier : null);
          }
        });
      }
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> _startTrialOrPurchase() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);

      // Find the selected package
      Package? selectedPackage;
      for (var package in _packages) {
        if (package.identifier == _selectedPackageId) {
          selectedPackage = package;
          break;
        }
      }

      // If no package is selected or found, try to find a default one
      if (selectedPackage == null) {
        if (_isTrialEnabled) {
          // Look for package with trial or annual package
          for (var package in _packages) {
            if (package.packageType == PackageType.annual ||
                package.identifier.contains('yearly')) {
              selectedPackage = package;
              break;
            }
          }
        } else {
          // Look for monthly package
          for (var package in _packages) {
            if (package.packageType == PackageType.monthly ||
                package.identifier.contains('monthly')) {
              selectedPackage = package;
              break;
            }
          }
        }

        // If still no package found, use the first available
        if (selectedPackage == null && _packages.isNotEmpty) {
          selectedPackage = _packages.first;
        }
      }

      if (selectedPackage == null) {
        throw Exception('No subscription package available');
      }

      bool success;
      if (_isTrialEnabled) {
        success = await subscriptionService.startTrial();
      } else {
        success = await subscriptionService.purchasePackage(selectedPackage);
      }

      if (mounted && success) {
        setState(() {
          _hasSubscription = true;
          _isLoading = false;
        });

        AppDialogs.showSnackBar(
          context,
          message: _isTrialEnabled
              ? 'onboarding.trial_started'.tr()
              : 'onboarding.subscription_successful'.tr(),
          type: SnackBarType.success,
        );

        widget.onSubscriptionHandled();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });

        AppDialogs.showSnackBar(
          context,
          message: 'onboarding.subscription_error'.tr(),
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final subscriptionService = ref.read(subscriptionServiceProvider);
      final restored = await subscriptionService.restorePurchases();

      if (mounted) {
        if (restored) {
          setState(() {
            _hasSubscription = true;
            _isLoading = false;
          });

          AppDialogs.showSnackBar(
            context,
            message: 'onboarding.restore_success'.tr(),
            type: SnackBarType.success,
          );

          widget.onSubscriptionHandled();
        } else {
          setState(() {
            _isLoading = false;
          });

          AppDialogs.showSnackBar(
            context,
            message: 'onboarding.no_purchases'.tr(),
            type: SnackBarType.warning,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });

        AppDialogs.showSnackBar(
          context,
          message: 'onboarding.restore_error'.tr(),
          type: SnackBarType.error,
        );
      }
    }
  }

  void _togglePackages() {
    setState(() {
      _showPackages = !_showPackages;
    });
  }

  void _skipSubscription() {
    widget.onSubscriptionHandled();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AutoSizeText(
              'onboarding.subscription_title'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 26.adaptiveSp,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: 12.h),
            AutoSizeText(
              'onboarding.subscription_description'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 14.adaptiveSp,
                color: colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),

            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    'onboarding.premium_features'.tr(),
                    style: GoogleFonts.slabo27px(
                      fontSize: 18.adaptiveSp,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildFeaturesList(colorScheme),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Trial toggle
            _buildTrialToggle(colorScheme),

            SizedBox(height: 24.h),

            if (_showPackages) _buildSubscriptionPackages(colorScheme),

            if (_hasSubscription)
              _buildSubscriptionActiveCard(colorScheme)
            else
              _buildTrialButton(colorScheme),

            SizedBox(height: 16.h),

            if (!_hasSubscription && !_isLoading)
              Center(
                child: TextButton(
                  onPressed: _restorePurchases,
                  style: TextButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                  ),
                  child: AutoSizeText(
                    'onboarding.restore_purchases'.tr(),
                    style: GoogleFonts.slabo27px(
                      fontSize: 14.adaptiveSp,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),

            SizedBox(height: 12.h),

            if (!_hasSubscription && !_isLoading)
              Center(
                child: TextButton(
                  onPressed: _skipSubscription,
                  style: TextButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                  ),
                  child: AutoSizeText(
                    'onboarding.maybe_later'.tr(),
                    style: GoogleFonts.slabo27px(
                      fontSize: 14.adaptiveSp,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),

            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList(ColorScheme colorScheme) {
    final features = [
      {
        'icon': Icons.document_scanner,
        'title': 'onboarding.ocr_feature'.tr(),
        'description': 'onboarding.ocr_feature_desc'.tr(),
      },
      {
        'icon': Icons.lock_outline,
        'title': 'onboarding.security_feature'.tr(),
        'description': 'onboarding.security_feature_desc'.tr(),
      },
      {
        'icon': Icons.cloud_upload_outlined,
        'title': 'onboarding.cloud_feature'.tr(),
        'description': 'onboarding.cloud_feature_desc'.tr(),
      },
      {
        'icon': Icons.file_copy_outlined,
        'title': 'onboarding.unlimited_feature'.tr(),
        'description': 'onboarding.unlimited_feature_desc'.tr(),
      },
    ];

    return Column(
      children: features
          .map((feature) => _buildFeatureItem(
                icon: feature['icon'] as IconData,
                title: feature['title'] as String,
                description: feature['description'] as String,
                colorScheme: colorScheme,
              ))
          .toList(),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 18.r,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  title,
                  style: GoogleFonts.slabo27px(
                    fontSize: 15.adaptiveSp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                AutoSizeText(
                  description,
                  style: GoogleFonts.slabo27px(
                    fontSize: 12.adaptiveSp,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialToggle(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: _isTrialEnabled
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _isTrialEnabled
              ? colorScheme.primary.withOpacity(0.2)
              : colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  'subscription.free_option'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontSize: 14.adaptiveSp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                AutoSizeText(
                  'trial_explanation.price_info_1'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontSize: 14.adaptiveSp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isTrialEnabled,
            onChanged: (value) {
              setState(() {
                _isTrialEnabled = value;

                // Update selected package based on trial state
                if (_isTrialEnabled) {
                  // Find yearly package
                  for (var package in _packages) {
                    if (package.packageType == PackageType.annual ||
                        package.identifier.contains('yearly')) {
                      _selectedPackageId = package.identifier;
                      break;
                    }
                  }
                } else {
                  // Find monthly package
                  for (var package in _packages) {
                    if (package.packageType == PackageType.monthly ||
                        package.identifier.contains('monthly')) {
                      _selectedPackageId = package.identifier;
                      break;
                    }
                  }
                }
              });
            },
            activeColor: colorScheme.primary,
            activeTrackColor: colorScheme.primary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialButton(ColorScheme colorScheme) {
    return Column(
      children: [
        OutlinedButton(
          onPressed: _isLoading
              ? null
              : () =>
                  _showPackages ? _togglePackages() : _startTrialOrPurchase(),
          style: OutlinedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 2,
            shadowColor: colorScheme.primary.withOpacity(0.4),
            minimumSize: Size(double.infinity, 54.h),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 24.r,
                  height: 24.r,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showPackages ? Icons.close : Icons.star_border_outlined,
                      size: 20.r,
                    ),
                    SizedBox(width: 8.w),
                    AutoSizeText(
                      _showPackages
                          ? 'onboarding.hide_options'.tr()
                          : (_isTrialEnabled
                              ? 'onboarding.start_free_trial'.tr()
                              : 'subscription.continue'.tr()),
                      style: GoogleFonts.slabo27px(
                        fontSize: 16.adaptiveSp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
        // if (!_showPackages) SizedBox(height: 12.h),
        // if (!_showPackages)
        //   TextButton(
        //     onPressed: _togglePackages,
        //     style: TextButton.styleFrom(
        //       padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
        //     ),
        //     child: AutoSizeText(
        //       'onboarding.see_subscription_plans'.tr(),
        //       style: GoogleFonts.slabo27px(
        //         fontSize: 14.adaptiveSp,
        //         fontWeight: FontWeight.w600,
        //         color: colorScheme.primary,
        //       ),
        //     ),
        //   ),
      ],
    );
  }

  Widget _buildSubscriptionActiveCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 24.r,
          ),
          SizedBox(width: 12.w),
          AutoSizeText(
            'onboarding.subscription_active'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 16.adaptiveSp,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPackages(ColorScheme colorScheme) {
    if (_packages.isEmpty) {
      return Container(
        margin: EdgeInsets.only(bottom: 24.h),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              SizedBox(height: 16.h),
              AutoSizeText(
                'onboarding.loading_options'.tr(),
                style: GoogleFonts.slabo27px(
                  fontSize: 14.adaptiveSp,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(
            'onboarding.subscription_plans'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 18.adaptiveSp,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: 16.h),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1.0,
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey(_isTrialEnabled),
              children: [
                if (_isTrialEnabled)
                  _buildYearlyCard(colorScheme)
                else ...[
                  _buildWeeklyCard(colorScheme),
                  SizedBox(height: 12.h),
                  _buildMonthlyCard(colorScheme),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyCard(ColorScheme colorScheme) {
    // Find yearly package
    Package? yearlyPackage;
    for (var package in _packages) {
      if (package.packageType == PackageType.annual ||
          package.identifier.contains('yearly')) {
        yearlyPackage = package;
        break;
      }
    }

    if (yearlyPackage == null) return const SizedBox.shrink();

    return _buildProductCard(
      package: yearlyPackage,
      colorScheme: colorScheme,
      isSelected: _selectedPackageId == yearlyPackage.identifier,
      title: 'onboarding.yearly_plan'.tr(),
      description: 'onboarding.yearly_details'.tr(),
      isBestValue: true,
    );
  }

  Widget _buildMonthlyCard(ColorScheme colorScheme) {
    // Find monthly package
    Package? monthlyPackage;
    for (var package in _packages) {
      if (package.packageType == PackageType.monthly ||
          package.identifier.contains('monthly')) {
        monthlyPackage = package;
        break;
      }
    }

    if (monthlyPackage == null) return const SizedBox.shrink();

    return _buildProductCard(
      package: monthlyPackage,
      colorScheme: colorScheme,
      isSelected: _selectedPackageId == monthlyPackage.identifier,
      title: 'onboarding.monthly_plan'.tr(),
      description: 'onboarding.monthly_details'.tr(),
    );
  }

  Widget _buildWeeklyCard(ColorScheme colorScheme) {
    // Find weekly package
    Package? weeklyPackage;
    for (var package in _packages) {
      if (package.packageType == PackageType.weekly ||
          package.identifier.contains('weekly')) {
        weeklyPackage = package;
        break;
      }
    }

    if (weeklyPackage == null) return const SizedBox.shrink();

    return _buildProductCard(
      package: weeklyPackage,
      colorScheme: colorScheme,
      isSelected: _selectedPackageId == weeklyPackage.identifier,
      title: 'onboarding.weekly_plan'.tr(),
      description: 'onboarding.weekly_details'.tr(),
    );
  }

  Widget _buildProductCard({
    required Package package,
    required ColorScheme colorScheme,
    required bool isSelected,
    required String title,
    required String description,
    bool isBestValue = false,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPackageId = package.identifier;
          });
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isSelected ? colorScheme.primary : Colors.transparent,
                      border: isSelected
                          ? null
                          : Border.all(
                              color: colorScheme.outline.withOpacity(0.5)),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, color: Colors.white, size: 16.r)
                        : null,
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          title,
                          style: GoogleFonts.slabo27px(
                            fontSize: 16.adaptiveSp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        AutoSizeText(
                          description,
                          style: GoogleFonts.slabo27px(
                            fontSize: 12.adaptiveSp,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AutoSizeText(
                        package.storeProduct.priceString,
                        style: GoogleFonts.slabo27px(
                          fontSize: 16.adaptiveSp,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isBestValue)
              Positioned(
                top: -8.h,
                right: -8.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: AutoSizeText(
                    'onboarding.best_value'.tr(),
                    style: GoogleFonts.slabo27px(
                      color: Colors.white,
                      fontSize: 10.adaptiveSp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
