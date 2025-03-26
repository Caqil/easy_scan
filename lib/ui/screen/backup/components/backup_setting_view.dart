import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/models/backup_setting.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/models/backup_settings.dart';

class BackupSettingsView extends ConsumerWidget {
  final AsyncValue<BackupSettings> settings;
  final Function(BackupSettings) onSettingsChanged;

  const BackupSettingsView({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return settings.when(
      data: (data) => _buildSettings(context, data),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error loading settings: $error'),
      ),
    );
  }

  Widget _buildSettings(BuildContext context, BackupSettings settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auto backup section
          _buildSectionHeader(context, 'backup.auto_backup.title'.tr()),

          // Auto backup switch
          SwitchListTile(
            title: AutoSizeText('backup.auto_backup.enable'.tr()),
            subtitle: AutoSizeText('backup.auto_backup.description'.tr()),
            value: settings.autoBackupEnabled,
            onChanged: (value) {
              onSettingsChanged(settings.copyWith(autoBackupEnabled: value));
            },
          ),

          // Backup frequency (only visible if auto backup is enabled)
          if (settings.autoBackupEnabled) ...[
            _buildSectionHeader(context, 'backup.frequency.title'.tr()),

            // Radio buttons for frequency
            RadioListTile<BackupFrequency>(
              title: AutoSizeText('backup.frequency.daily'.tr()),
              value: BackupFrequency.daily,
              groupValue: settings.backupFrequency,
              onChanged: (value) {
                if (value != null) {
                  onSettingsChanged(settings.copyWith(backupFrequency: value));
                }
              },
            ),
            RadioListTile<BackupFrequency>(
              title: AutoSizeText('backup.frequency.weekly'.tr()),
              value: BackupFrequency.weekly,
              groupValue: settings.backupFrequency,
              onChanged: (value) {
                if (value != null) {
                  onSettingsChanged(settings.copyWith(backupFrequency: value));
                }
              },
            ),
            RadioListTile<BackupFrequency>(
              title: AutoSizeText('backup.frequency.monthly'.tr()),
              value: BackupFrequency.monthly,
              groupValue: settings.backupFrequency,
              onChanged: (value) {
                if (value != null) {
                  onSettingsChanged(settings.copyWith(backupFrequency: value));
                }
              },
            ),
          ],

          const Divider(height: 32),

          // Backup content section
          _buildSectionHeader(context, 'backup.content.title'.tr()),

          // Content options
          SwitchListTile(
            title: AutoSizeText('backup.content.documents'.tr()),
            subtitle: AutoSizeText('backup.content.documents_description'.tr()),
            value: settings.includeDocuments,
            onChanged: (value) {
              onSettingsChanged(settings.copyWith(includeDocuments: value));
            },
          ),
          SwitchListTile(
            title: AutoSizeText('backup.content.folders'.tr()),
            subtitle: AutoSizeText('backup.content.folders_description'.tr()),
            value: settings.includeFolders,
            onChanged: (value) {
              onSettingsChanged(settings.copyWith(includeFolders: value));
            },
          ),
          SwitchListTile(
            title: AutoSizeText('backup.content.settings'.tr()),
            subtitle: AutoSizeText('backup.content.settings_description'.tr()),
            value: settings.includeSettings,
            onChanged: (value) {
              onSettingsChanged(settings.copyWith(includeSettings: value));
            },
          ),

          const Divider(height: 32),

          // Storage options section
          _buildSectionHeader(context, 'backup.storage.title'.tr()),

          // Max local backups slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  'backup.storage.max_local_backups'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.adaptiveSp,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: settings.maxLocalBackups.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: settings.maxLocalBackups.toString(),
                        onChanged: (value) {
                          onSettingsChanged(
                            settings.copyWith(maxLocalBackups: value.toInt()),
                          );
                        },
                      ),
                    ),
                    SizedBox(
                      width: 40.w,
                      child: AutoSizeText(
                        settings.maxLocalBackups.toString(),
                        style: GoogleFonts.slabo27px(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.adaptiveSp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                AutoSizeText(
                  'backup.storage.max_backups_description'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.adaptiveSp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Help information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24.adaptiveSp,
                    ),
                    const SizedBox(width: 8),
                    AutoSizeText(
                      'backup.help.title'.tr(),
                      style: GoogleFonts.slabo27px(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.adaptiveSp,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AutoSizeText(
                  'backup.help.description'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.adaptiveSp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: AutoSizeText(
        title,
        style: GoogleFonts.slabo27px(
          fontSize: 16.adaptiveSp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
