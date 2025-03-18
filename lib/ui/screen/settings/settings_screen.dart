import 'package:easy_localization/easy_localization.dart';
import 'package:easy_scan/config/routes.dart';
import 'package:easy_scan/providers/locale_provider.dart';
import 'package:easy_scan/providers/settings_provider.dart';
import 'package:easy_scan/ui/common/app_bar.dart';
import 'package:easy_scan/ui/screen/settings/components/app_header.dart';
import 'package:easy_scan/ui/screen/settings/components/settings_card.dart';
import 'package:easy_scan/ui/screen/settings/components/settings_divider.dart';
import 'package:easy_scan/ui/screen/settings/components/settings_section_header.dart';
import 'package:easy_scan/ui/screen/settings/components/settings_switch_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'components/settings_navigation_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final localState = ref.watch(localProvider);

    // Get the current language's label
    String currentLanguageLabel = "English";
    if (localState.languages.isNotEmpty) {
      try {
        final currentLang = localState.languages.firstWhere(
          (lang) =>
              lang.languageCode == context.locale.languageCode &&
              (lang.countryCode == context.locale.countryCode ||
                  lang.countryCode == null),
          orElse: () => localState.languages.first,
        );
        currentLanguageLabel = currentLang.label;
      } catch (e) {
        // Default to English if something goes wrong
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: Text("settings.title".tr()),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App info header
            AppHeaderWidget(
              appName: "ScanPro",
              version: "Version 1.0.0",
              icon: Icons.document_scanner,
            ),

            SizedBox(height: 16.h),

            // Appearance settings
            SettingsSectionHeader(title: "settings.appearance".tr()),
            SettingsCard(
              children: [
                // Dark Mode Toggle
                SettingsSwitchTile(
                  icon: settings.darkMode ? Icons.dark_mode : Icons.light_mode,
                  iconColor: Colors.indigo,
                  title: "settings.dark_mode".tr(),
                  subtitle: settings.darkMode
                      ? "settings.dark_mode_on".tr()
                      : "settings.dark_mode_off".tr(),
                  value: settings.darkMode,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleDarkMode();
                  },
                ),

                SettingsDivider(),

                // Language selection
                SettingsNavigationTile(
                  icon: Icons.language,
                  iconColor: Colors.green,
                  title: "settings.language".tr(),
                  subtitle: currentLanguageLabel,
                  onTap: () => context.push(AppRoutes.languages),
                ),
              ],
            ),

            // Security settings
            SettingsSectionHeader(title: "settings.security".tr()),
            SettingsCard(
              children: [
                // Biometric Auth
                SettingsSwitchTile(
                  icon: Icons.fingerprint,
                  iconColor: Colors.red,
                  title: "settings.biometric_auth".tr(),
                  subtitle: settings.biometricAuthEnabled
                      ? "settings.biometric_auth_on".tr()
                      : "settings.biometric_auth_off".tr(),
                  value: settings.biometricAuthEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleBiometricAuth();
                  },
                ),

                SettingsDivider(),

                // Auto-lock
                SettingsNavigationTile(
                  icon: Icons.lock_clock,
                  iconColor: Colors.orange,
                  title: "settings.auto_lock".tr(),
                  subtitle: "settings.auto_lock_desc".tr(),
                  onTap: () {
                    // Navigate to auto-lock settings
                  },
                ),
              ],
            ),

            // Document settings
            SettingsSectionHeader(title: "settings.document_settings".tr()),
            SettingsCard(
              children: [
                // Default PDF Quality
                SettingsNavigationTile(
                  icon: Icons.picture_as_pdf,
                  iconColor: Colors.red,
                  title: "settings.default_pdf_quality".tr(),
                  subtitle: "${settings.defaultPdfQuality}%",
                  onTap: () {
                    _showQualitySelector(
                        context, ref, settings.defaultPdfQuality);
                  },
                ),

                SettingsDivider(),

                // Auto Enhance Images
                SettingsSwitchTile(
                  icon: Icons.auto_awesome,
                  iconColor: Colors.amber,
                  title: "settings.auto_enhance".tr(),
                  subtitle: "settings.auto_enhance_desc".tr(),
                  value: settings.autoEnhanceImages,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .toggleAutoEnhanceImages();
                  },
                ),

                SettingsDivider(),

                // Default Save Location
                SettingsNavigationTile(
                  icon: Icons.folder,
                  iconColor: Colors.blue,
                  title: "settings.default_save_location".tr(),
                  subtitle: settings.defaultSaveLocation.isEmpty
                      ? "settings.default_location".tr()
                      : settings.defaultSaveLocation,
                  onTap: () {
                    // Show folder picker
                  },
                ),
              ],
            ),

            // Backup & Cloud Settings
            SettingsSectionHeader(title: "settings.backup_cloud".tr()),
            SettingsCard(
              children: [
                // Cloud Backup Toggle
                SettingsSwitchTile(
                  icon: Icons.cloud_upload,
                  iconColor: Colors.cyan,
                  title: "settings.cloud_backup".tr(),
                  subtitle: settings.cloudBackupEnabled
                      ? "settings.cloud_backup_on".tr()
                      : "settings.cloud_backup_off".tr(),
                  value: settings.cloudBackupEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleCloudBackup();
                  },
                ),

                SettingsDivider(),

                // Backup Now
                SettingsNavigationTile(
                  icon: Icons.backup,
                  iconColor: Colors.teal,
                  title: "settings.backup_now".tr(),
                  subtitle: "settings.backup_now_desc".tr(),
                  onTap: () {
                    // Trigger backup
                  },
                ),

                SettingsDivider(),

                // Restore from Backup
                SettingsNavigationTile(
                  icon: Icons.restore,
                  iconColor: Colors.deepPurple,
                  title: "settings.restore".tr(),
                  subtitle: "settings.restore_desc".tr(),
                  onTap: () {
                    // Show restore options
                  },
                ),
              ],
            ),

            // About & Help
            SettingsSectionHeader(title: "settings.about_help".tr()),
            SettingsCard(
              children: [
                // Help & Support
                SettingsNavigationTile(
                  icon: Icons.help_outline,
                  iconColor: Colors.blue,
                  title: "settings.help_support".tr(),
                  subtitle: "settings.help_support_desc".tr(),
                  onTap: () {
                    // Navigate to help page
                  },
                ),

                SettingsDivider(),

                // Privacy Policy
                SettingsNavigationTile(
                  icon: Icons.privacy_tip_outlined,
                  iconColor: Colors.grey,
                  title: "settings.privacy_policy".tr(),
                  subtitle: "settings.privacy_policy_desc".tr(),
                  onTap: () {
                    // Open privacy policy
                  },
                ),

                SettingsDivider(),

                // About
                SettingsNavigationTile(
                  icon: Icons.info_outline,
                  iconColor: Colors.grey,
                  title: "settings.about".tr(),
                  subtitle: "settings.about_desc".tr(),
                  onTap: () {
                    // Show about dialog
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),

            SizedBox(height: 32.h), // Bottom padding
          ],
        ),
      ),
    );
  }

  void _showQualitySelector(
      BuildContext context, WidgetRef ref, int currentQuality) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          int selectedQuality = currentQuality;

          return Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "settings.pdf_quality".tr(),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "settings.pdf_quality_desc".tr(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Lower Quality",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      "Higher Quality",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: selectedQuality.toDouble(),
                  min: 30,
                  max: 100,
                  divisions: 7,
                  label: "$selectedQuality%",
                  onChanged: (value) {
                    setState(() {
                      selectedQuality = value.round();
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$selectedQuality%",
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.r),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text("common.cancel".tr()),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          ref
                              .read(settingsProvider.notifier)
                              .setDefaultPdfQuality(selectedQuality);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.r),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text("common.save".tr()),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("About Easy Scan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Easy Scan is a document scanning app that allows you to scan, organize, and manage your documents easily.",
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              "Version: 1.0.0",
              style: TextStyle(fontSize: 14.sp),
            ),
            Text(
              "Build: 2023.03.25",
              style: TextStyle(fontSize: 14.sp),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }
}
