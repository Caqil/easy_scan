// Add this to your lib/ui/common/add_options.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scanpro/ui/widget/option_tile.dart';

/// A globally accessible component to show add/create options
class AddOptions {
  /// Show a modal bottom sheet with folder and document creation options
  static Future<void> showAddOptions(
    BuildContext context,
    WidgetRef ref, {
    required Function() onCreateSubfolder,
    required Function() onScanDocument,
    required Function() onImportDocuments,
    Function()? onMoveDocuments,
    String title = 'Add Content',
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddOptionsSheet(
        onCreateSubfolder: onCreateSubfolder,
        onScanDocument: onScanDocument,
        onImportDocuments: onImportDocuments,
        onMoveDocuments: onMoveDocuments,
        title: title,
      ),
    );
  }
}

class _AddOptionsSheet extends StatelessWidget {
  final String title;
  final Function() onCreateSubfolder;
  final Function() onScanDocument;
  final Function() onImportDocuments;
  final Function()? onMoveDocuments;

  const _AddOptionsSheet({
    required this.onCreateSubfolder,
    required this.onScanDocument,
    required this.onImportDocuments,
    this.onMoveDocuments,
    required this.title,
  });

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 2.h,
            width: 30.w,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Header with title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 30.w,
                  height: 30.h,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_circle_outline,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.slabo27px(
                      fontSize: 16.sp.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Action options
          OptionTile(
            icon: Icons.create_new_folder_outlined,
            title: 'add_options.create_subfolder.title'.tr(),
            description: 'add_options.create_subfolder.description'.tr(),
            onTap: () {
              Navigator.pop(context);
              onCreateSubfolder();
            },
          ),

          OptionTile(
            icon: Icons.document_scanner_outlined,
            title: 'add_options.scan_document.title'.tr(),
            description: 'add_options.scan_document.description'.tr(),
            onTap: () {
              Navigator.pop(context);
              onScanDocument();
            },
          ),

          OptionTile(
            icon: Icons.file_upload_outlined,
            title: 'add_options.import_documents.title'.tr(),
            description: 'add_options.import_documents.description'.tr(),
            onTap: () {
              Navigator.pop(context);
              onImportDocuments();
            },
          ),

          if (onMoveDocuments != null)
            OptionTile(
              icon: Icons.drive_file_move_outlined,
              title: 'add_options.move_documents_here.title'.tr(),
              description: 'add_options.move_documents_here.description'.tr(),
              onTap: () {
                Navigator.pop(context);
                onMoveDocuments!();
              },
            ),
          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
