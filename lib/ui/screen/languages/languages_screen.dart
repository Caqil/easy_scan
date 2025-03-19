import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/models/language.dart';
import 'package:scanpro/providers/locale_provider.dart';
import 'package:scanpro/ui/common/app_bar.dart';
import 'package:scanpro/ui/screen/languages/components/language_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/ui/screen/languages/components/language_tile.dart';

class LanguagesScreen extends ConsumerStatefulWidget {
  const LanguagesScreen({super.key});

  @override
  ConsumerState<LanguagesScreen> createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends ConsumerState<LanguagesScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localProvider.notifier).initializeLanguages(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localState = ref.watch(localProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: Text("settings.language".tr()),
        centerTitle: false,
      ),
      body: localState.languages.isEmpty
          ? _buildLoadingState()
          : _buildLanguageList(context, localState),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            "settings.loading_languages".tr(),
            style: GoogleFonts.slabo27px(
              fontWeight: FontWeight.w700,
              fontSize: 16.sp,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageList(BuildContext context, LocalState localState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info card for current language
        Padding(
          padding: EdgeInsets.all(16.r),
          child: Card(
            elevation: 0,
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24.r,
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "settings.current_language".tr(),
                          style: GoogleFonts.slabo27px(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _getCurrentLanguageName(
                              context.locale, localState.languages),
                          style: GoogleFonts.slabo27px(
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Heading for available languages
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 8.r),
          child: Text(
            "settings.available_languages".tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ),

        Divider(height: 1),

        // Language list with visual improvements
        Expanded(
          child: ListView.builder(
            itemCount: localState.languages.length,
            itemBuilder: (context, index) {
              final language = localState.languages[index];
              final isSelected =
                  context.locale.languageCode == language.languageCode &&
                      (context.locale.countryCode == language.countryCode ||
                          language.countryCode == null);

              return LanguageTile(
                language: language,
                isSelected: isSelected,
                onTap: () => _changeLanguage(language),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getCurrentLanguageName(Locale locale, List<Language> languages) {
    try {
      final currentLanguage = languages.firstWhere(
        (lang) =>
            lang.languageCode == locale.languageCode &&
            (lang.countryCode == locale.countryCode),
        orElse: () => Language(
          label: "Unknown (${locale.languageCode}_${locale.countryCode})",
          languageCode: locale.languageCode,
          countryCode: locale.countryCode ?? "",
        ),
      );
      return currentLanguage.label;
    } catch (e) {
      return "Unknown";
    }
  }

  void _changeLanguage(Language language) {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Directly set the language without showing a dialog or delay
    try {
      ref.read(localProvider.notifier).setLanguage(
            context,
            Locale(language.languageCode, language.countryCode),
          );

      // Simple success message instead of dialogs and navigation
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Language changed to ${language.label}"),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      // Show error if something went wrong
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error changing language"),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
