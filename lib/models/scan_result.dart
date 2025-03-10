import 'dart:io';

class ScanResult {
  final List<File> scannedPages;
  final List<String> recognizedText;
  final String? documentName;
  final bool isSuccess;
  final String? errorMessage;

  ScanResult({
    required this.scannedPages,
    this.recognizedText = const [],
    this.documentName,
    this.isSuccess = true,
    this.errorMessage,
  });

  // Check if scan has any pages
  bool get hasPages => scannedPages.isNotEmpty;

  // Check if OCR results are available
  bool get hasText => recognizedText.isNotEmpty;
}
