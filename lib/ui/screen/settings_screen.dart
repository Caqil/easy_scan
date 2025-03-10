import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_scan/providers/settings_provider.dart';
import 'package:easy_scan/services/auth_service.dart';
import 'package:easy_scan/services/storage_service.dart';
import 'package:easy_scan/ui/common/app_bar.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:easy_scan/utils/permission_utils.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final authService = AuthService();
    final storageService = StorageService();

    return Scaffold(
      appBar: const CustomAppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          // Appearance section
          const _SectionHeader(title: 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme throughout the app'),
            value: settings.darkMode,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).toggleDarkMode();
            },
          ),

          // Security section
          const _SectionHeader(title: 'Security'),
          SwitchListTile(
            title: const Text('Biometric Authentication'),
            subtitle: const Text('Require fingerprint or face ID to open app'),
            value: settings.biometricAuthEnabled,
            onChanged: (value) async {
              final biometricAvailable =
                  await authService.isBiometricAvailable();

              if (biometricAvailable) {
                final authenticated =
                    await authService.authenticateWithBiometrics();
                if (authenticated) {
                  ref.read(settingsProvider.notifier).toggleBiometricAuth();
                }
              } else {
                // ignore: use_build_context_synchronously
                AppDialogs.showSnackBar(
                  context,
                  message:
                      'Biometric authentication not available on this device',
                );
              }
            },
          ),
          ListTile(
            title: const Text('Document Passwords'),
            subtitle: const Text('Manage default password settings'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Show password settings
            },
          ),

          // Scan settings section
          const _SectionHeader(title: 'Scan Settings'),
          SwitchListTile(
            title: const Text('Auto Enhance'),
            subtitle: const Text('Automatically improve scanned documents'),
            value: settings.autoEnhanceImages,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).toggleAutoEnhanceImages();
            },
          ),
          ListTile(
            title: const Text('Default PDF Quality'),
            subtitle: Text('${settings.defaultPdfQuality}%'),
            trailing: SizedBox(
              width: 150,
              child: Slider(
                value: settings.defaultPdfQuality.toDouble(),
                min: 30,
                max: 100,
                divisions: 7,
                onChanged: (value) {
                  ref
                      .read(settingsProvider.notifier)
                      .setDefaultPdfQuality(value.round());
                },
              ),
            ),
          ),
          ListTile(
            title: const Text('Default Save Location'),
            subtitle: Text(settings.defaultSaveLocation == 'local'
                ? 'Device Storage'
                : 'Cloud Storage'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showSaveLocationDialog(
                  context, ref, settings.defaultSaveLocation);
            },
          ),

          // Storage section
          const _SectionHeader(title: 'Storage'),
          FutureBuilder<double>(
            future: storageService.getAvailableStorage(),
            builder: (context, snapshot) {
              final available = snapshot.data ?? 0;
              return ListTile(
                title: const Text('Available Storage'),
                subtitle: Text('${available.toStringAsFixed(1)} MB'),
                leading: const Icon(Icons.storage),
              );
            },
          ),
          ListTile(
            title: const Text('Clear Temporary Files'),
            subtitle: const Text('Free up space by removing cache'),
            leading: const Icon(Icons.cleaning_services),
            onTap: () async {
              final confirmed = await AppDialogs.showConfirmDialog(
                context,
                title: 'Clear Temporary Files',
                message:
                    'This will delete all temporary files. This action cannot be undone.',
                confirmText: 'Clear',
              );

              if (confirmed) {
                await storageService.clearTempFiles();
                // ignore: use_build_context_synchronously
                AppDialogs.showSnackBar(
                  context,
                  message: 'Temporary files cleared successfully',
                );
              }
            },
          ),
          SwitchListTile(
            title: const Text('Cloud Backup'),
            subtitle: const Text('Automatically backup documents to cloud'),
            value: settings.cloudBackupEnabled,
            secondary: const Icon(Icons.cloud_upload),
            onChanged: (value) {
              ref.read(settingsProvider.notifier).toggleCloudBackup();
            },
          ),

          // Permissions section
          const _SectionHeader(title: 'Permissions'),
          FutureBuilder<bool>(
            future: PermissionUtils.hasCameraPermission(),
            builder: (context, snapshot) {
              final hasPermission = snapshot.data ?? false;
              return ListTile(
                title: const Text('Camera Permission'),
                subtitle: Text(hasPermission ? 'Granted' : 'Not granted'),
                leading: const Icon(Icons.camera_alt),
                trailing: hasPermission
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : TextButton(
                        onPressed: () async {
                          final granted =
                              await PermissionUtils.requestCameraPermission();
                          if (!granted) {
                            // ignore: use_build_context_synchronously
                            final openSettings =
                                await AppDialogs.showConfirmDialog(
                              context,
                              title: 'Permission Required',
                              message:
                                  'Camera permission is needed. Open app settings?',
                              confirmText: 'Open Settings',
                            );

                            if (openSettings) {
                              PermissionUtils.openAppSettings();
                            }
                          }
                        },
                        child: const Text('Request'),
                      ),
              );
            },
          ),
          FutureBuilder<bool>(
            future: PermissionUtils.hasStoragePermissions(),
            builder: (context, snapshot) {
              final hasPermission = snapshot.data ?? false;
              return ListTile(
                title: const Text('Storage Permission'),
                subtitle: Text(hasPermission ? 'Granted' : 'Not granted'),
                leading: const Icon(Icons.folder),
                trailing: hasPermission
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : TextButton(
                        onPressed: () async {
                          final granted =
                              await PermissionUtils.requestStoragePermissions();
                          if (!granted) {
                            // ignore: use_build_context_synchronously
                            final openSettings =
                                await AppDialogs.showConfirmDialog(
                              context,
                              title: 'Permission Required',
                              message:
                                  'Storage permission is needed. Open app settings?',
                              confirmText: 'Open Settings',
                            );

                            if (openSettings) {
                              PermissionUtils.openAppSettings();
                            }
                          }
                        },
                        child: const Text('Request'),
                      ),
              );
            },
          ),

          // About section
          const _SectionHeader(title: 'About'),
          ListTile(
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
            leading: const Icon(Icons.info),
          ),
          ListTile(
            title: const Text('Terms of Service'),
            leading: const Icon(Icons.description),
            onTap: () {
              // TODO: Open terms of service
            },
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            leading: const Icon(Icons.privacy_tip),
            onTap: () {
              // TODO: Open privacy policy
            },
          ),
          ListTile(
            title: const Text('Send Feedback'),
            leading: const Icon(Icons.feedback),
            onTap: () {
              // TODO: Open feedback form
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showSaveLocationDialog(
      BuildContext context, WidgetRef ref, String currentLocation) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Default Save Location'),
        children: [
          RadioListTile<String>(
            title: const Text('Device Storage'),
            value: 'local',
            groupValue: currentLocation,
            onChanged: (value) {
              ref
                  .read(settingsProvider.notifier)
                  .setDefaultSaveLocation(value!);
              Navigator.pop(context);
            },
          ),
          RadioListTile<String>(
            title: const Text('Cloud Storage'),
            value: 'cloud',
            groupValue: currentLocation,
            onChanged: (value) {
              ref
                  .read(settingsProvider.notifier)
                  .setDefaultSaveLocation(value!);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
