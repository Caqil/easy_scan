import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';

class RevenueCatSubscriptionOptions extends StatelessWidget {
  final List<Package> packages;
  final String? selectedPackageId;
  final bool isTrialEnabled;
  final VoidCallback onFreePlanSelected;
  final ValueChanged<String> onPackageSelected;

  const RevenueCatSubscriptionOptions({
    super.key,
    required this.packages,
    required this.selectedPackageId,
    required this.isTrialEnabled,
    required this.onFreePlanSelected,
    required this.onPackageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12.h),
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
            key: ValueKey('${packages.length}_$isTrialEnabled'),
            children: [
              if (packages.isNotEmpty)
                if (isTrialEnabled)
                  _buildYearlyOption()
                else ...[
                  _buildWeeklyOption(),
                  SizedBox(height: 12.h),
                  _buildMonthlyOption(),
                ],
              SizedBox(height: 12.h),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String subtitle,
    required String price,
    required bool selected,
    bool isBestValue = false,
    required VoidCallback onTap,
    bool showCheckbox = true,
    String? savingsText,
  }) {
    final context = WidgetsBinding
            .instance.focusManager.primaryFocus?.context ??
        WidgetsBinding.instance.focusManager.rootScope.focusedChild?.context;
    if (context == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 4.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).primaryColor.withOpacity(0.15)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor.withOpacity(0.5),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              spreadRadius: selected ? 2 : 1,
              blurRadius: selected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showCheckbox)
                  AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: selected ? 1.1 : 1.0,
                    child: Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).primaryColor
                              : Colors.grey.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16.r,
                            )
                          : null,
                    ),
                  ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: AutoSizeText(
                              title,
                              style: GoogleFonts.slabo27px(
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                          ),
                          if (savingsText != null) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 0, 255, 8),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: AutoSizeText(
                                savingsText,
                                style: GoogleFonts.slabo27px(
                                  color: Colors.green[700],
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4.h),
                      AutoSizeText(
                        subtitle,
                        style: GoogleFonts.slabo27px(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.7),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AutoSizeText(
                      price,
                      style: GoogleFonts.slabo13px(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (isBestValue)
              Positioned(
                top: -15.h,
                right: -16.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12.r),
                        topRight: Radius.circular(12.r)),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: AutoSizeText(
                    'subscription.most_popular'.tr(),
                    style: GoogleFonts.slabo27px(
                      color: Colors.white,
                      fontSize: 10.sp,
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

  Widget _buildYearlyOption() {
    // Find yearly package
    Package? yearlyPackage;
    for (var package in packages) {
      if (package.packageType == PackageType.annual ||
          package.identifier.contains('yearly')) {
        yearlyPackage = package;
        break;
      }
    }

    if (yearlyPackage == null) return const SizedBox.shrink();

    // Find monthly package for pricing comparison
    Package? monthlyPackage;
    for (var package in packages) {
      if (package.packageType == PackageType.monthly ||
          package.identifier.contains('monthly')) {
        monthlyPackage = package;
        break;
      }
    }

    String savingsText = '';
    if (monthlyPackage != null) {
      final yearlyPrice = yearlyPackage.storeProduct.price;
      final monthlyPrice = monthlyPackage.storeProduct.price;

      if (yearlyPrice < monthlyPrice * 12) {
        final savings =
            ((monthlyPrice * 12 - yearlyPrice) / (monthlyPrice * 12) * 100)
                .round();
        savingsText = 'Save $savings%';
      }
    }

    return _buildPlanCard(
      title: yearlyPackage.storeProduct.title,
      subtitle: yearlyPackage.storeProduct.description,
      price: yearlyPackage.storeProduct.priceString,
      selected: selectedPackageId == yearlyPackage.identifier,
      isBestValue: true,
      savingsText: savingsText,
      onTap: () => onPackageSelected(yearlyPackage!.identifier),
    );
  }

  Widget _buildMonthlyOption() {
    // Find monthly package
    Package? monthlyPackage;
    for (var package in packages) {
      if (package.packageType == PackageType.monthly ||
          package.identifier.contains('monthly')) {
        monthlyPackage = package;
        break;
      }
    }

    if (monthlyPackage == null) return const SizedBox.shrink();

    // Find weekly package for pricing comparison
    Package? weeklyPackage;
    for (var package in packages) {
      if (package.packageType == PackageType.weekly ||
          package.identifier.contains('weekly')) {
        weeklyPackage = package;
        break;
      }
    }

    String savingsText = '';
    if (weeklyPackage != null) {
      final monthlyPrice = monthlyPackage.storeProduct.price;
      final weeklyPrice = weeklyPackage.storeProduct.price;

      if (monthlyPrice < weeklyPrice * 4) {
        final savings =
            ((weeklyPrice * 4 - monthlyPrice) / (weeklyPrice * 4) * 100)
                .round();
        savingsText = 'Save $savings%';
      }
    }

    return _buildPlanCard(
      title: monthlyPackage.storeProduct.title,
      subtitle: monthlyPackage.storeProduct.description,
      price: monthlyPackage.storeProduct.priceString,
      selected: selectedPackageId == monthlyPackage.identifier,
      savingsText: savingsText,
      onTap: () => onPackageSelected(monthlyPackage!.identifier),
    );
  }

  Widget _buildWeeklyOption() {
    // Find weekly package
    Package? weeklyPackage;
    for (var package in packages) {
      if (package.packageType == PackageType.weekly ||
          package.identifier.contains('weekly')) {
        weeklyPackage = package;
        break;
      }
    }

    if (weeklyPackage == null) return const SizedBox.shrink();

    return _buildPlanCard(
      title: weeklyPackage.storeProduct.title,
      subtitle: weeklyPackage.storeProduct.description,
      price: weeklyPackage.storeProduct.priceString,
      selected: selectedPackageId == weeklyPackage.identifier,
      onTap: () => onPackageSelected(weeklyPackage!.identifier),
    );
  }
}
