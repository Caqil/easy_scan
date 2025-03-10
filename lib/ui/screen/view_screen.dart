
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/providers/document_provider.dart';
import 'package:easy_scan/services/share_service.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:easy_scan/utils/date_utils.dart';
import 'package:easy_scan/utils/file_utils.dart';

import '../widget/pdf_viewer.dart';

class ViewScreen extends ConsumerStatefulWidget {
  final Document document;
  
  const ViewScreen({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<ViewScreen> createState() => _ViewScreenState();
}

class _ViewScreenState extends ConsumerState<ViewScreen> {
  final ShareService _shareService = ShareService();
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PDF Viewer
          Positioned.fill(
            child: PDFViewerWidget(
              document: widget.document,
              showAppBar: false,
              onShare: _shareDocument,
            ),
          ),
          
          // Top menu bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Theme.of(context).appBarTheme.backgroundColor,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.document.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: _shareDocument,
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: _showMoreOptions,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
  
  Future<void> _shareDocument() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      await _shareService.sharePdf(
        widget.document.pdfPath,
        subject: widget.document.name,
      );
    } catch (e) {
      // Show error
      // ignore: use_build_context_synchronously
      AppDialogs.showSnackBar(
        context,
        message: 'Error sharing document: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Document info
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.document.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                FutureBuilder<String>(
                  future: FileUtils.getFileSize(widget.document.pdfPath),
                  builder: (context, snapshot) {
                    final size = snapshot.data ?? 'Unknown size';
                    return Text(
                      '${widget.document.pageCount} pages • $size',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'Created: ${DateTimeUtils.formatDateTime(widget.document.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Actions
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              _showRenameDialog();
            },
          ),
          ListTile(
            leading: Icon(
              widget.document.isFavorite ? Icons.star : Icons.star_border,
              color: widget.document.isFavorite ? Colors.amber : null,
            ),
            title: Text(
              widget.document.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
            ),
            onTap: () {
              Navigator.pop(context);
              _toggleFavorite();
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Move to Folder'),
            onTap: () {
              Navigator.pop(context);
              _showMoveToFolderDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text('Print'),
            onTap: () {
              Navigator.pop(context);
              _printDocument();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete();
            },
          ),
        ],
      ),
    );
  }
  
  void _showRenameDialog() {
    AppDialogs.showInputDialog(
      context,
      title: 'Rename Document',
      initialValue: widget.document.name,
      hintText: 'Enter new name',
    ).then((newName) {
      if (newName != null && newName.isNotEmpty) {
        // Create updated document
        final updatedDoc = Document(
          id: widget.document.id,
          name: newName,
          pdfPath: widget.document.pdfPath,
          pagesPaths: widget.document.pagesPaths,
          pageCount: widget.document.pageCount,
          thumbnailPath: widget.document.thumbnailPath,
          createdAt: widget.document.createdAt,
          modifiedAt: DateTime.now(),
          tags: widget.document.tags,
          folderId: widget.document.folderId,
          isFavorite: widget.document.isFavorite,
          isPasswordProtected: widget.document.isPasswordProtected,
          password: widget.document.password,
        );
        
        // Update document
        ref.read(documentsProvider.notifier).updateDocument(updatedDoc);
        
        // Show success message
        AppDialogs.showSnackBar(
          context,
          message: 'Document renamed successfully',
        );
      }
    });
  }
  
  void _toggleFavorite() {
    // Create updated document
    final updatedDoc = Document(
      id: widget.document.id,
      name: widget.document.name,
      pdfPath: widget.document.pdfPath,
      pagesPaths: widget.document.pagesPaths,
      pageCount: widget.document.pageCount,
      thumbnailPath: widget.document.thumbnailPath,
      createdAt: widget.document.createdAt,
      modifiedAt: DateTime.now(),
      tags: widget.document.tags,
      folderId: widget.document.folderId,
      isFavorite: !widget.document.isFavorite,
      isPasswordProtected: widget.document.isPasswordProtected,
      password: widget.document.password,
    );
    
    // Update document
    ref.read(documentsProvider.notifier).updateDocument(updatedDoc);
    
    // Show success message
    AppDialogs.showSnackBar(
      context,
      message: updatedDoc.isFavorite
          ? 'Added to favorites'
          : 'Removed from favorites',
    );
  }
  
  void _showMoveToFolderDialog() {
    // This would be implemented to show a list of folders to move the document to
    // For now, just show a message
    AppDialogs.showSnackBar(
      context,
      message: 'Move to folder functionality would be implemented here',
    );
  }
  
  void _printDocument() {
    // This would be implemented to print the document
    // For now, just show a message
    AppDialogs.showSnackBar(
      context,
      message: 'Print functionality would be implemented here',
    );
  }
  
  void _confirmDelete() {
    AppDialogs.showConfirmDialog(
      context,
      title: 'Delete Document',
      message: 'Are you sure you want to delete "${widget.document.name}"?',
      confirmText: 'Delete',
      isDangerous: true,
    ).then((confirmed) {
      if (confirmed) {
        // Delete document
        ref.read(documentsProvider.notifier).deleteDocument(widget.document.id);
        
        // Show success message
        AppDialogs.showSnackBar(
          context,
          message: 'Document deleted successfully',
        );
        
        // Go back to previous screen
        Navigator.pop(context);
      }
    });
  }
}