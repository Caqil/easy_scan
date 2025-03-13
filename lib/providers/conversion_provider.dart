import 'dart:async';
import 'dart:io';

import 'package:easy_scan/models/conversion.dart';
import 'package:easy_scan/models/format_category.dart';
import 'package:easy_scan/services/conversion_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final conversionServiceProvider = Provider<ConversionService>((ref) {
  return ConversionService();
});

final conversionStateProvider =
    StateNotifierProvider<ConversionNotifier, ConversionState>((ref) {
  return ConversionNotifier(ref);
});

// State notifier
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
      FilePickerResult? result = await FilePicker.platform.pickFiles();

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

  Future<void> convertFile() async {
    if (state.selectedFile == null) {
      state = state.copyWith(error: "Please select a file first");
      return;
    }

    if (state.inputFormat == null || state.outputFormat == null) {
      state = state.copyWith(error: "Please select input and output formats");
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
      final filePath = await service.convertFile(
        file: state.selectedFile!,
        inputFormat: state.inputFormat!.id,
        outputFormat: state.outputFormat!.id,
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
    } catch (e) {
      state = state.copyWith(
        isConverting: false,
        error: e.toString(),
      );
    }
  }

  void reset() {
    state = ConversionState();
  }
}
