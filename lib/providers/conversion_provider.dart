import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:easy_scan/models/conversion.dart';
import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/models/format_category.dart';
import 'package:easy_scan/services/conversion_service.dart';
import 'package:easy_scan/services/image_service.dart';
import 'package:easy_scan/services/pdf_service.dart';
import 'package:easy_scan/services/thumbnail_service.dart';
import 'package:easy_scan/utils/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'document_provider.dart';

final conversionServiceProvider = Provider<ConversionService>((ref) {
  return ConversionService();
});

final conversionStateProvider =
    StateNotifierProvider<ConversionNotifier, ConversionState>((ref) {
  return ConversionNotifier(ref);
});

class ConversionNotifier extends StateNotifier<ConversionState> {
  final Ref _ref;

  ConversionNotifier(this._ref) : super(ConversionState());

  void setInputFormat(FormatOption format) {
    state = state.copyWith(
      inputFormat: format,
      selectedFile: null,
      convertedFilePath: null,
      error: null,
    );
  }

  void setOutputFormat(FormatOption format) {
    state = state.copyWith(
      outputFormat: format,
      convertedFilePath: null,
      error: null,
    );
  }

  Future<void> pickFile() async {
    try {
      String? allowedExtension;
      if (state.inputFormat != null) {
        allowedExtension = state.inputFormat!.id.toLowerCase();
      }

      FilePickerResult? result;
      if (allowedExtension != null) {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: [allowedExtension],
        );
      } else {
        result = await FilePicker.platform.pickFiles();
      }

      if (result != null) {
        state = state.copyWith(
          selectedFile: File(result.files.single.path!),
          error: null,
          convertedFilePath: null,
        );
      }
    } catch (e) {
      state = state.copyWith(error: "Error picking file: $e");
    }
  }

  void setOcrEnabled(bool enabled) {
    state = state.copyWith(ocrEnabled: enabled);
  }

  void setQuality(int quality) {
    state = state.copyWith(quality: quality);
  }

  void setPassword(String? password) {
    state = state.copyWith(password: password);
  }

  Future<void> convertFile({
    VoidCallback? onSuccess,
    Function(String error)? onFailure,
  }) async {
    if (state.selectedFile == null) {
      state = state.copyWith(error: "Please select a file first");
      onFailure?.call("Please select a file first");
      return;
    }

    if (state.inputFormat == null || state.outputFormat == null) {
      state = state.copyWith(error: "Please select input and output formats");
      onFailure?.call("Please select input and output formats");
      return;
    }

    try {
      state = state.copyWith(isConverting: true, progress: 0.0, error: null);

      // Simulate progress updates
      final progressTimer =
          Timer.periodic(const Duration(milliseconds: 200), (timer) {
        if (state.isConverting && state.progress < 0.9) {
          state = state.copyWith(progress: state.progress + 0.1);
        } else {
          timer.cancel();
        }
      });

      final service = _ref.read(conversionServiceProvider);

      // Check values before using them
      final String inputFormat = state.inputFormat?.id ?? "";
      final String outputFormat = state.outputFormat?.id ?? "";

      if (inputFormat.isEmpty || outputFormat.isEmpty) {
        throw Exception("Input or output format is invalid");
      }

      final filePath = await service.convertFile(
        file: state.selectedFile!,
        inputFormat: inputFormat,
        outputFormat: outputFormat,
        ocrEnabled: state.ocrEnabled,
        quality: state.quality,
        password: state.password,
      );

      progressTimer.cancel();
      state = state.copyWith(
        isConverting: false,
        progress: 1.0,
        convertedFilePath: filePath,
      );

      onSuccess?.call();
    } catch (e) {
      state = state.copyWith(
        isConverting: false,
        error: e.toString(),
      );
      onFailure?.call(e.toString());
    }
  }

  Future<void> saveConvertedFileAsDocument(
      String filePath, FormatOption outputFormat, WidgetRef ref,
      {String? thumbnailPath}) async {
    try {
      File? thumbnailFile;

      // Create a document name from the original filename
      final fileName = path.basename(filePath);
      final documentName = path.basenameWithoutExtension(fileName);

      // Get page count if it's a PDF
      int pageCount = 1;
      if (outputFormat.id.toLowerCase() == 'pdf') {
        final pdfService = PdfService();
        pageCount = await pdfService.getPdfPageCount(filePath);
      }
      if (thumbnailPath != null && File(thumbnailPath).existsSync()) {
        thumbnailFile = File(thumbnailPath);
      } else {
        // Generate a thumbnail if not already generated
        final thumbnailService = ThumbnailService();

        try {
          thumbnailFile = await thumbnailService.generateThumbnail(
            filePath,
            size: AppConstants.thumbnailSize,
          );
        } catch (e) {
          print('Failed to generate thumbnail: $e');
        }
      }
      final document = Document(
        name: documentName,
        pdfPath:
            filePath, // This field is named pdfPath but we're using it for all file types
        pagesPaths: [filePath],
        pageCount: pageCount,
        thumbnailPath: thumbnailFile?.path,
      );

      // Save document to Hive via provider
      await ref.read(documentsProvider.notifier).addDocument(document);
    } catch (e) {}
  }

  Future<void> _saveConvertedFileToLibrary(
      String filePath, String outputFormat) async {
    try {
      // Generate a thumbnail for the converted file
      final imageService = ImageService();
      File? thumbnailFile;

      // Only try to create thumbnail if it's a supported format
      if (['pdf', 'jpg', 'jpeg', 'png'].contains(outputFormat.toLowerCase())) {
        try {
          thumbnailFile = await imageService.createThumbnail(
            File(filePath),
            size: AppConstants.thumbnailSize,
          );
        } catch (e) {
          print('Failed to generate thumbnail: $e');
        }
      }

      // Create a document name from the original filename
      final fileName = path.basename(filePath);
      final documentName = path.basenameWithoutExtension(fileName);

      // Get page count if it's a PDF
      int pageCount = 1;
      if (outputFormat.toLowerCase() == 'pdf') {
        final pdfService = PdfService();
        pageCount = await pdfService.getPdfPageCount(filePath);
      }

      // Create document model
      final document = Document(
        name: documentName,
        pdfPath: filePath,
        pagesPaths: [filePath],
        pageCount: pageCount,
        thumbnailPath: thumbnailFile?.path,
      );

      // Save document to Hive via provider
      await _ref.read(documentsProvider.notifier).addDocument(document);
    } catch (e) {
      print('Error saving converted file to library: $e');
      // Don't throw, just log the error
    }
  }

  void reset() {
    state = ConversionState();
  }
}
