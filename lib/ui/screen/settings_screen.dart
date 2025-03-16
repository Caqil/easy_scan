import 'package:easy_scan/models/app_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_scan/providers/settings_provider.dart';
import 'package:easy_scan/services/auth_service.dart';
import 'package:easy_scan/ui/common/app_bar.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:easy_scan/utils/permission_utils.dart';
import 'package:local_auth/local_auth.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isCheckingBiometrics = false;
  bool _biometricsAvailable = false;
  String? _biometricType;

  @override
  void initState() {
    super.initState();
    _checkBiometricCapabilities();
  }

  Future<void> _checkBiometricCapabilities() async {
    setState(() {
      _isCheckingBiometrics = true;
    });

    try {
      // Check if device supports biometric authentication
      final isAvailable = await _authService.isBiometricAvailable();
      final types = await _authService.getAvailableBiometrics();

      setState(() {
        _biometricsAvailable = isAvailable && types.isNotEmpty;

        // Determine biometric type for display purposes
        if (types.isNotEmpty) {
          if (types.contains(BiometricType.face)) {
            _biometricType = "Face ID";
          } else if (types.contains(BiometricType.fingerprint)) {
            _biometricType = "Fingerprint";
          } else if (types.contains(BiometricType.iris)) {
            _biometricType = "Iris";
          } else if (types.contains(BiometricType.strong)) {
            _biometricType = "Biometrics";
          } else {
            _biometricType = "Biometrics";
          }
        }
      });
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
      setState(() {
        _biometricsAvailable = false;
      });
    } finally {
      setState(() {
        _isCheckingBiometrics = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar:  CustomAppBar(
        title: Text('Settings',style: GoogleFonts.lilitaOne(fontSize: 25.sp),),
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
          _isCheckingBiometrics
              ? const ListTile(
                  title: Text('Checking biometric capabilities...'),
                  trailing: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _biometricsAvailable
                  ? _buildBiometricTile(settings, colorScheme)
                  : ListTile(
                      title: const Text('Biometric Authentication'),
                      subtitle: const Text(
                          'Requires fingerprint or face ID to access the app'),
                      trailing: Chip(
                        label: const Text('Not Available'),
                        backgroundColor: Colors.grey.withOpacity(0.2),
                        labelStyle:
                            GoogleFonts.notoSerif(color: Colors.grey.shade700),
                      ),
                      onTap: () {
                        AppDialogs.showSnackBar(
                          context,
                          message:
                              'Biometric authentication is not available on this device',
                          type: SnackBarType.warning,
                        );
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

  Widget _buildBiometricTile(AppSettings settings, ColorScheme colorScheme) {
    final IconData biometricIcon = _biometricType == "Face ID"
        ? Icons.face
        : (_biometricType == "Iris" ? Icons.remove_red_eye : Icons.fingerprint);

    return SwitchListTile(
      title: Row(
        children: [
          Text('$_biometricType Authentication'),
          const SizedBox(width: 8),
          Icon(
            biometricIcon,
            color: settings.biometricAuthEnabled
                ? colorScheme.primary
                : Colors.grey,
            size: 20,
          ),
        ],
      ),
      subtitle:
          Text('Require $_biometricType authentication when opening the app'),
      value: settings.biometricAuthEnabled,
      onChanged: (value) async {
        if (value) {
          // If turning on, test authentication first
          final authenticated = await _authService.authenticateWithBiometrics();
          if (authenticated) {
            ref.read(settingsProvider.notifier).toggleBiometricAuth();
            if (mounted) {
              AppDialogs.showSnackBar(
                context,
                type: SnackBarType.success,
                message: '$_biometricType authentication enabled',
              );
            }
          } else {
            if (mounted) {
              AppDialogs.showSnackBar(
                context,
                type: SnackBarType.error,
                message: 'Authentication failed. Please try again.',
              );
            }
          }
        } else {
          // If turning off, confirm with authentication first
          final authenticated = await _authService.authenticateWithBiometrics();
          if (authenticated) {
            ref.read(settingsProvider.notifier).toggleBiometricAuth();
            if (mounted) {
              AppDialogs.showSnackBar(
                context,
                type: SnackBarType.success,
                message: '$_biometricType authentication disabled',
              );
            }
          } else {
            if (mounted) {
              AppDialogs.showSnackBar(
                context,
                type: SnackBarType.error,
                message: 'Authentication failed. Setting was not changed.',
              );
            }
          }
        }
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({
    required this.title,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.notoSerif(
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
