import 'package:easy_scan/config/routes.dart';
import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/providers/document_provider.dart';
import 'package:easy_scan/services/pdf_merger_service.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:easy_scan/ui/common/pdf_merger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class MergeOptionsSheet extends ConsumerWidget {
  final Document? initialDocument;

  const MergeOptionsSheet({
    required this.ref,
    this.initialDocument,
  });

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.merge_type,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'PDF Merger',
                  style: GoogleFonts.notoSerif(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Options
          ListTile(
            leading: Icon(
              Icons.playlist_add,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Open PDF Merger Tool',
              style: GoogleFonts.notoSerif(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Full control over PDF selection and merging',
              style: GoogleFonts.notoSerif(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              AppRoutes.navigateToPdfMerger(context);
            },
          ),

          if (initialDocument != null)
            ListTile(
              leading: Icon(
                Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Append Documents to This PDF',
                style: GoogleFonts.notoSerif(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Add more PDFs to the end of "${initialDocument!.name}"',
                style: GoogleFonts.notoSerif(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.pop(context);
                _showAppendDialog(context, initialDocument!);
              },
            ),

          ListTile(
            leading: Icon(
              Icons.folder_zip,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Quick Merge Recent PDFs',
              style: GoogleFonts.notoSerif(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Quickly combine your recent PDF documents',
              style: GoogleFonts.notoSerif(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showQuickMergeDialog(context);
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAppendDialog(BuildContext context, Document initialDocument) {
    // Get PDF documents from provider
    final allDocuments = ref.read(documentsProvider);
    final pdfMergerService = ref.read(pdfMergerServiceProvider);
    final pdfDocs = pdfMergerService
        .filterPdfDocuments(allDocuments)
        .where((doc) => doc.id != initialDocument.id)
        .toList();

    if (pdfDocs.isEmpty) {
      AppDialogs.showSnackBar(
        context,
        message: 'No other PDF documents found to append',
        type: SnackBarType.warning,
      );
      return;
    }

    // Track selected documents
    final selectedDocs = <Document>[];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Select PDFs to Append'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected document: ${initialDocument.name}',
                  style: GoogleFonts.notoSerif(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose documents to append:',
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: pdfDocs.length,
                    itemBuilder: (context, index) {
                      final doc = pdfDocs[index];
                      final isSelected = selectedDocs.contains(doc);

                      return CheckboxListTile(
                        title: Text(
                          doc.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('${doc.pageCount} pages'),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value!) {
                              selectedDocs.add(doc);
                            } else {
                              selectedDocs.remove(doc);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selectedDocs.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context);

                      // Prepare documents in correct order
                      final docsToMerge = [initialDocument, ...selectedDocs];
                      final outputName = '${initialDocument.name}_appended';

                      // Perform merge
                      PdfMerger.quickMergePdfs(
                        context,
                        ref,
                        docsToMerge,
                        outputName,
                      );
                    },
              child: const Text('Merge'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickMergeDialog(BuildContext context) {
    // Get recent PDF documents
    final allDocuments = ref.read(documentsProvider);
    final pdfMergerService = ref.read(pdfMergerServiceProvider);
    final pdfDocs = pdfMergerService.filterPdfDocuments(allDocuments);

    // Sort by most recent first
    pdfDocs.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

    // Take only the recent ones (max 10)
    final recentPdfs = pdfDocs.take(10).toList();

    if (recentPdfs.length < 2) {
      AppDialogs.showSnackBar(
        context,
        message: 'Need at least 2 PDF documents to merge',
        type: SnackBarType.warning,
      );
      return;
    }

    // Track selected documents
    final selectedDocs = <Document>[];
    final nameController = TextEditingController(
      text: 'Merged_${DateTime.now().toString().substring(0, 10)}',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Quick Merge PDFs'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Output Filename',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select PDFs to merge:',
                  style: GoogleFonts.notoSerif(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: recentPdfs.length,
                    itemBuilder: (context, index) {
                      final doc = recentPdfs[index];
                      final isSelected = selectedDocs.contains(doc);

                      return CheckboxListTile(
                        title: Text(
                          doc.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('${doc.pageCount} pages'),
                        secondary: Text(
                          '${index + 1}',
                          style: GoogleFonts.notoSerif(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value!) {
                              selectedDocs.add(doc);
                            } else {
                              selectedDocs.remove(doc);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: selectedDocs.length < 2
                  ? null
                  : () {
                      Navigator.pop(context);

                      // Perform merge
                      PdfMerger.quickMergePdfs(
                        context,
                        ref,
                        selectedDocs,
                        nameController.text.trim(),
                      );
                    },
              child: const Text('Merge'),
            ),
          ],
        ),
      ),
    );
  }
}
