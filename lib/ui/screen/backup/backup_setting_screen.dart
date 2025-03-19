import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scanpro/providers/backup_provider.dart';
import 'package:scanpro/services/backup_service.dart';
import 'package:scanpro/ui/screen/backup/backup_restore_screnn.dart';
import 'package:scanpro/ui/screen/backup/cloud_backup_screen.dart';
import 'package:scanpro/ui/screen/backup/components/backup_dialogs.dart';

class BackupSettingsSection extends ConsumerWidget {
  const BackupSettingsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupState = ref.watch(backupProvider);
    final lastBackupDate = backupState.lastBackupDate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'settings.backup_restore'.tr(),
            style: GoogleFonts.notoSerif(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),

        // Last backup info
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'backup.last_backup'.tr(),
                      style: GoogleFonts.notoSerif(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    lastBackupDate != null
                        ? DateFormat('MMM dd, yyyy HH:mm')
                            .format(lastBackupDate)
                        : 'backup.never'.tr(),
                    style: GoogleFonts.notoSerif(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                if (lastBackupDate != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      _getRelativeTime(lastBackupDate),
                      style: GoogleFonts.notoSerif(
                        color: _getTimeColor(lastBackupDate, context),
                        fontStyle: FontStyle.italic,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Quick backup button
        _buildSettingsItem(
          context: context,
          title: 'backup.quick_backup'.tr(),
          subtitle: 'backup.create_new_backup'.tr(),
          iconData: Icons.backup,
          onTap: () {
            BackupDialogs.showQuickBackupBottomSheet(context, ref);
          },
        ),

        // Backup & Restore
        _buildSettingsItem(
          context: context,
          title: 'backup.backup_restore'.tr(),
          subtitle: 'backup.manage_backups'.tr(),
          iconData: Icons.settings_backup_restore,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BackupRestoreScreen(),
              ),
            );
          },
        ),

        // Cloud specific backup options
        if (Platform.isIOS)
          _buildSettingsItem(
            context: context,
            title: 'iCloud ${'backup.backup'.tr()}',
            subtitle: 'backup.icloud_description'.tr(),
            iconData: Icons.cloud,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CloudBackupScreen(
                    backupDestination: BackupDestination.iCloud,
                  ),
                ),
              );
            },
          ),

        if (Platform.isAndroid || Platform.isIOS)
          _buildSettingsItem(
            context: context,
            title: 'Google Drive ${'backup.backup'.tr()}',
            subtitle: 'backup.gdrive_description'.tr(),
            iconData: Icons.drive_folder_upload,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CloudBackupScreen(
                    backupDestination: BackupDestination.googleDrive,
                  ),
                ),
              );
            },
          ),

        // Auto backup settings
        _buildSettingsItem(
          context: context,
          title: 'backup.auto_backup'.tr(),
          subtitle: 'backup.schedule_backups'.tr(),
          iconData: Icons.schedule,
          onTap: () {
            BackupDialogs.showAutoBackupSettingsDialog(context, ref);
          },
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSettingsItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData iconData,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          iconData,
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.notoSerif(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.notoSerif(
          fontSize: 12.sp,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return 'backup.backup_old'.tr();
    } else if (difference.inDays > 7) {
      return 'backup.backup_week_old'.tr();
    } else if (difference.inDays > 0) {
      return 'backup.backup_days'
          .tr(namedArgs: {'days': difference.inDays.toString()});
    } else if (difference.inHours > 0) {
      return 'backup.backup_hours'
          .tr(namedArgs: {'hours': difference.inHours.toString()});
    } else {
      return 'backup.backup_recent'.tr();
    }
  }

  Color _getTimeColor(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return Colors.red.shade700;
    } else if (difference.inDays > 7) {
      return Colors.orange.shade700;
    } else {
      return Colors.green.shade700;
    }
  }
}
