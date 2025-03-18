// lib/providers/barcode_provider.dart

import 'dart:convert';
import 'package:easy_scan/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/barcode_scan.dart';

/// Provider for storing and managing barcode scan history
class BarcodeScanHistoryNotifier extends StateNotifier<List<BarcodeScan>> {
  BarcodeScanHistoryNotifier() : super([]);

  /// Add a new scan to the history
  void addScan(BarcodeScan scan) {
    // Check if we're updating an existing scan with the same value
    final existingIndex =
        state.indexWhere((s) => s.barcodeValue == scan.barcodeValue);

    if (existingIndex >= 0) {
      // If this is a customized version of an existing scan, update it
      if (scan.isCustomized) {
        final updatedList = [...state];
        updatedList[existingIndex] = scan;
        state = updatedList;
      } else {
        // Move existing scan to the top of the list
        final updatedList = [...state];
        final existingScan = updatedList.removeAt(existingIndex);
        state = [
          existingScan.copyWith(timestamp: DateTime.now()),
          ...updatedList
        ];
      }
    } else {
      // Add to beginning of list (most recent first)
      state = [scan, ...state];
    }

    // Limit history to 50 items
    if (state.length > 50) {
      state = state.sublist(0, 50);
    }

    // Save to persistent storage
    _saveToStorage();
  }

  /// Remove a specific scan by ID
  void removeScan(String id) {
    state = state.where((scan) => scan.id != id).toList();
    _saveToStorage();
  }

  /// Clear entire scan history
  void clearHistory() {
    state = [];
    _saveToStorage();
  }

  /// Get customized QR codes
  List<BarcodeScan> getCustomizedScans() {
    return state.where((scan) => scan.isCustomized).toList();
  }

  /// Get QR codes (excluding linear barcodes)
  List<BarcodeScan> getQrCodes() {
    return state.where((scan) => scan.isQrCode).toList();
  }

  /// Load history from Hive storage
  Future<void> loadHistory() async {
    try {
      final box = await Hive.openBox<String>('barcode_history');
      if (box.isEmpty) return;

      final jsonList = box.values.toList();
      state = jsonList
          .map((json) => BarcodeScan.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      logger.error('Error loading barcode history: $e');
      // If loading fails, maintain an empty state
      state = [];
    }
  }

  /// Save history to Hive storage
  Future<void> _saveToStorage() async {
    try {
      // We'll use Hive for storage since your app already uses it
      final box = await Hive.openBox<String>('barcode_history');

      // Convert state to JSON strings
      final jsonList = state.map((scan) => jsonEncode(scan.toJson())).toList();

      // Clear existing data and save new state
      await box.clear();
      for (int i = 0; i < jsonList.length; i++) {
        await box.put(i.toString(), jsonList[i]);
      }
    } catch (e) {
      logger.error('Error saving barcode history: $e');
    }
  }
}

/// Global provider for barcode scan history
final barcodeScanHistoryProvider =
    StateNotifierProvider<BarcodeScanHistoryNotifier, List<BarcodeScan>>((ref) {
  final notifier = BarcodeScanHistoryNotifier();
  // Load history from storage when provider is created
  notifier.loadHistory();
  return notifier;
});

/// Provider for recent barcode scans (limited to 5)
final recentBarcodesProvider = Provider<List<BarcodeScan>>((ref) {
  final allScans = ref.watch(barcodeScanHistoryProvider);

  // Return up to 5 most recent scans
  if (allScans.isEmpty) {
    return [];
  }

  return allScans.take(5).toList();
});

/// Provider for recent QR codes only
final recentQrCodesProvider = Provider<List<BarcodeScan>>((ref) {
  final allScans = ref.watch(barcodeScanHistoryProvider);

  // Filter for QR codes only and take up to 5
  final qrCodes = allScans.where((scan) => scan.isQrCode).take(5).toList();
  return qrCodes;
});

/// Provider for customized QR codes
final customizedQrCodesProvider = Provider<List<BarcodeScan>>((ref) {
  final allScans = ref.watch(barcodeScanHistoryProvider);

  // Filter for customized QR codes only
  final customized = allScans.where((scan) => scan.isCustomized).toList();
  return customized;
});

/// Provider for recent generated barcodes (from creation, not scanning)
final recentGeneratedBarcodesProvider = Provider<List<BarcodeScan>>((ref) {
  final allScans = ref.watch(barcodeScanHistoryProvider);

  // Filter for generated barcodes and take up to 3
  final generated = allScans
      .where((scan) =>
          scan.barcodeType == 'QR Code' ||
          scan.barcodeType == 'URL' ||
          scan.barcodeType == 'Email' ||
          scan.barcodeType == 'WiFi' ||
          scan.barcodeType == 'Contact')
      .take(3)
      .toList();

  return generated;
});
