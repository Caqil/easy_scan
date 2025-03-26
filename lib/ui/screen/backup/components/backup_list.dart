import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BackupListView extends StatelessWidget {
  final List<Map<String, dynamic>> backups;
  final bool isLoading;
  final VoidCallback onRefresh;
  final Function(String) onRestore;
  final Function(String) onDelete;
  final DateTime? lastBackupDate;

  const BackupListView({
    super.key,
    required this.backups,
    required this.isLoading,
    required this.onRefresh,
    required this.onRestore,
    required this.onDelete,
    this.lastBackupDate,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: Column(
        children: [
          // Last backup info
          _buildLastBackupInfo(context),

          // Backups list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : backups.isEmpty
                    ? _buildEmptyState(context)
                    : _buildBackupsList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLastBackupInfo(BuildContext context) {
    final formattedDate = lastBackupDate != null
        ? DateFormat.yMMMd().add_jm().format(lastBackupDate!)
        : 'backup.never'.tr();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history,
            color: Theme.of(context).colorScheme.primary,
            size: 24.adaptiveSp,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  'backup.last_backup'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.adaptiveSp,
                  ),
                ),
                AutoSizeText(
                  formattedDate,
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.adaptiveSp,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.backup,
            size: 64.adaptiveSp,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          AutoSizeText(
            'backup.no_backups_found'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 16.adaptiveSp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          AutoSizeText(
            'backup.create_first_backup'.tr(),
            style: GoogleFonts.slabo27px(
              fontWeight: FontWeight.w700,
              fontSize: 14.adaptiveSp,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBackupsList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: backups.length,
      itemBuilder: (context, index) {
        final backup = backups[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.backup,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: AutoSizeText(
              backup['name'],
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
                fontSize: 14.adaptiveSp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                AutoSizeText(
                  _formatDate(backup['date']),
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.adaptiveSp,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                AutoSizeText(
                  backup['size'] ?? 'Unknown size',
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.adaptiveSp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Restore button
                IconButton(
                  icon: const Icon(Icons.restore),
                  tooltip: 'backup.restore'.tr(),
                  onPressed: () => onRestore(backup['id']),
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'common.delete'.tr(),
                  onPressed: () => onDelete(backup['id']),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    try {
      if (dateStr == 'Unknown' || dateStr == 'Unknown date') {
        return 'backup.unknown_date'.tr();
      }

      final date = DateTime.parse(dateStr);
      return DateFormat.yMMMd().add_jm().format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
