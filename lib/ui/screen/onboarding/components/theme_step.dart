import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/providers/settings_provider.dart';

class ThemeStep extends ConsumerStatefulWidget {
  final VoidCallback onThemeSelected;

  const ThemeStep({
    super.key,
    required this.onThemeSelected,
  });

  @override
  ConsumerState<ThemeStep> createState() => _ThemeStepState();
}

class _ThemeStepState extends ConsumerState<ThemeStep> {
  bool? _darkModeSelected;

  @override
  void initState() {
    super.initState();
    // Get the current theme mode from settings
    final settings = ref.read(settingsProvider);
    _darkModeSelected = settings.darkMode;
  }

  void _selectLightTheme() {
    if (ref.read(settingsProvider).darkMode) {
      ref.read(settingsProvider.notifier).toggleDarkMode();
    }
    setState(() {
      _darkModeSelected = false;
    });
    widget.onThemeSelected();
  }

  void _selectDarkTheme() {
    if (!ref.read(settingsProvider).darkMode) {
      ref.read(settingsProvider.notifier).toggleDarkMode();
    }
    setState(() {
      _darkModeSelected = true;
    });
    widget.onThemeSelected();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20.h),
            AutoSizeText(
              'onboarding.theme_title'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 24.adaptiveSp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            AutoSizeText(
              'onboarding.theme_description'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 16.adaptiveSp,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.h),

            // Theme options
            Row(
              children: [
                // Light Theme Option
                Expanded(
                  child: _buildThemeCard(
                    title: 'onboarding.light_theme'.tr(),
                    icon: Icons.light_mode,
                    color: Colors.amber,
                    isSelected: _darkModeSelected == false,
                    onSelect: _selectLightTheme,
                    previewColor: Colors.white,
                  ),
                ),
                SizedBox(width: 16.w),
                // Dark Theme Option
                Expanded(
                  child: _buildThemeCard(
                    title: 'onboarding.dark_theme'.tr(),
                    icon: Icons.dark_mode,
                    color: Colors.indigo,
                    isSelected: _darkModeSelected == true,
                    onSelect: _selectDarkTheme,
                    previewColor: Colors.grey.shade900,
                  ),
                ),
              ],
            ),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onSelect,
    required Color previewColor,
  }) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        height: 180.h,
        decoration: BoxDecoration(
          color: previewColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 30.r,
              ),
            ),
            SizedBox(height: 16.h),
            AutoSizeText(
              title,
              style: GoogleFonts.slabo27px(
                fontSize: 16.adaptiveSp,
                fontWeight: FontWeight.bold,
                color:
                    previewColor == Colors.white ? Colors.black : Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            if (isSelected)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: AutoSizeText(
                  'onboarding.selected'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontSize: 12.adaptiveSp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
