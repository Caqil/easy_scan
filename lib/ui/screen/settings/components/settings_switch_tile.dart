import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.symmetric(horizontal: 8.r, vertical: 4.r),
      secondary: Container(
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
    );
  }
}
