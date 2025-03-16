import 'dart:io';
import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/providers/document_provider.dart';
import 'package:easy_scan/services/pdf_merger_service.dart';
import 'package:easy_scan/ui/common/app_bar.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:easy_scan/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:super_tooltip/super_tooltip.dart';

class PdfMergerScreen extends ConsumerStatefulWidget {
  const PdfMergerScreen({Key? key}) : super(key: key);

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

    // Get all documents from provider and filter for PDFs
    final allDocuments = ref.watch(documentsProvider);
    final pdfMergerService = ref.read(pdfMergerServiceProvider);
    final pdfDocuments = pdfMergerService.filterPdfDocuments(allDocuments);

    // Sort by most recent first
    pdfDocuments.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('PDF Merger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Help',
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Output filename input
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _outputNameController,
                  decoration: InputDecoration(
                    labelText: 'Output Filename',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.merge_type),
                  ),
                ),
              ),

              // Toggle between library and external PDFs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('From Library'),
                      icon: Icon(Icons.folder),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('From Device'),
                      icon: Icon(Icons.drive_folder_upload),
                    ),
                  ],
                  selected: {_isShowingLibraryDocs},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _isShowingLibraryDocs = selection.first;
                      // Clear selection when switching modes
                      _selectedDocuments.clear();
                    });
                  },
                ),
              ),

              // Selected documents counter and tip
              if (_selectedDocuments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Selected: ${_selectedDocuments.length} PDFs',
                                style: GoogleFonts.notoSerif(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 2),
                              GestureDetector(
                                onTap: () async {
                                  await _controller.showTooltip();
                                },
                                child: SuperTooltip(
                                  showBarrier: true,
                                  controller: _controller,
                                  content: Text(
                                    "Files will be merged in the order displayed. Drag items to reorder.",
                                    softWrap: true,
                                    style: GoogleFonts.notoSerif(),
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear'),
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

              // Library documents display (when in library mode)
              if (_isShowingLibraryDocs)
                Expanded(
                  child: pdfDocuments.isEmpty
                      ? _buildEmptyLibraryView()
                      : _buildLibraryDocsGrid(pdfDocuments),
                )
              else
                // External PDFs mode content
                Expanded(
                  child: _selectedDocuments.isEmpty
                      ? _buildAddExternalDocsView()
                      : _buildSelectedDocsList(),
                ),

              // Merge button
              if (_selectedDocuments.isNotEmpty) _buildMergeButton(colorScheme),
            ],
          ),

          // Loading overlay
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
              tooltip: 'Add PDFs',
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
          Text(
            'No PDF documents in your library',
            style: GoogleFonts.notoSerif(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try importing PDFs or switching to "From Device" mode',
            style: GoogleFonts.notoSerif(
              fontSize: 14.sp,
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
          Text(
            'Select PDFs to merge',
            style: GoogleFonts.notoSerif(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to select files from your device',
            style: GoogleFonts.notoSerif(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _pickExternalPdfs,
            icon: const Icon(Icons.add),
            label: const Text('Select PDFs'),
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
                // PDF thumbnail
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Thumbnail with rounded corners
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

                      // Selection overlay with order number
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
                                      Text(
                                        '${selectedIndex + 1}',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        'ORDER',
                                        style: TextStyle(
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

                // Document info
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSerif(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${document.pageCount} pages',
                        style: GoogleFonts.notoSerif(
                          fontSize: 10.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        DateTimeUtils.getRelativeTime(document.modifiedAt),
                        style: GoogleFonts.notoSerif(
                          fontSize: 10.sp,
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
        // Info banner
        Container(
          margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
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
                child: Text(
                  'Drag files to reorder. PDFs will be merged in this sequence.',
                  style: GoogleFonts.notoSerif(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Reorderable list with order numbers
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
                          Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const Text(
                            'ORDER',
                            style: TextStyle(
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
                              Text(
                                document.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.notoSerif(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${document.pageCount} pages',
                                style: GoogleFonts.notoSerif(
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
      child: ElevatedButton.icon(
        onPressed: _selectedDocuments.length < 2 ? null : _mergePdfs,
        icon: const Icon(Icons.merge_type),
        label: const Text('Merge PDFs'),
        style: ElevatedButton.styleFrom(
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
        // Create temporary Document objects from the selected files
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
            debugPrint('Error processing PDF $pdfPath: $e');
            // Continue with the rest of the files
          }
        }

        setState(() {
          _selectedDocuments.addAll(newDocuments);
        });
      }
    } catch (e) {
      AppDialogs.showSnackBar(
        context,
        message: 'Error selecting PDFs: $e',
        type: SnackBarType.error,
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // void _showOrderingTip() {
  //   if (_selectedDocuments.length < 2) return;

  //   AppDialogs.showSnackBar(
  //     context,
  //     message:
  //         'Files will be merged in the order shown. Drag items to reorder.',
  //     type: SnackBarType.normal,
  //     duration: const Duration(seconds: 5),
  //   );
  // }

  Future<void> _mergePdfs() async {
    if (_selectedDocuments.length < 2) {
      AppDialogs.showSnackBar(
        context,
        message: 'Please select at least 2 PDFs to merge',
        type: SnackBarType.warning,
      );
      return;
    }

    if (_outputNameController.text.trim().isEmpty) {
      AppDialogs.showSnackBar(
        context,
        message: 'Please enter a name for the output file',
        type: SnackBarType.warning,
      );
      return;
    }

    // Show confirmation with ordered file list
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

      // Add the merged document to the library
      await ref.read(documentsProvider.notifier).addDocument(mergedDocument);

      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'PDFs merged successfully into "$outputName"',
          type: SnackBarType.success,
        );

        // Reset selection
        setState(() {
          _selectedDocuments.clear();
        });

        // Navigate back
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'Error merging PDFs: $e',
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
                const Text('Confirm PDF Order'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Files will be merged in this order:',
                    style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
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
                                    style: const TextStyle(
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
                                '${doc.pageCount} pages',
                                style: TextStyle(
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
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Merge Now'),
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
        title: const Text('PDF Merger Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This tool allows you to combine multiple PDF files into a single document.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Steps:'),
            const SizedBox(height: 8),
            _buildHelpItem('1', 'Enter a name for the merged file'),
            _buildHelpItem('2', 'Choose PDFs from your library or device'),
            _buildHelpItem('3', 'Select at least 2 PDFs to merge'),
            _buildHelpItem('4', 'Drag PDFs to change the merge order'),
            _buildHelpItem('5', 'Tap "Merge PDFs" button'),
            const SizedBox(height: 16),
            const Text(
              'The merged PDF will be saved to your document library.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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
                style: const TextStyle(
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
