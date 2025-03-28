import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsNavigationTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const SettingsNavigationTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 4.r),
      leading: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24.r,
        ),
      ),
      title: AutoSizeText(
        title,
        style: GoogleFonts.slabo27px(
          fontWeight: FontWeight.w700,
          fontSize: 14.adaptiveSp,
        ),
      ),
      subtitle: AutoSizeText(
        subtitle,
        style: GoogleFonts.slabo27px(
          fontWeight: FontWeight.w700,
          fontSize: 12.adaptiveSp,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: 16.r,
            color: Colors.grey.shade400,
          ),
      onTap: onTap,
    );
  }
}
