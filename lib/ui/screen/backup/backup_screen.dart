import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/models/backup_setting.dart';
import 'package:scanpro/providers/backup_setting_provider.dart';
import 'package:scanpro/services/cloud_service.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/models/backup_settings.dart';
import 'package:scanpro/providers/backup_provider.dart';
import 'package:scanpro/ui/common/app_bar.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/utils/constants.dart';
import 'components/backup_progress_view.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BackupDestination _selectedDestination = BackupDestination.local;
  bool _isLoading = false;
  bool _isBackupInProgress = false;
  bool _isRestoreInProgress = false;
  double _progress = 0.0;
  String _progressMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBackupSettings();
    _refreshBackupsList();
  }

  Future<void> _loadBackupSettings() async {
    try {
      final backupState = ref.read(backupProvider);
      final settings = await ref.read(backupSettingsProvider.future);
      setState(() {
        _selectedDestination = settings.backupDestination;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _refreshBackupsList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(backupProvider.notifier)
          .loadAvailableBackups(_selectedDestination);
    } catch (e) {
      // Error will be shown through the provider
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleCreateBackup() async {
    setState(() {
      _isBackupInProgress = true;
      _progress = 0.0;
      _progressMessage = 'backup.creating_backup'.tr();
    });

    try {
      await ref.read(backupProvider.notifier).createBackup(
            destination: _selectedDestination,
            context: context,
            onProgress: (progress) {
              setState(() {
                _progress = progress;
                if (progress < 0.3) {
                  _progressMessage = 'backup.preparing_data'.tr();
                } else if (progress < 0.6) {
                  _progressMessage = 'backup.creating_archive'.tr();
                } else if (progress < 0.9) {
                  _progressMessage = 'backup.uploading'.tr();
                } else {
                  _progressMessage = 'backup.finalizing'.tr();
                }
              });
            },
          );

      // Refresh the backup list after creating a new backup
      if (mounted) {
        await _refreshBackupsList();
      }
    } catch (e) {
      // Error will be shown through the provider
    } finally {
      if (mounted) {
        setState(() {
          _isBackupInProgress = false;
        });
      }
    }
  }

  void _handleRestoreBackup(String backupId) async {
    // Confirm before restoring
    final shouldRestore = await AppDialogs.showConfirmDialog(
      context,
      title: 'backup.confirm_restore_title'.tr(),
      message: 'backup.confirm_restore_message'.tr(),
      confirmText: 'backup.restore'.tr(),
      cancelText: 'common.cancel'.tr(),
    );

    if (!shouldRestore) return;

    setState(() {
      _isRestoreInProgress = true;
      _progress = 0.0;
      _progressMessage = 'backup.restoring_backup'.tr();
    });

    try {
      await ref.read(backupProvider.notifier).restoreBackup(
            source: _selectedDestination,
            context: context,
            backupId: backupId,
            onProgress: (progress) {
              setState(() {
                _progress = progress;
                if (progress < 0.3) {
                  _progressMessage = 'backup.downloading'.tr();
                } else if (progress < 0.6) {
                  _progressMessage = 'backup.extracting'.tr();
                } else if (progress < 0.9) {
                  _progressMessage = 'backup.restoring_data'.tr();
                } else {
                  _progressMessage = 'backup.finalizing'.tr();
                }
              });
            },
          );
    } catch (e) {
      // Error will be shown through the provider
    } finally {
      if (mounted) {
        setState(() {
          _isRestoreInProgress = false;
        });
      }
    }
  }

  void _handleDeleteBackup(String backupId) async {
    // Confirm before deleting
    final shouldDelete = await AppDialogs.showConfirmDialog(
      context,
      title: 'backup.confirm_delete_title'.tr(),
      message: 'backup.confirm_delete_message'.tr(),
      confirmText: 'common.delete'.tr(),
      cancelText: 'common.cancel'.tr(),
      isDangerous: true,
    );

    if (!shouldDelete) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ref.read(cloudBackupServiceProvider).deleteBackup(
            _selectedDestination,
            backupId,
          );

      if (success && mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'backup.delete_success'.tr(),
          type: SnackBarType.success,
        );
        await _refreshBackupsList();
      } else if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'backup.delete_error'.tr(),
          type: SnackBarType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'backup.delete_error_with_details'
              .tr(namedArgs: {'error': e.toString()}),
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onDestinationChanged(BackupDestination destination) async {
    if (_selectedDestination == destination) return;

    // Check if the destination is available
    final isAvailable = await ref
        .read(cloudBackupServiceProvider)
        .isBackupServiceAvailable(destination);

    if (!isAvailable) {
      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'backup.destination_not_available'.tr(),
          type: SnackBarType.warning,
        );
      }
      return;
    }

    setState(() {
      _selectedDestination = destination;
    });

    // Update backup settings
    final settings = await ref.read(backupSettingsProvider.future);
    await ref.read(backupSettingsProvider.notifier).saveSettings(
          settings.copyWith(backupDestination: destination),
        );

    // Refresh the backup list for the new destination
    await _refreshBackupsList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backupState = ref.watch(backupProvider);

    // Show progress view during backup or restore operations
    if (_isBackupInProgress || _isRestoreInProgress) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isBackupInProgress
              ? 'backup.creating_backup_title'.tr()
              : 'backup.restoring_title'.tr()),
          automaticallyImplyLeading: false,
        ),
        body: BackupProgressView(
          progress: _progress,
          message: _progressMessage,
          isBackup: _isBackupInProgress,
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: Text('backup.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'backup.refresh'.tr(),
            onPressed: _refreshBackupsList,
          ),
        ],
      ),
      body: Column(
        children: [
          // Destination selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'backup.destination'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.adaptiveSp,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDestinationSelector(),
                ),
              ],
            ),
          ),

          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'backup.backups'.tr()),
              Tab(text: 'backup.settings'.tr()),
            ],
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Backups list tab
                BackupListView(
                  backups: backupState.availableBackups,
                  isLoading: _isLoading,
                  onRefresh: _refreshBackupsList,
                  onRestore: _handleRestoreBackup,
                  onDelete: _handleDeleteBackup,
                  lastBackupDate: backupState.lastBackupDate,
                ),

                // Settings tab
                BackupSettingsView(
                  settings: ref.watch(backupSettingsProvider),
                  onSettingsChanged: (settings) {
                    ref
                        .read(backupSettingsProvider.notifier)
                        .saveSettings(settings);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _handleCreateBackup,
              icon: const Icon(Icons.backup),
              label: Text('backup.create'.tr()),
            )
          : null,
    );
  }

  Widget _buildDestinationSelector() {
    return DropdownButtonFormField<BackupDestination>(
      value: _selectedDestination,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        DropdownMenuItem(
          value: BackupDestination.local,
          child: Row(
            children: [
              const Icon(Icons.folder),
              const SizedBox(width: 8),
              Text('backup.destination_local'.tr()),
            ],
          ),
        ),
        if (Platform.isIOS)
          DropdownMenuItem(
            value: BackupDestination.iCloud,
            child: Row(
              children: [
                const Icon(Icons.cloud),
                const SizedBox(width: 8),
                Text('backup.destination_icloud'.tr()),
              ],
            ),
          ),
        DropdownMenuItem(
          value: BackupDestination.googleDrive,
          child: Row(
            children: [
              const Icon(Icons.drive_folder_upload),
              const SizedBox(width: 8),
              Text('backup.destination_google_drive'.tr()),
            ],
          ),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          _onDestinationChanged(value);
        }
      },
    );
  }
}
