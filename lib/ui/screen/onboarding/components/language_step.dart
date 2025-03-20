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

class _LanguageStepState extends ConsumerState<LanguageStep> {
  Language? _selectedLanguage;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLanguages();
    });
  }

  Future<void> _initializeLanguages() async {
    // Initialize languages from the locale provider
    await ref.read(localProvider.notifier).initializeLanguages(context);
    setState(() {
      _isInitialized = true;
    });
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
    final localState = ref.watch(localProvider);
    final languages = localState.languages;

    // Determine if a language is currently selected (from current locale)
    if (!_isInitialized && languages.isNotEmpty) {
      final currentLocale = context.locale;
      _selectedLanguage = languages.firstWhere(
        (lang) =>
            lang.languageCode == currentLocale.languageCode &&
            (lang.countryCode == currentLocale.countryCode ||
                lang.countryCode == null),
        orElse: () => languages.first,
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20.h),
            Text(
              'onboarding.language_title'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Text(
              'onboarding.language_description'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 16.sp,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),

            // Animation or Illustration
            Container(
              height: 150.h,
              width: double.infinity,
              child: Lottie.asset(
                'assets/animations/language.json',
                fit: BoxFit.contain,
                // Fallback if the animation is not available
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.language,
                  size: 100.r,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Language selection list
            if (languages.isEmpty)
              Center(
                child: CircularProgressIndicator(),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final language = languages[index];
                  final isSelected = _selectedLanguage?.languageCode ==
                          language.languageCode &&
                      _selectedLanguage?.countryCode == language.countryCode;

                  return _buildLanguageCard(
                    language: language,
                    isSelected: isSelected,
                    onSelect: () => _selectLanguage(language),
                  );
                },
              ),

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
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Row(
            children: [
              // Language flag or icon
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color:
                      _getLanguageColor(language.languageCode).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    language.languageCode.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
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
