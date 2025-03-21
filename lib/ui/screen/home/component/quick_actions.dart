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
  final VoidCallback onOcr;
  final VoidCallback onUnlock;
  final VoidCallback onMerge;
  final VoidCallback onCompress;

  const QuickActions({
    super.key,
    required this.onScan,
    required this.onFolders,
    required this.onOcr,
    required this.onUnlock,
    required this.onMerge,
    required this.onCompress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionItem(context, Icons.qr_code_scanner, 'barcode'.tr(),
                  onScan, Colors.blue),
              _buildActionItem(context, Icons.merge_type,
                  'merge_pdf.title'.tr(), onMerge, Colors.purple),
              _buildActionItem(context, Icons.text_snippet,
                  'ocr.extract_text'.tr(), onOcr, Colors.green),
              _buildActionItem(context, Icons.lock_open,
                  'pdf.unlock.title'.tr(), onUnlock, Colors.orange),
              _buildActionItem(context, Icons.compress, 'compress_pdf'.tr(),
                  onCompress, Colors.red),
            ],
          ),
          SizedBox(height: 8.h),
          PremiumBanner(
            onTap: () => SubscriptionNavigator.openPremiumScreen(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'quick_actions'.tr(),
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 16.sp,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
    Color color,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        splashColor: color.withOpacity(0.2),
        highlightColor: color.withOpacity(0.1),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24.r,
                  color: color,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 8.sp,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
