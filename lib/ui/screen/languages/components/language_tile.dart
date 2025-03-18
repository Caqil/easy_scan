import 'package:easy_scan/models/language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class LanguageTile extends StatelessWidget {
  final Language language;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageTile({
    Key? key,
    required this.language,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2)
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 6.r),
          child: Row(
            children: [
              // Country flag (optional feature)
              _buildLanguageIcon(language.languageCode),
              SizedBox(width: 16.w),

              // Language name
              Expanded(
                child: Text(
                  language.label,
                  style: GoogleFonts.notoSerif(
                    fontSize: 14.sp,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ),

              // Selection indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24.r,
                )
              else
                Icon(
                  Icons.circle_outlined,
                  color: Colors.grey.shade400,
                  size: 24.r,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageIcon(String languageCode) {
    // You could replace this with actual flag icons if desired
    final Map<String, IconData> languageIcons = {
      'en': Icons.language,
      'id': Icons.language,
      // Add more as needed
    };

    final Map<String, Color> languageColors = {
      'en': Colors.blue.shade700,
      'id': Colors.red.shade700,
      // Add more as needed
    };

    return Container(
      width: 40.r,
      height: 40.r,
      decoration: BoxDecoration(
        color: (languageColors[languageCode] ?? Colors.grey.shade700)
            .withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          languageCode.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: languageColors[languageCode] ?? Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
