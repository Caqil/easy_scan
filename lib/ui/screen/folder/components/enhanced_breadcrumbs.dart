import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class EnhancedBreadcrumbs extends StatelessWidget {
  final List<String> breadcrumbs;
  final String? currentParentId;
  final Function(int) onBreadcrumbTap;
  final VoidCallback onNavigateUp;

  const EnhancedBreadcrumbs({
    Key? key,
    required this.breadcrumbs,
    this.currentParentId,
    required this.onBreadcrumbTap,
    required this.onNavigateUp,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
      margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Back button when not at root
            if (currentParentId != null) _buildBackButton(context),

            // Breadcrumb trail
            ..._buildBreadcrumbTrail(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onNavigateUp,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(8.w),
            child: Icon(
              Icons.arrow_back_ios_rounded,
              size: 16.sp,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade300
                  : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBreadcrumbTrail(BuildContext context) {
    List<Widget> items = [];
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    for (int i = 0; i < breadcrumbs.length; i++) {
      final isLast = i == breadcrumbs.length - 1;
      final isRoot = i == 0;

      items.add(
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(5.r),
          child: InkWell(
            onTap: isLast ? null : () => onBreadcrumbTap(i),
            borderRadius: BorderRadius.circular(5.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isLast
                    ? colorScheme.primary.withOpacity(0.1)
                    : (theme.brightness == Brightness.dark
                        ? Colors.grey.shade800.withOpacity(0.5)
                        : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isLast
                      ? colorScheme.primary.withOpacity(0.5)
                      : (theme.brightness == Brightness.dark
                          ? Colors.grey.shade700
                          : Colors.grey.shade200),
                ),
                boxShadow: isLast
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isRoot)
                    Icon(
                      Icons.home_rounded,
                      size: 16.sp,
                      color: isLast
                          ? colorScheme.primary
                          : (theme.brightness == Brightness.dark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700),
                    ),
                  if (isRoot) SizedBox(width: 6.w),
                  Text(
                    breadcrumbs[i],
                    style: GoogleFonts.notoSerif(
                      color: isLast
                          ? colorScheme.primary
                          : (theme.brightness == Brightness.dark
                              ? Colors.grey.shade300
                              : Colors.grey.shade800),
                      fontWeight: isLast ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      if (!isLast) {
        items.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 18.sp,
              color: theme.brightness == Brightness.dark
                  ? Colors.grey.shade500
                  : Colors.grey.shade400,
            ),
          ),
        );
      }
    }

    return items;
  }
}
