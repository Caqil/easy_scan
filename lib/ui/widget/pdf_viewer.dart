import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../models/document.dart';

class PDFViewerWidget extends StatefulWidget {
  final Document document;
  final bool showAppBar;
  final VoidCallback? onShare;

  const PDFViewerWidget({
    super.key,
    required this.document,
    this.showAppBar = true,
    this.onShare,
  });

  @override
  State<PDFViewerWidget> createState() => _PDFViewerWidgetState();
}

class _PDFViewerWidgetState extends State<PDFViewerWidget> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isPasswordDialogOpen = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPasswordProtection();
  }

  void _checkPasswordProtection() {
    // If the document is password protected and we have a password, we need to prompt for it
    if (widget.document.isPasswordProtected &&
        widget.document.password != null) {
      // In a real app, we would decrypt the file here
      // For now, we'll just simulate it
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _isLoading = false;
        });
      });
    } else {
      // Not password protected, just load it
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPasswordDialog() {
    if (_isPasswordDialogOpen) return;

    _isPasswordDialogOpen = true;
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Password Protected'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text == widget.document.password) {
                Navigator.pop(context);
                // In a real app, we would decrypt the file here
                setState(() {
                  _isLoading = false;
                });
              } else {
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Incorrect password'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Open'),
          ),
        ],
      ),
    ).then((_) {
      controller.dispose();
      _isPasswordDialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Check if the file exists
    final file = File(widget.document.pdfPath);
    if (!file.existsSync()) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'PDF file not found',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        SfPdfViewer.file(
          file,
          controller: _pdfViewerController,
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            setState(() {
              _errorMessage = 'Failed to load PDF: ${details.error}';
            });
          },
        ),
        if (widget.showAppBar)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Theme.of(context).appBarTheme.backgroundColor,
              child: SafeArea(
                bottom: false,
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
                    if (widget.onShare != null)
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: widget.onShare,
                      ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                      //  _pdfViewerController.openSearchTextField();
                      },
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'bookmark':
                            // TODO: Implement bookmarks
                            break;
                          case 'print':
                            // TODO: Implement print
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'bookmark',
                          child: Row(
                            children: [
                              Icon(Icons.bookmark),
                              SizedBox(width: 8),
                              Text('Add Bookmark'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'print',
                          child: Row(
                            children: [
                              Icon(Icons.print),
                              SizedBox(width: 8),
                              Text('Print'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
