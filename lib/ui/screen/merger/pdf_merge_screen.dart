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

              // Selected documents counter
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selected PDFs: ${_selectedDocuments.length}',
                      style: GoogleFonts.notoSerif(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedDocuments.isNotEmpty)
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
              _buildMergeButton(colorScheme),
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

                      // Selection indicator
                      if (isSelected)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
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
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _selectedDocuments.length,
      itemBuilder: (context, index) {
        final document = _selectedDocuments[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
          child: ListTile(
            leading: document.thumbnailPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      File(document.thumbnailPath!),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: Colors.grey),
                  ),
            title: Text(
              document.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSerif(
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              '${document.pageCount} pages',
              style: GoogleFonts.notoSerif(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                setState(() {
                  _selectedDocuments.remove(document);
                });
              },
            ),
          ),
        );
      },
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
        // We need to create temporary Document objects from the selected files
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

        AppDialogs.showSnackBar(
          context,
          message: 'Added ${newDocuments.length} PDF files',
          type: SnackBarType.success,
        );
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
          message: 'PDFs merged successfully into $outputName',
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
            _buildHelpItem('4', 'Tap "Merge PDFs" button'),
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
