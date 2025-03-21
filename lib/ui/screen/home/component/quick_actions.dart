import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scanpro/config/subscription_navigator.dart';
import 'package:scanpro/ui/screen/premium/components/premium_banner.dart';

class QuickActions extends ConsumerWidget {
  final VoidCallback onScan;
  final VoidCallback onFolders;
  final VoidCallback onFavorites;
  final VoidCallback onMerge;
  final VoidCallback onCompress;
  const QuickActions({
    super.key,
    required this.onScan,
    required this.onFolders,
    required this.onFavorites,
    required this.onMerge,
    required this.onCompress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 10.h),
          PremiumBanner(
            onTap: () {
              SubscriptionNavigator.openPremiumScreen(context);
            },
          ),
          SizedBox(height: 10.h),
          _buildActionGrid(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(left: 8.w),
      child: Text(
        'quick_actions'.tr(),
        style: GoogleFonts.slabo27px(
          fontWeight: FontWeight.w700,
          fontSize: 18.sp,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final actions = [
      _ActionItem(Icons.qr_code_scanner, 'barcode'.tr(), onScan),
      _ActionItem(Icons.merge_type, 'merge_pdf.title'.tr(), onMerge),
      _ActionItem(Icons.favorite_border, 'favorite'.tr(), onFavorites),
      _ActionItem(Icons.compress, 'compress_pdf'.tr(), onCompress),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: actions
              .sublist(0, 4)
              .map((action) => _buildActionButton(action, context))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActionButton(_ActionItem action, BuildContext context) {
    // Generate a unique color based on the icon's code
    final color =
        Colors.primaries[action.icon.codePoint % Colors.primaries.length];

    return GestureDetector(
      onTap: action.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Add ripple effect with InkWell inside a Material widget
          Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withOpacity(0.1),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(30.r),
                splashColor: color.withOpacity(0.2),
                highlightColor: color.withOpacity(0.1),
                onTap: action.onTap,
                child: SizedBox(
                  width: 60.w,
                  height: 50.h,
                  child: Icon(
                    action.icon,
                    size: 25.r,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            action.label,
            style: GoogleFonts.slabo27px(
              fontWeight: FontWeight.w700,
              fontSize: 10.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _ActionItem(this.icon, this.label, this.onTap);
}
