import 'package:hive/hive.dart';
import 'dart:ui';

part 'scan_result.g.dart';

@HiveType(typeId: 4)
class TextElementData extends HiveObject {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final Rect boundingBox;

  TextElementData({required this.text, required this.boundingBox});
}

@HiveType(typeId: 5)
class ScanResult extends HiveObject {
  @HiveField(0)
  final List<String> scannedPages; // Store file paths instead of File objects

  @HiveField(1)
  final List<String> recognizedText;

  @HiveField(2)
  final String? documentName;

  @HiveField(3)
  final bool isSuccess;

  @HiveField(4)
  final String? errorMessage;

  ScanResult({
    required this.scannedPages,
    this.recognizedText = const [],
    this.documentName,
    this.isSuccess = true,
    this.errorMessage,
  });

  bool get hasPages => scannedPages.isNotEmpty;

  bool get hasText => recognizedText.isNotEmpty;
}
