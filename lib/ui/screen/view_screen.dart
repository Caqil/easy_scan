import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/services/share_service.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:printing/printing.dart';
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
                        icon: const Icon(Icons.print),
                        onPressed: _printPDF,
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

  Future<void> _printPDF() async {
    await Printing.layoutPdf(
      onLayout: (format) async => File(widget.document.pdfPath).readAsBytes(),
    );
  }
}
