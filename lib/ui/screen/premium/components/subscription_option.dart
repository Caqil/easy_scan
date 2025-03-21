import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionOptionsWidget extends StatefulWidget {
  final List<ProductDetails> products;
  final String? selectedProductId;
  final bool isTrialEnabled;
  final VoidCallback onFreePlanSelected;
  final ValueChanged<String> onProductSelected;

  const SubscriptionOptionsWidget({
    Key? key,
    required this.products,
    required this.selectedProductId,
    required this.isTrialEnabled,
    required this.onFreePlanSelected,
    required this.onProductSelected,
  }) : super(key: key);

  @override
  State<SubscriptionOptionsWidget> createState() =>
      _SubscriptionOptionsWidgetState();
}

class _SubscriptionOptionsWidgetState extends State<SubscriptionOptionsWidget> {
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
            key: ValueKey('${widget.products.length}_${widget.isTrialEnabled}'),
            children: [
              if (widget.products.isNotEmpty)
                if (widget.isTrialEnabled)
                  _buildYearlyOption()
                else ...[
                  _buildWeeklyOption(),
                  SizedBox(height: 12.h),
                  _buildMonthlyOption(),
                ],
              SizedBox(height: 12.h),
            ],
          ),
        ),
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
    // ... same as previous implementation
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
                            child: Text(
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
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
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
                      Text(
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
                    Text(
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
                  child: Text(
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
    ProductDetails? yearlyProduct;
    for (var product in widget.products) {
      if (product.id == 'scanpro_premium_yearly') {
        yearlyProduct = product;
        break;
      }
    }

    if (yearlyProduct == null) return const SizedBox.shrink();

    final monthlyProduct = widget.products.firstWhere(
      (p) => p.id == 'scanpro_premium_monthly',
    );
    final yearlyPrice = double.tryParse(
            yearlyProduct.price.replaceAll(RegExp(r'[^\d.]'), '')) ??
        0;
    final monthlyPrice = double.tryParse(
            monthlyProduct.price.replaceAll(RegExp(r'[^\d.]'), '')) ??
        0;
    final savings =
        ((monthlyPrice * 12 - yearlyPrice) / (monthlyPrice * 12) * 100).round();

    return _buildPlanCard(
      title: yearlyProduct.title,
      subtitle: yearlyProduct.description,
      price: yearlyProduct.price,
      selected: widget.selectedProductId == yearlyProduct.id,
      isBestValue: true,
      savingsText: 'Save $savings%',
      onTap: () => widget.onProductSelected(yearlyProduct!.id),
    );
  }

  Widget _buildMonthlyOption() {
    ProductDetails? monthlyProduct;
    for (var product in widget.products) {
      if (product.id == 'scanpro_premium_monthly') {
        monthlyProduct = product;
        break;
      }
    }

    if (monthlyProduct == null) return const SizedBox.shrink();

    final weeklyProduct = widget.products.firstWhere(
      (p) => p.id == 'scanpro_premium_weekly',
    );
    final monthlyPrice = double.tryParse(
            monthlyProduct.price.replaceAll(RegExp(r'[^\d.]'), '')) ??
        0;
    final weeklyPrice = double.tryParse(
            weeklyProduct.price.replaceAll(RegExp(r'[^\d.]'), '')) ??
        0;
    final savings =
        ((weeklyPrice * 4 - monthlyPrice) / (weeklyPrice * 4) * 100).round();

    return _buildPlanCard(
      title: monthlyProduct.title,
      subtitle: monthlyProduct.description,
      price: monthlyProduct.price,
      selected: widget.selectedProductId == monthlyProduct.id,
      savingsText: 'Save $savings%',
      onTap: () => widget.onProductSelected(monthlyProduct!.id),
    );
  }

  Widget _buildWeeklyOption() {
    ProductDetails? weeklyProduct;
    for (var product in widget.products) {
      if (product.id == 'scanpro_premium_weekly') {
        weeklyProduct = product;
        break;
      }
    }

    if (weeklyProduct == null) return const SizedBox.shrink();

    return _buildPlanCard(
      title: weeklyProduct.title.replaceAll('ScanPro', ''),
      subtitle: weeklyProduct.description,
      price: weeklyProduct.price,
      selected: widget.selectedProductId == weeklyProduct.id,
      onTap: () => widget.onProductSelected(weeklyProduct!.id),
    );
  }
}
