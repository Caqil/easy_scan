import 'dart:io';

import 'package:easy_scan/models/format_category.dart';

class ConversionState {
  final FormatOption? inputFormat;
  final FormatOption? outputFormat;
  final File? selectedFile;
  final bool isConverting;
  final double progress;
  final String? error;
  final String? convertedFilePath;
  final bool ocrEnabled;
  final int quality;
  final String? password;
  final String? thumbnailPath;

  ConversionState({
    this.inputFormat,
    this.outputFormat,
    this.selectedFile,
    this.isConverting = false,
    this.progress = 0.0,
    this.error,
    this.convertedFilePath,
    this.ocrEnabled = false,
    this.quality = 90,
    this.password,
    this.thumbnailPath,
  });

  ConversionState copyWith({
    FormatOption? inputFormat,
    FormatOption? outputFormat,
    File? selectedFile,
    bool? isConverting,
    double? progress,
    String? error,
    String? convertedFilePath,
    bool? ocrEnabled,
    int? quality,
    String? password,
    String? thumbnailPath,
  }) {
    return ConversionState(
      inputFormat: inputFormat ?? this.inputFormat,
      outputFormat: outputFormat ?? this.outputFormat,
      selectedFile: selectedFile ?? this.selectedFile,
      isConverting: isConverting ?? this.isConverting,
      progress: progress ?? this.progress,
      error: error,
      convertedFilePath: convertedFilePath,
      ocrEnabled: ocrEnabled ?? this.ocrEnabled,
      quality: quality ?? this.quality,
      password: password ?? this.password,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}
