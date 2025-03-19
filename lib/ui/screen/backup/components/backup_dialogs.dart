import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scanpro/providers/backup_provider.dart';
import 'package:scanpro/services/backup_service.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/ui/screen/backup/backup_restore_screnn.dart';

class BackupDialogs {
  /// Show a quick backup bottom sheet dialog
  static Future<void> showQuickBackupBottomSheet(
      BuildContext context, WidgetRef ref) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickBackupBottomSheet(ref: ref),
    );
  }

  /// Show auto backup options dialog
  static Future<void> showAutoBackupSettingsDialog(
      BuildContext context, WidgetRef ref) async {
    return showDialog(
      context: context,
      builder: (context) => _AutoBackupSettingsDialog(ref: ref),
    );
  }

  /// Show backup success dialog with details
  static Future<void> showBackupSuccessDialog(
    BuildContext context,
    String message,
    BackupDestination destination,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => _BackupResultDialog(
        message: message,
        isSuccess: true,
        destination: destination,
      ),
    );
  }

  /// Show backup error dialog with details
  static Future<void> showBackupErrorDialog(
    BuildContext context,
    String message,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => _BackupResultDialog(
        message: message,
        isSuccess: false,
        destination: null,
      ),
    );
  }

  /// Show a quick option to navigate to backup screen
  static Future<void> showBackupPrompt(BuildContext context) async {
    return AppDialogs.showSnackBar(
      context,
      message: 'backup.dont_forget_backup'.tr(),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'backup.backup_now'.tr(),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const BackupRestoreScreen(),
            ),
          );
        },
        textColor: Colors.white,
      ),
    );
  }
}

/// Bottom sheet for quick backup options
class _QuickBackupBottomSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _QuickBackupBottomSheet({required this.ref});

  @override
  ConsumerState<_QuickBackupBottomSheet> createState() =>
      _QuickBackupBottomSheetState();
}

class _QuickBackupBottomSheetState
    extends ConsumerState<_QuickBackupBottomSheet> {
  BackupDestination _selectedDestination = BackupDestination.local;
  bool _isBackingUp = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    _selectedDestination = BackupDestination.googleDrive;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.backup,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'backup.quick_backup'.tr(),
                    style: GoogleFonts.notoSerif(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'backup.quick_backup_description'.tr(),
                style: GoogleFonts.notoSerif(
                  color: Colors.grey.shade700,
                  fontSize: 14.sp,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'backup.destination'.tr(),
                style: GoogleFonts.notoSerif(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              const SizedBox(height: 8),
              _buildDestinationOptions(),
              const SizedBox(height: 16),
              if (_isBackingUp)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.grey.shade200,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'backup.creating_backup'.tr(),
                      style: GoogleFonts.notoSerif(
                        color: Theme.of(context).primaryColor,
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      '${(_progress * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.notoSerif(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12.sp,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isBackingUp ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('common.cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isBackingUp ? null : _createBackup,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('backup.backup_now'.tr()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _isBackingUp
                      ? null
                      : () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BackupRestoreScreen(),
                            ),
                          );
                        },
                  child: Text('backup.advanced_options'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationOptions() {
    final isIOS = Platform.isIOS;
    final isAndroid = Platform.isAndroid;

    return Column(
      children: [
        if (isAndroid || isIOS)
          _buildDestinationOption(
            title: 'Google Drive',
            icon: Icons.drive_folder_upload,
            destination: BackupDestination.googleDrive,
          ),
        _buildDestinationOption(
          title: 'backup.local_storage'.tr(),
          icon: Icons.smartphone,
          destination: BackupDestination.local,
        ),
      ],
    );
  }

  Widget _buildDestinationOption({
    required String title,
    required IconData icon,
    required BackupDestination destination,
  }) {
    final isSelected = _selectedDestination == destination;

    return InkWell(
      onTap: _isBackingUp
          ? null
          : () {
              setState(() {
                _selectedDestination = destination;
              });
            },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.notoSerif(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
              ),
            ),
            Radio<BackupDestination>(
              value: destination,
              groupValue: _selectedDestination,
              onChanged: _isBackingUp
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          _selectedDestination = value;
                        });
                      }
                    },
              activeColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBackup() async {
    // Check if platform is supported
    final notifier = ref.read(backupProvider.notifier);
    if (!notifier.isPlatformSupported(_selectedDestination)) {
      AppDialogs.showSnackBar(
        context,
        message: 'backup.platform_not_supported'.tr(),
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _isBackingUp = true;
      _progress = 0.0;
    });

    try {
      final backupService = ref.read(backupServiceProvider);

      final result = await backupService.createBackup(
        destination: _selectedDestination,
        context: context,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );

      if (mounted) {
        // Close bottom sheet
        Navigator.pop(context);

        // Show success dialog
        BackupDialogs.showBackupSuccessDialog(
          context,
          result,
          _selectedDestination,
        );

        // Update last backup date
        ref
            .read(backupProvider.notifier)
            .loadAvailableBackups(_selectedDestination);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
        });

        // Show error message
        AppDialogs.showSnackBar(
          context,
          message: 'Error: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }
}

/// Dialog for auto backup settings
class _AutoBackupSettingsDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _AutoBackupSettingsDialog({required this.ref});

  @override
  ConsumerState<_AutoBackupSettingsDialog> createState() =>
      _AutoBackupSettingsDialogState();
}

class _AutoBackupSettingsDialogState
    extends ConsumerState<_AutoBackupSettingsDialog> {
  bool _autoBackupEnabled = false;
  String _autoBackupFrequency = 'weekly';
  BackupDestination _autoBackupDestination = BackupDestination.local;

  @override
  void initState() {
    super.initState();

    // Load settings (in a real app, you'd load these from shared preferences)
    // For now, we'll use placeholder values
    _autoBackupEnabled = false;
    _autoBackupFrequency = 'weekly';
    _autoBackupDestination = BackupDestination.googleDrive;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('backup.auto_backup_settings'.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text(
                'backup.enable_auto_backup'.tr(),
                style: GoogleFonts.notoSerif(),
              ),
              value: _autoBackupEnabled,
              onChanged: (value) {
                setState(() {
                  _autoBackupEnabled = value;
                });
              },
              activeColor: Theme.of(context).primaryColor,
            ),
            const Divider(),
            if (_autoBackupEnabled) ...[
              Text(
                'backup.backup_frequency'.tr(),
                style: GoogleFonts.notoSerif(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                title: Text('backup.daily'.tr()),
                value: 'daily',
                groupValue: _autoBackupFrequency,
                onChanged: (value) {
                  setState(() {
                    _autoBackupFrequency = value!;
                  });
                },
                activeColor: Theme.of(context).primaryColor,
              ),
              RadioListTile<String>(
                title: Text('backup.weekly'.tr()),
                value: 'weekly',
                groupValue: _autoBackupFrequency,
                onChanged: (value) {
                  setState(() {
                    _autoBackupFrequency = value!;
                  });
                },
                activeColor: Theme.of(context).primaryColor,
              ),
              RadioListTile<String>(
                title: Text('backup.monthly'.tr()),
                value: 'monthly',
                groupValue: _autoBackupFrequency,
                onChanged: (value) {
                  setState(() {
                    _autoBackupFrequency = value!;
                  });
                },
                activeColor: Theme.of(context).primaryColor,
              ),
              const Divider(),
              Text(
                'backup.destination'.tr(),
                style: GoogleFonts.notoSerif(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildDestinationOptions(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('common.cancel'.tr()),
        ),
        TextButton(
          onPressed: _saveSettings,
          child: Text('common.save'.tr()),
        ),
      ],
    );
  }

  Widget _buildDestinationOptions() {
    final isIOS = Platform.isIOS;
    final isAndroid = Platform.isAndroid;

    return Column(
      children: [
        if (isAndroid || isIOS)
          RadioListTile<BackupDestination>(
            title: const Text('Google Drive'),
            value: BackupDestination.googleDrive,
            groupValue: _autoBackupDestination,
            onChanged: (value) {
              setState(() {
                _autoBackupDestination = value!;
              });
            },
            activeColor: Theme.of(context).primaryColor,
          ),
        RadioListTile<BackupDestination>(
          title: Text('backup.local_storage'.tr()),
          value: BackupDestination.local,
          groupValue: _autoBackupDestination,
          onChanged: (value) {
            setState(() {
              _autoBackupDestination = value!;
            });
          },
          activeColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }

  void _saveSettings() {
    // In a real app, you'd save these settings to shared preferences
    // For now, we'll just close the dialog

    // Example of what you'd do:
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setBool('auto_backup_enabled', _autoBackupEnabled);
    // await prefs.setString('auto_backup_frequency', _autoBackupFrequency);
    // await prefs.setString('auto_backup_destination', _autoBackupDestination.toString());

    Navigator.pop(context);

    if (_autoBackupEnabled) {
      AppDialogs.showSnackBar(
        context,
        message: 'backup.auto_backup_enabled'.tr(),
        type: SnackBarType.success,
      );
    }
  }
}

/// Dialog for showing backup results
class _BackupResultDialog extends StatelessWidget {
  final String message;
  final bool isSuccess;
  final BackupDestination? destination;

  const _BackupResultDialog({
    required this.message,
    required this.isSuccess,
    this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        isSuccess ? 'backup.success'.tr() : 'backup.error'.tr(),
        style: GoogleFonts.notoSerif(
          color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.notoSerif(),
            textAlign: TextAlign.center,
          ),
          if (isSuccess && destination != null) ...[
            const SizedBox(height: 16),
            Text(
              _getDestinationMessage(),
              style: GoogleFonts.notoSerif(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('common.close'.tr()),
        ),
        if (isSuccess)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BackupRestoreScreen(),
                ),
              );
            },
            child: Text('backup.view_backups'.tr()),
          ),
      ],
    );
  }

  String _getDestinationMessage() {
    switch (destination) {
      case BackupDestination.googleDrive:
        return 'backup.saved_to_gdrive'.tr();
      case BackupDestination.local:
        return 'backup.saved_to_local'.tr();
      default:
        return '';
    }
  }
}
