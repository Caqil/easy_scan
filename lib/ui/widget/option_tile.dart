import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class OptionTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String description;
  final Color? textColor;
  final VoidCallback onTap;

  const OptionTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.description,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 30.w,
              height: 30.h,
              decoration: BoxDecoration(
                color: (iconColor ?? Theme.of(context).primaryColor)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.slabo27px(
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.slabo27px(
                      fontWeight: FontWeight.w700,
                      fontSize: 10.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
