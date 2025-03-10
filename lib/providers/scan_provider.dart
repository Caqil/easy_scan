import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scan_settings.dart';

class ScanState {
  final List<File> scannedPages;
  final ScanSettings settings;
  final bool isScanning;
  final String? errorMessage;

  ScanState({
    required this.scannedPages,
    required this.settings,
    this.isScanning = false,
    this.errorMessage,
  });

  ScanState copyWith({
    List<File>? scannedPages,
    ScanSettings? settings,
    bool? isScanning,
    String? errorMessage,
  }) {
    return ScanState(
      scannedPages: scannedPages ?? this.scannedPages,
      settings: settings ?? this.settings,
      isScanning: isScanning ?? this.isScanning,
      errorMessage: errorMessage,
    );
  }

  bool get hasPages => scannedPages.isNotEmpty;
}

class ScanNotifier extends StateNotifier<ScanState> {
  ScanNotifier()
      : super(ScanState(
          scannedPages: [],
          settings: ScanSettings(),
        ));

  void updateSettings(ScanSettings settings) {
    state = state.copyWith(settings: settings);
  }

  void addPage(File page) {
    state = state.copyWith(
      scannedPages: [...state.scannedPages, page],
    );
  }

  void updatePageAt(int index, File newPage) {
    if (index < 0 || index >= state.scannedPages.length) return;

    final newPages = [...state.scannedPages];
    newPages[index] = newPage;
    state = state.copyWith(scannedPages: newPages);
  }

  void removePage(int index) {
    if (index < 0 || index >= state.scannedPages.length) return;

    final newPages = [...state.scannedPages];
    newPages.removeAt(index);
    state = state.copyWith(scannedPages: newPages);
  }

  void reorderPages(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.scannedPages.length) return;
    if (newIndex < 0 || newIndex > state.scannedPages.length) return;

    final newPages = [...state.scannedPages];
    final File page = newPages.removeAt(oldIndex);

    // Adjust for the shifting after removal
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    newPages.insert(newIndex, page);
    state = state.copyWith(scannedPages: newPages);
  }

  void setScanning(bool isScanning) {
    state = state.copyWith(isScanning: isScanning);
  }

  void setError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void clearPages() {
    state = state.copyWith(scannedPages: []);
  }
}

final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  return ScanNotifier();
});
