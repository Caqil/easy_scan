// lib/providers/barcode_scan_provider.dart

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/barcode_scan.dart';

/// Provider for storing and managing barcode scan history
class BarcodeScanHistoryNotifier extends StateNotifier<List<BarcodeScan>> {
  BarcodeScanHistoryNotifier() : super([]);

  /// Add a new scan to the history
  void addScan(BarcodeScan scan) {
    // Add to beginning of list (most recent first)
    state = [scan, ...state];

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
      print('Error loading barcode history: $e');
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
      print('Error saving barcode history: $e');
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
