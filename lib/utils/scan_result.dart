import 'dart:io';
import 'dart:ui';

class TextElementData {
  final String text;
  final Rect boundingBox;

  TextElementData({required this.text, required this.boundingBox});
}

// Update ScanResult class
class ScanResult {
  final List<File> scannedPages;
  final List<List<TextElementData>> recognizedTextElements;
  final String? documentName;
  final bool isSuccess;
  final String? errorMessage;

  ScanResult({
    required this.scannedPages,
    this.recognizedTextElements = const [],
    this.documentName,
    this.isSuccess = true,
    this.errorMessage,
  });

  // Check if scan has any pages
  bool get hasPages => scannedPages.isNotEmpty;

  // Check if OCR results are available
  bool get hasText => recognizedTextElements.any((page) => page.isNotEmpty);
}
