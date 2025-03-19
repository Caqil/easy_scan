import 'dart:io';

import 'package:hive/hive.dart';
import 'package:scanpro/models/format_category.dart';

part 'conversion_state.g.dart';

@HiveType(typeId: 0)
class ConversionState extends HiveObject {
  @HiveField(0)
  final FormatOption? inputFormat;

  @HiveField(1)
  final FormatOption? outputFormat;

  @HiveField(2)
  final String? selectedFilePath;

  @HiveField(3)
  final bool isConverting;

  @HiveField(4)
  final double progress;

  @HiveField(5)
  final String? error;

  @HiveField(6)
  final String? convertedFilePath;

  @HiveField(7)
  final bool ocrEnabled;

  @HiveField(8)
  final int quality;

  @HiveField(9)
  final String? password;

  @HiveField(10)
  final String? thumbnailPath;

  ConversionState({
    this.inputFormat,
    this.outputFormat,
    this.selectedFilePath,
    this.isConverting = false,
    this.progress = 0.0,
    this.error,
    this.convertedFilePath,
    this.ocrEnabled = false,
    this.quality = 90,
    this.password,
    this.thumbnailPath,
  });

  File? get selectedFile =>
      selectedFilePath != null ? File(selectedFilePath!) : null;

  ConversionState copyWith({
    FormatOption? inputFormat,
    FormatOption? outputFormat,
    String? selectedFilePath,
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
      selectedFilePath: selectedFilePath ?? this.selectedFilePath,
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
