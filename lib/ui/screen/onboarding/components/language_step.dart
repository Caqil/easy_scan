import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/models/language.dart';
import 'package:scanpro/providers/locale_provider.dart';
import 'package:lottie/lottie.dart';

class LanguageStep extends ConsumerStatefulWidget {
  final VoidCallback onLanguageSelected;

  const LanguageStep({
    Key? key,
    required this.onLanguageSelected,
  }) : super(key: key);

  @override
  ConsumerState<LanguageStep> createState() => _LanguageStepState();
}

class _LanguageStepState extends ConsumerState<LanguageStep>
    with SingleTickerProviderStateMixin {
  Language? _selectedLanguage;
  bool _isInitialized = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLanguages();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeLanguages() async {
    // Initialize languages from the locale provider
    await ref.read(localProvider.notifier).initializeLanguages(context);

    // Get current locale and set selected language
    final localState = ref.read(localProvider);
    final languages = localState.languages;

    if (languages.isNotEmpty) {
      final currentLocale = context.locale;
      final currentLanguage = languages.firstWhere(
        (lang) =>
            lang.languageCode == currentLocale.languageCode &&
            (lang.countryCode == currentLocale.countryCode ||
                lang.countryCode == null),
        orElse: () => languages.first,
      );

      setState(() {
        _selectedLanguage = currentLanguage;
        _isInitialized = true;
      });
    } else {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _selectLanguage(Language language) {
    setState(() {
      _selectedLanguage = language;
    });

    // Set the selected language in the app
    ref.read(localProvider.notifier).setLanguage(
          context,
          Locale(language.languageCode, language.countryCode),
        );

    // Notify parent that language is selected
    widget.onLanguageSelected();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localState = ref.watch(localProvider);
    final languages = localState.languages;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'onboarding.language_title'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'onboarding.language_description'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 14.sp,
                color: colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),

            // Animation or Illustration
            Center(
              child: FadeTransition(
                opacity: _animationController,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Curves.easeOut,
                  )),
                  child: Container(
                    height: 160.h,
                    child: Lottie.asset(
                      'assets/animations/language.json',
                      fit: BoxFit.contain,
                      // Fallback if the animation is not available
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.language,
                        size: 100.r,
                        color: colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 32.h),

            // Language selection heading
            Text(
              'onboarding.select_your_language'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 16.h),

            // Language selection list
            if (!_isInitialized || languages.isEmpty)
              Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              )
            else
              ...languages.map((language) {
                final isSelected =
                    _selectedLanguage?.languageCode == language.languageCode &&
                        _selectedLanguage?.countryCode == language.countryCode;
                return _buildLanguageCard(
                  language: language,
                  isSelected: isSelected,
                  onSelect: () => _selectLanguage(language),
                );
              }).toList(),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required Language language,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? colorScheme.primary.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
          child: Row(
            children: [
              // Language flag or icon
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: _getLanguageColor(language.languageCode)
                      .withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    language.languageCode.toUpperCase(),
                    style: GoogleFonts.slabo27px(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: _getLanguageColor(language.languageCode),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),

              // Language name
              Expanded(
                child: Text(
                  language.label,
                  style: GoogleFonts.slabo27px(
                    fontSize: 16.sp,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              ),

              // Selection indicator
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: isSelected
                    ? Container(
                        key: const ValueKey('selected'),
                        width: 26.w,
                        height: 26.w,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16.r,
                        ),
                      )
                    : Container(
                        key: const ValueKey('unselected'),
                        width: 26.w,
                        height: 26.w,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLanguageColor(String languageCode) {
    final Map<String, Color> languageColors = {
      'en': Colors.blue.shade700,
      'id': Colors.red.shade700,
      // Add more as needed
    };

    return languageColors[languageCode] ?? Colors.grey.shade700;
  }
}
