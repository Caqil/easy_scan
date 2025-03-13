import 'dart:io';
import 'package:easy_scan/ui/widget/password_verification_dialog.dart';
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
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPasswordProtection();
  }

  void _checkPasswordProtection() {
    if (widget.document.isPasswordProtected) {
      Future.delayed(const Duration(milliseconds: 500), () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PasswordVerificationDialog(
            correctPassword:
                widget.document.password ?? "", // Pastikan tidak null
            onVerified: () {
              setState(() {
                _isLoading = false;
                _errorMessage = null; // Reset error jika ada
              });
            },
            onCancelled: () {
              setState(() {
                _isLoading = false;
                _errorMessage =
                    "Password input was cancelled."; // Tampilkan error
              });
            },
          ),
        );
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
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
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context), // Kembali ke halaman sebelumnya
              child: const Text("Go Back"),
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
          password: widget.document.isPasswordProtected
              ? widget.document.password ?? ""
              : null,
          controller: _pdfViewerController,
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            setState(() {
              _isLoading = false; // Stop loading
              if (details.error.contains('Password required') ||
                  details.error.contains('invalid password')) {
                _errorMessage =
                    'Incorrect password or password input was cancelled.';
              } else {
                _errorMessage = 'Failed to load PDF: ${details.error}';
              }
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
                            break;
                          case 'print':
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
