import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/providers/document_provider.dart';
import 'package:scanpro/services/pdf_merger_service.dart';
import 'package:scanpro/ui/common/app_bar.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_tooltip/super_tooltip.dart';

class PdfMergerScreen extends ConsumerStatefulWidget {
  const PdfMergerScreen({super.key});

  @override
  ConsumerState<PdfMergerScreen> createState() => _PdfMergerScreenState();
}

class _PdfMergerScreenState extends ConsumerState<PdfMergerScreen> {
  final TextEditingController _outputNameController = TextEditingController(
      text: 'Merged_${DateTime.now().toString().substring(0, 10)}');
  final List<Document> _selectedDocuments = [];
  bool _isProcessing = false;
  bool _isShowingLibraryDocs = true;
  final _controller = SuperTooltipController();

  @override
  void dispose() {
    _outputNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final allDocuments = ref.watch(documentsProvider);
    final pdfMergerService = ref.read(pdfMergerServiceProvider);
    final pdfDocuments = pdfMergerService.filterPdfDocuments(allDocuments);

    pdfDocuments.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

    return Scaffold(
      appBar: CustomAppBar(
        title: AutoSizeText('merge_pdf.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'merge_pdf.help'.tr(),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _outputNameController,
                  decoration: InputDecoration(
                    labelText: 'merge_pdf.output_filename'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.merge_type),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: true,
                      label: AutoSizeText('merge_pdf.from_library'.tr()),
                      icon: const Icon(Icons.folder),
                    ),
                    ButtonSegment(
                      value: false,
                      label: AutoSizeText('merge_pdf.from_device'.tr()),
                      icon: const Icon(Icons.drive_folder_upload),
                    ),
                  ],
                  selected: {_isShowingLibraryDocs},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _isShowingLibraryDocs = selection.first;
                      _selectedDocuments.clear();
                    });
                  },
                ),
              ),
              if (_selectedDocuments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              AutoSizeText(
                                'merge_pdf.selected_pdfs'.tr(namedArgs: {
                                  'count': _selectedDocuments.length.toString()
                                }),
                                style: GoogleFonts.slabo27px(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 2),
                              GestureDetector(
                                onTap: () async {
                                  await _controller.showTooltip();
                                },
                                child: SuperTooltip(
                                  showBarrier: true,
                                  controller: _controller,
                                  content: AutoSizeText(
                                    'merge_pdf.merge_order_tip'.tr(),
                                    softWrap: true,
                                    style: GoogleFonts.slabo27px(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.clear),
                            label: AutoSizeText('merge_pdf.clear'.tr()),
                            onPressed: () {
                              setState(() {
                                _selectedDocuments.clear();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              if (_isShowingLibraryDocs)
                Expanded(
                  child: pdfDocuments.isEmpty
                      ? _buildEmptyLibraryView()
                      : _buildLibraryDocsGrid(pdfDocuments),
                )
              else
                Expanded(
                  child: _selectedDocuments.isEmpty
                      ? _buildAddExternalDocsView()
                      : _buildSelectedDocsList(),
                ),
              if (_selectedDocuments.isNotEmpty) _buildMergeButton(colorScheme),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      floatingActionButton: !_isShowingLibraryDocs
          ? FloatingActionButton(
              onPressed: _pickExternalPdfs,
              tooltip: 'merge_pdf.add_pdfs'.tr(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildEmptyLibraryView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.picture_as_pdf,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          AutoSizeText(
            'merge_pdf.no_pdfs_in_library'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 16.adaptiveSp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          AutoSizeText(
            'merge_pdf.import_or_switch'.tr(),
            style: GoogleFonts.slabo27px(
              fontWeight: FontWeight.w700,
              fontSize: 14.adaptiveSp,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAddExternalDocsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.file_upload_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          AutoSizeText(
            'merge_pdf.select_pdfs_to_merge'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 16.adaptiveSp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          AutoSizeText(
            'merge_pdf.tap_to_select'.tr(),
            style: GoogleFonts.slabo27px(
              fontWeight: FontWeight.w700,
              fontSize: 14.adaptiveSp,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _pickExternalPdfs,
            icon: const Icon(Icons.add),
            label: AutoSizeText('merge_pdf.select_pdfs'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryDocsGrid(List<Document> documents) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        final isSelected = _selectedDocuments.contains(document);
        final selectedIndex =
            isSelected ? _selectedDocuments.indexOf(document) : -1;

        return InkWell(
          onTap: () => _toggleDocumentSelection(document),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3)
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(11),
                          topRight: Radius.circular(11),
                        ),
                        child: document.thumbnailPath != null
                            ? Image.file(
                                File(document.thumbnailPath!),
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.picture_as_pdf,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      if (isSelected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(11),
                                topRight: Radius.circular(11),
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AutoSizeText(
                                        '${selectedIndex + 1}',
                                        style: GoogleFonts.slabo27px(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      AutoSizeText(
                                        'merge_pdf.order'.tr(),
                                        style: GoogleFonts.slabo27px(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        document.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.slabo27px(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.adaptiveSp,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AutoSizeText(
                        '${document.pageCount} pages'.tr(),
                        style: GoogleFonts.slabo27px(
                          fontWeight: FontWeight.w700,
                          fontSize: 10.adaptiveSp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      AutoSizeText(
                        DateTimeUtils.getRelativeTime(document.modifiedAt),
                        style: GoogleFonts.slabo27px(
                          fontWeight: FontWeight.w700,
                          fontSize: 10.adaptiveSp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedDocsList() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.drag_indicator,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AutoSizeText(
                  'merge_pdf.drag_to_reorder'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.adaptiveSp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _selectedDocuments.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final Document item = _selectedDocuments.removeAt(oldIndex);
                _selectedDocuments.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final document = _selectedDocuments[index];

              return Card(
                key: ValueKey(document.id),
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AutoSizeText(
                            '${index + 1}',
                            style: GoogleFonts.slabo27px(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          AutoSizeText(
                            'merge_pdf.order'.tr(),
                            style: GoogleFonts.slabo27px(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  title: Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Row(
                      children: [
                        if (document.thumbnailPath != null &&
                            File(document.thumbnailPath!).existsSync())
                          Image.file(
                            File(document.thumbnailPath!),
                            fit: BoxFit.cover,
                          )
                        else
                          Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.picture_as_pdf,
                              size: 30,
                              color: Colors.grey,
                            ),
                          ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(
                                document.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.slabo27px(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              AutoSizeText(
                                '${document.pageCount} pages'.tr(),
                                style: GoogleFonts.slabo27px(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.drag_handle, color: Colors.grey),
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _selectedDocuments.remove(document);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMergeButton(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: OutlinedButton.icon(
        onPressed: _selectedDocuments.length < 2 ? null : _mergePdfs,
        icon: const Icon(Icons.merge_type),
        label: AutoSizeText('merge_pdf.merge_pdfs'.tr()),
        style: OutlinedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  void _toggleDocumentSelection(Document document) {
    setState(() {
      if (_selectedDocuments.contains(document)) {
        _selectedDocuments.remove(document);
      } else {
        _selectedDocuments.add(document);
      }
    });
  }

  Future<void> _pickExternalPdfs() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      final pdfMergerService = ref.read(pdfMergerServiceProvider);
      final List<String> selectedPaths = await pdfMergerService.selectPdfs();

      if (selectedPaths.isNotEmpty) {
        int pageCount = 0;
        List<Document> newDocuments = [];

        for (final pdfPath in selectedPaths) {
          try {
            pageCount =
                await pdfMergerService.pdfService.getPdfPageCount(pdfPath);

            final doc = Document(
              name: pdfPath.split('/').last.replaceAll('.pdf', ''),
              pdfPath: pdfPath,
              pagesPaths: [pdfPath],
              pageCount: pageCount,
            );

            newDocuments.add(doc);
          } catch (e) {
            logger.error('Error processing PDF $pdfPath: $e');
          }
        }

        setState(() {
          _selectedDocuments.addAll(newDocuments);
        });
      }
    } catch (e) {
      AppDialogs.showSnackBar(
        context,
        message:
            'merge_pdf.select_error'.tr(namedArgs: {'error': e.toString()}),
        type: SnackBarType.error,
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _mergePdfs() async {
    if (_selectedDocuments.length < 2) {
      AppDialogs.showSnackBar(
        context,
        message: 'merge_pdf.min_pdfs_warning'.tr(),
        type: SnackBarType.warning,
      );
      return;
    }

    if (_outputNameController.text.trim().isEmpty) {
      AppDialogs.showSnackBar(
        context,
        message: 'merge_pdf.enter_output_name'.tr(),
        type: SnackBarType.warning,
      );
      return;
    }

    final bool confirmMerge = await _confirmMergeOrder();
    if (!confirmMerge) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final pdfMergerService = ref.read(pdfMergerServiceProvider);
      final outputName = _outputNameController.text.trim();

      final mergedDocument = await pdfMergerService.mergeDocuments(
        _selectedDocuments,
        outputName,
      );

      await ref.read(documentsProvider.notifier).addDocument(mergedDocument);

      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message:
              'merge_pdf.merge_success'.tr(namedArgs: {'name': outputName}),
          type: SnackBarType.success,
        );

        setState(() {
          _selectedDocuments.clear();
        });

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message:
              'merge_pdf.merge_error'.tr(namedArgs: {'error': e.toString()}),
          type: SnackBarType.error,
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<bool> _confirmMergeOrder() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.merge_type,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('merge_pdf.confirm_order_title'.tr()),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'merge_pdf.files_merge_order'.tr(),
                    style: GoogleFonts.slabo27px(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _selectedDocuments.length,
                      itemBuilder: (context, index) {
                        final doc = _selectedDocuments[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.slabo27px(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  doc.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${doc.pageCount} pages'.tr(),
                                style: GoogleFonts.slabo27px(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('common.cancel'.tr()),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('merge_pdf.merge_now'.tr()),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('merge_pdf.help_title'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'merge_pdf.help_description'.tr(),
              style: GoogleFonts.slabo27px(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('merge_pdf.help_steps'.tr()),
            const SizedBox(height: 8),
            _buildHelpItem('1', 'merge_pdf.step_1'.tr()),
            _buildHelpItem('2', 'merge_pdf.step_2'.tr()),
            _buildHelpItem('3', 'merge_pdf.step_3'.tr()),
            _buildHelpItem('4', 'merge_pdf.step_4'.tr()),
            _buildHelpItem('5', 'merge_pdf.step_5'.tr()),
            const SizedBox(height: 16),
            Text(
              'merge_pdf.help_save_note'.tr(),
              style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.w700, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.got_it'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.slabo27px(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}
