import 'package:easy_scan/main.dart';
import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/ui/screen/home/widget/image_viewer_widget.dart';
import 'package:easy_scan/ui/screen/home/widget/text_viewer_widget.dart';
import 'package:easy_scan/ui/widget/pdf_viewer.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;

class DocumentViewerWidget extends StatelessWidget {
  final Document document;
  final bool showAppBar;
  final VoidCallback? onShare;

  const DocumentViewerWidget({
    Key? key,
    required this.document,
    this.showAppBar = true,
    this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get file extension
    final String extension =
        path.extension(document.pdfPath).toLowerCase().replaceAll('.', '');

    // Determine which viewer to use based on file extension
    switch (extension) {
      case 'pdf':
        return PDFViewerWidget(
          document: document,
          showAppBar: showAppBar,
          onShare: onShare,
        );
      case 'jpg':
      case 'jpeg':
      case 'png':
        return ImageViewerWidget(
          filePath: document.pdfPath,
          showAppBar: showAppBar,
          onShare: onShare,
        );
      case 'txt':
      case 'html':
      case 'md':
      case 'rtf':
        return TextViewerWidget(
          filePath: document.pdfPath,
          showAppBar: showAppBar,
          onShare: onShare,
        );
      default:
        // For unsupported formats, show a message
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.file_present, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Cannot preview this file format (.$extension)',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // Open with external viewer if available
                  _openWithExternalApp(document.pdfPath);
                },
                child: const Text('Open with another app'),
              ),
            ],
          ),
        );
    }
  }

  Future<void> _openWithExternalApp(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      logger.error('Failed to open file with external app: $e');
    }
  }
}
