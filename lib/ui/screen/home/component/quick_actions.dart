import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuickActions extends ConsumerWidget {
  final VoidCallback onScan;
  final VoidCallback onImport;
  final VoidCallback onFolders;
  final VoidCallback onFavorites;
  final VoidCallback onMerge;
  final VoidCallback onCompress;

  const QuickActions({
    super.key,
    required this.onScan,
    required this.onImport,
    required this.onFolders,
    required this.onFavorites,
    required this.onMerge,
    required this.onCompress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(16.w),
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 20.h),
          _buildActionGrid(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.only(left: 8.w),
      child: Text(
        'Quick Actions',
        style: GoogleFonts.notoSans(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    final actions = [
      _ActionItem(Icons.qr_code_scanner, 'Scan Code', onScan),
      _ActionItem(Icons.merge_type, 'Merge PDF', onMerge),
      _ActionItem(Icons.lock, 'Protect PDF', onImport),
      _ActionItem(Icons.compress, 'Compress PDF', onCompress),
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
                child: Container(
                  width: 50.w,
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
            style: GoogleFonts.notoSans(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              height: 1.2,
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
