// Add to lib/providers/barcode_scan_provider.dart

import 'package:easy_scan/models/barcode_scan.dart';
import 'package:easy_scan/providers/barcode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for recent barcode scans (limited to 5)
final recentBarcodesProvider = Provider<List<BarcodeScan>>((ref) {
  final allScans = ref.watch(barcodeScanHistoryProvider);

  // Return up to 5 most recent scans
  if (allScans.isEmpty) {
    return [];
  }

  return allScans.take(5).toList();
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
