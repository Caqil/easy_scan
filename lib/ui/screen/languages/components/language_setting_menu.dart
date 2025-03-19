import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/config/routes.dart';
import 'package:scanpro/providers/locale_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsLanguageMenu extends ConsumerWidget {
  const SettingsLanguageMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localState = ref.watch(localProvider);

    // Get the current language's label
    String currentLanguageLabel = "English";
    if (localState.languages.isNotEmpty) {
      try {
        final currentLang = localState.languages.firstWhere(
          (lang) =>
              lang.languageCode == context.locale.languageCode &&
              (lang.countryCode == context.locale.countryCode),
          orElse: () => localState.languages.first,
        );
        currentLanguageLabel = currentLang.label;
      } catch (e) {
        // Default to English if something goes wrong
      }
    }

    return ListTile(
      leading: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          Icons.language,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        "settings.language".tr(),
        style: GoogleFonts.notoSerif(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        currentLanguageLabel,
        style: GoogleFonts.notoSerif(
          fontSize: 14.sp,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16.r,
        color: Colors.grey.shade400,
      ),
      onTap: () {
        context.push(AppRoutes.languages);
      },
    );
  }
}
