import 'package:easy_localization/easy_localization.dart';
import 'package:easy_scan/config/routes.dart';
import 'package:easy_scan/models/app_settings.dart';
import 'package:easy_scan/providers/locale_provider.dart';
import 'package:easy_scan/providers/settings_provider.dart';
import 'package:easy_scan/services/auth_service.dart';
import 'package:easy_scan/ui/common/app_bar.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
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

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isBiometricAvailable = false;
  bool _isCloudAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _checkCloudAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _authService.isBiometricAvailable();
    if (mounted) {
      setState(() {
        _isBiometricAvailable = isAvailable;
      });
    }
  }

  Future<void> _checkCloudAvailability() async {
    // This would check if cloud services are available
    // For now, we'll assume they are
    setState(() {
      _isCloudAvailable = true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              appName: "Easy Scan",
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
                    subtitle: _isBiometricAvailable
                        ? (settings.biometricAuthEnabled
                            ? "settings.biometric_auth_on".tr()
                            : "settings.biometric_auth_off".tr())
                        : "settings.biometric_not_available".tr(),
                    value:
                        _isBiometricAvailable && settings.biometricAuthEnabled,
                    onChanged: (value) async {
                      if (value) {
                        // When enabling, verify biometrics first
                        final authenticated =
                            await _authService.authenticateWithBiometrics();
                        if (authenticated) {
                          ref
                              .read(settingsProvider.notifier)
                              .toggleBiometricAuth();
                        } else {
                          if (mounted) {
                            AppDialogs.showSnackBar(context,
                                message:
                                    "settings.biometric_verification_failed"
                                        .tr(),
                                type: SnackBarType.error);
                          }
                        }
                      } else {
                        // Just disable without verification
                        ref
                            .read(settingsProvider.notifier)
                            .toggleBiometricAuth();
                      }
                    }),

                SettingsDivider(),

                // Auto-lock
                SettingsNavigationTile(
                  icon: Icons.lock_clock,
                  iconColor: Colors.orange,
                  title: "settings.auto_lock".tr(),
                  subtitle: "settings.auto_lock_desc".tr(),
                  onTap: () {
                    _showAutoLockOptions(context, ref);
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
                    _showSaveLocationPicker(context, ref, settings);
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
                  subtitle: _isCloudAvailable
                      ? (settings.cloudBackupEnabled
                          ? "settings.cloud_backup_on".tr()
                          : "settings.cloud_backup_off".tr())
                      : "settings.cloud_not_available".tr(),
                  value: _isCloudAvailable && settings.cloudBackupEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleCloudBackup();
                    if (value) {
                      _showCloudServiceSelector(context);
                    }
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
                    settings.cloudBackupEnabled && _isCloudAvailable
                        ? _performBackup(context)
                        : null;
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
                    settings.cloudBackupEnabled && _isCloudAvailable
                        ? () {
                            _showRestoreConfirmation(context);
                          }
                        : null;
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
                    _showHelpOptions(context);
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
                    _showPrivacyPolicy(context);
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

  void _showAutoLockOptions(BuildContext context, WidgetRef ref) {
    // This would show options for auto-lock timing
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "settings.auto_lock".tr(),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            _buildAutoLockOption(
                context, "settings.auto_lock_immediate".tr(), 0),
            _buildAutoLockOption(
                context, "settings.auto_lock_1_minute".tr(), 1),
            _buildAutoLockOption(
                context, "settings.auto_lock_5_minutes".tr(), 5),
            _buildAutoLockOption(context, "settings.auto_lock_never".tr(), -1),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoLockOption(BuildContext context, String title, int minutes) {
    return ListTile(
      title: Text(title),
      onTap: () {
        // Would save the auto-lock setting
        Navigator.pop(context);
        AppDialogs.showSnackBar(context,
            message: "settings.auto_lock_set".tr(), type: SnackBarType.success);
      },
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

                          AppDialogs.showSnackBar(context,
                              message: "settings.quality_saved".tr(),
                              type: SnackBarType.success);
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

  void _showSaveLocationPicker(
      BuildContext context, WidgetRef ref, AppSettings settings) {
    // Show a folder picker dialog
    // For now, we'll just show some options
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "settings.select_save_location".tr(),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            ListTile(
              leading: Icon(Icons.folder),
              title: Text("Documents"),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(settingsProvider.notifier)
                    .setDefaultSaveLocation("Documents");
                AppDialogs.showSnackBar(context,
                    message: "settings.save_location_set".tr(),
                    type: SnackBarType.success);
              },
            ),
            ListTile(
              leading: Icon(Icons.folder),
              title: Text("Easy Scan"),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(settingsProvider.notifier)
                    .setDefaultSaveLocation("Easy Scan");
                AppDialogs.showSnackBar(context,
                    message: "settings.save_location_set".tr(),
                    type: SnackBarType.success);
              },
            ),
            ListTile(
              leading: Icon(Icons.create_new_folder_outlined),
              title: Text("settings.create_new_folder".tr()),
              onTap: () {
                Navigator.pop(context);
                _showNewFolderDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNewFolderDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("settings.create_new_folder".tr()),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "settings.folder_name".tr(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("common.cancel".tr()),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                ref
                    .read(settingsProvider.notifier)
                    .setDefaultSaveLocation(controller.text);
                AppDialogs.showSnackBar(context,
                    message: "settings.folder_created".tr(),
                    type: SnackBarType.success);
              }
            },
            child: Text("common.create".tr()),
          ),
        ],
      ),
    );
  }

  void _showCloudServiceSelector(BuildContext context) {
    // Would show available cloud services
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "settings.select_cloud_service".tr(),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            ListTile(
              leading: Icon(Icons.cloud, color: Colors.blue),
              title: Text("Google Drive"),
              onTap: () {
                Navigator.pop(context);
                AppDialogs.showSnackBar(context,
                    message: "Connected to Google Drive",
                    type: SnackBarType.success);
              },
            ),
            ListTile(
              leading: Icon(Icons.cloud, color: Colors.lightBlue),
              title: Text("Dropbox"),
              onTap: () {
                Navigator.pop(context);
                AppDialogs.showSnackBar(context,
                    message: "Connected to Dropbox",
                    type: SnackBarType.success);
              },
            ),
            ListTile(
              leading: Icon(Icons.cloud, color: Colors.grey),
              title: Text("OneDrive"),
              onTap: () {
                Navigator.pop(context);
                AppDialogs.showSnackBar(context,
                    message: "Connected to OneDrive",
                    type: SnackBarType.success);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _performBackup(BuildContext context) {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16.h),
            Text("settings.backing_up".tr()),
          ],
        ),
      ),
    );

    // Simulate backup
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pop(context); // Close dialog
      AppDialogs.showSnackBar(context,
          message: "settings.backup_complete".tr(), type: SnackBarType.success);
    });
  }

  void _showRestoreConfirmation(BuildContext context) {
    AppDialogs.showConfirmDialog(
      context,
      title: "settings.restore_confirm_title".tr(),
      message: "settings.restore_confirm_message".tr(),
      confirmText: "settings.restore".tr(),
      cancelText: "common.cancel".tr(),
    ).then((confirmed) {
      if (confirmed) {
        _performRestore(context);
      }
    });
  }

  void _performRestore(BuildContext context) {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16.h),
            Text("settings.restoring".tr()),
          ],
        ),
      ),
    );

    // Simulate restore
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pop(context); // Close dialog
      AppDialogs.showSnackBar(context,
          message: "settings.restore_complete".tr(),
          type: SnackBarType.success);
    });
  }

  void _showHelpOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "settings.help_support".tr(),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text("settings.faqs".tr()),
              onTap: () {
                Navigator.pop(context);
                // Navigate to FAQs
              },
            ),
            ListTile(
              leading: Icon(Icons.email_outlined),
              title: Text("settings.contact_support".tr()),
              onTap: () {
                Navigator.pop(context);
                // Open email client
              },
            ),
            ListTile(
              leading: Icon(Icons.description_outlined),
              title: Text("settings.user_guide".tr()),
              onTap: () {
                Navigator.pop(context);
                // Open user guide
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("settings.privacy_policy".tr()),
        content: SingleChildScrollView(
          child: Text(
            "This is a placeholder for the privacy policy. In a real app, this would contain your actual privacy policy text.",
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("common.close".tr()),
          ),
        ],
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
