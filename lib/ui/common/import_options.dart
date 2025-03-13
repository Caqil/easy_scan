// Add this file to your project as lib/ui/common/import_options.dart

import 'package:flutter/material.dart';

/// A globally accessible class to show import options
class ImportOptions {
  /// Show import options bottom sheet with a modern UI
  static Future<void> showImportOptions(
    BuildContext context, {
    required Function() onImportFromGallery,
    required Function() onImportPdf,
    required Function() onImportFromCloud,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ImportOptionsSheet(
        onImportFromGallery: onImportFromGallery,
        onImportPdf: onImportPdf,
        onImportFromCloud: onImportFromCloud,
      ),
    );
  }
}

class _ImportOptionsSheet extends StatelessWidget {
  final Function() onImportFromGallery;
  final Function() onImportPdf;
  final Function() onImportFromCloud;

  const _ImportOptionsSheet({
    required this.onImportFromGallery,
    required this.onImportPdf,
    required this.onImportFromCloud,
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
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.file_upload_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import Document',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Choose an import method',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Import options
          _buildImportOption(
            context,
            icon: Icons.photo_library_outlined,
            title: 'Import from Gallery',
            subtitle: 'Select images to scan',
            onTap: () {
              Navigator.pop(context);
              onImportFromGallery();
            },
          ),

          _buildImportOption(
            context,
            icon: Icons.picture_as_pdf_outlined,
            title: 'Import PDF',
            subtitle: 'Select PDF files from your device',
            onTap: () {
              Navigator.pop(context);
              onImportPdf();
            },
          ),

          _buildImportOption(
            context,
            icon: Icons.cloud_download_outlined,
            title: 'Import from Cloud',
            subtitle: 'Import files from cloud storage',
            onTap: () {
              Navigator.pop(context);
              onImportFromCloud();
            },
          ),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildImportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
