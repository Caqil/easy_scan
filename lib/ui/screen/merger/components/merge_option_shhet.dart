import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/config/routes.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/providers/document_provider.dart';
import 'package:scanpro/services/pdf_merger_service.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/ui/common/pdf_merger.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class MergeOptionsSheet extends ConsumerWidget {
  final Document? initialDocument;

  const MergeOptionsSheet({
    super.key,
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
                AutoSizeText(
                  'merge_pdf.title'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontSize: 18.adaptiveSp,
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
            title: AutoSizeText(
              'merge_pdf.open_tool'.tr(),
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: AutoSizeText(
              'merge_pdf.open_tool_desc'.tr(),
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
                fontSize: 12.adaptiveSp,
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
              title: AutoSizeText(
                'merge_pdf.append_to_pdf'.tr(),
                style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: AutoSizeText(
                'merge_pdf.append_to_pdf_desc'
                    .tr(namedArgs: {'name': initialDocument!.name}),
                style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.adaptiveSp,
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
            title: AutoSizeText(
              'merge_pdf.quick_merge'.tr(),
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: AutoSizeText(
              'merge_pdf.quick_merge_desc'.tr(),
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
                fontSize: 12.adaptiveSp,
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
    final allDocuments = ref.read(documentsProvider);
    final pdfMergerService = ref.read(pdfMergerServiceProvider);
    final pdfDocs = pdfMergerService
        .filterPdfDocuments(allDocuments)
        .where((doc) => doc.id != initialDocument.id)
        .toList();

    if (pdfDocs.isEmpty) {
      AppDialogs.showSnackBar(
        context,
        message: 'merge_pdf.no_pdfs_to_append'.tr(),
        type: SnackBarType.warning,
      );
      return;
    }

    final selectedDocs = <Document>[];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('merge_pdf.select_to_append'.tr()),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'merge_pdf.selected_document'
                      .tr(namedArgs: {'name': initialDocument.name}),
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'merge_pdf.choose_to_append'.tr(),
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
                        subtitle: Text('${doc.pageCount} pages'.tr()),
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
              child: Text('common.cancel'.tr()),
            ),
            TextButton(
              onPressed: selectedDocs.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context);
                      final docsToMerge = [initialDocument, ...selectedDocs];
                      final outputName = '${initialDocument.name}_appended';
                      PdfMerger.quickMergePdfs(
                        context,
                        ref,
                        docsToMerge,
                        outputName,
                      );
                    },
              child: Text('common.merge'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickMergeDialog(BuildContext context) {
    final allDocuments = ref.read(documentsProvider);
    final pdfMergerService = ref.read(pdfMergerServiceProvider);
    final pdfDocs = pdfMergerService.filterPdfDocuments(allDocuments);
    pdfDocs.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    final recentPdfs = pdfDocs.take(10).toList();

    if (recentPdfs.length < 2) {
      AppDialogs.showSnackBar(
        context,
        message: 'merge_pdf.min_pdfs_required'.tr(),
        type: SnackBarType.warning,
      );
      return;
    }

    final selectedDocs = <Document>[];
    final nameController = TextEditingController(
      text: 'Merged_${DateTime.now().toString().substring(0, 10)}',
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('merge_pdf.quick_merge_title'.tr()),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'merge_pdf.output_filename'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'merge_pdf.select_to_merge'.tr(),
                  style: GoogleFonts.slabo27px(
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
                        subtitle: Text('${doc.pageCount} pages'.tr()),
                        secondary: Text(
                          '${index + 1}',
                          style: GoogleFonts.slabo27px(
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
              child: Text('common.cancel'.tr()),
            ),
            TextButton(
              onPressed: selectedDocs.length < 2
                  ? null
                  : () {
                      Navigator.pop(context);
                      PdfMerger.quickMergePdfs(
                        context,
                        ref,
                        selectedDocs,
                        nameController.text.trim(),
                      );
                    },
              child: Text('common.merge'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
