import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
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
  final VoidCallback onFavorite;
  final VoidCallback onMoreTools;

  const QuickActions({
    super.key,
    required this.onScan,
    required this.onFolders,
    required this.onOcr,
    required this.onUnlock,
    required this.onMerge,
    required this.onCompress,
    required this.onFavorite,
    required this.onMoreTools,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5.h),
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
              _buildActionItem(context, Icons.compress, 'compress_pdf'.tr(),
                  onCompress, Colors.red),
              _buildActionItem(context, Icons.merge_type,
                  'merge_pdf.title'.tr(), onMerge, Colors.purple),
              _buildActionItem(context, Icons.text_snippet,
                  'ocr.extract_text'.tr(), onOcr, Colors.green),
              _buildActionItem(context, Icons.lock_open,
                  'pdf.unlock.title'.tr(), onUnlock, Colors.orange),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionItem(context, Icons.qr_code_scanner, 'barcode'.tr(),
                  onScan, Colors.blue),
              _buildActionItem(context, Icons.favorite_border, 'favorite'.tr(),
                  onFavorite, Colors.pink),
              _buildActionItem(context, Icons.folder_open,
                  'folder_screen.folders_section'.tr(), onFolders, Colors.teal),
              _buildActionItem(context, Icons.more_horiz, 'view_all'.tr(),
                  onMoreTools, Colors.grey),
            ],
          ),
          SizedBox(height: 12.h),
          PremiumBanner(
            onTap: () => SubscriptionNavigator.openPremiumScreen(context),
          )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return AutoSizeText(
      'quick_actions'.tr(),
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 16.adaptiveSp,
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
          padding: EdgeInsets.symmetric(vertical: 2.h),
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
              AutoSizeText(
                label,
                style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.w500,
                  fontSize: 11.adaptiveSp,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
