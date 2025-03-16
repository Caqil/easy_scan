import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class BarcodeScan {
  final String id;
  final String barcodeValue;
  final String barcodeType;
  final String barcodeFormat;
  final DateTime timestamp;
  final bool isCustomized;
  final String? customImagePath; // Optional path to a customized QR image

  BarcodeScan({
    String? id,
    required this.barcodeValue,
    required this.barcodeType,
    required this.barcodeFormat,
    required this.timestamp,
    this.isCustomized = false,
    this.customImagePath,
  }) : id = id ?? const Uuid().v4();

  // Create a copy of the current scan with some updated properties
  BarcodeScan copyWith({
    String? barcodeValue,
    String? barcodeType,
    String? barcodeFormat,
    DateTime? timestamp,
    bool? isCustomized,
    String? customImagePath,
  }) {
    return BarcodeScan(
      id: this.id,
      barcodeValue: barcodeValue ?? this.barcodeValue,
      barcodeType: barcodeType ?? this.barcodeType,
      barcodeFormat: barcodeFormat ?? this.barcodeFormat,
      timestamp: timestamp ?? this.timestamp,
      isCustomized: isCustomized ?? this.isCustomized,
      customImagePath: customImagePath ?? this.customImagePath,
    );
  }

  // Convert to JSON representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcodeValue': barcodeValue,
      'barcodeType': barcodeType,
      'barcodeFormat': barcodeFormat,
      'timestamp': timestamp.toIso8601String(),
      'isCustomized': isCustomized,
      'customImagePath': customImagePath,
    };
  }

  // Create from JSON map
  factory BarcodeScan.fromJson(Map<String, dynamic> json) {
    return BarcodeScan(
      id: json['id'],
      barcodeValue: json['barcodeValue'],
      barcodeType: json['barcodeType'],
      barcodeFormat: json['barcodeFormat'],
      timestamp: DateTime.parse(json['timestamp']),
      isCustomized: json['isCustomized'] ?? false,
      customImagePath: json['customImagePath'],
    );
  }

  // Create from JSON string
  factory BarcodeScan.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return BarcodeScan.fromJson(json);
  }

  // Helper method to determine if this is a QR code (vs linear barcode)
  bool get isQrCode {
    final qrFormats = ['QR_CODE', 'AZTEC', 'DATA_MATRIX'];
    return qrFormats.contains(barcodeFormat) ||
        barcodeFormat.contains('QR') ||
        barcodeFormat.contains('qr');
  }

  // Helper method to get a standardized content type
  String get standardizedContentType {
    if (barcodeValue.startsWith('http://') ||
        barcodeValue.startsWith('https://')) {
      return 'URL/Website';
    } else if (barcodeValue.startsWith('tel:') ||
        RegExp(r'^\+?[0-9\s\-\(\)]+$').hasMatch(barcodeValue)) {
      return 'Phone Number';
    } else if (barcodeValue.contains('@') && barcodeValue.contains('.')) {
      return 'Email Address';
    } else if (barcodeValue.startsWith('WIFI:')) {
      return 'WiFi Network';
    } else if (barcodeValue.startsWith('MATMSG:') ||
        barcodeValue.startsWith('mailto:')) {
      return 'Email Message';
    } else if (barcodeValue.startsWith('geo:') ||
        RegExp(r'^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$')
            .hasMatch(barcodeValue)) {
      return 'Location';
    } else if (barcodeValue.startsWith('BEGIN:VCARD')) {
      return 'Contact';
    } else if (barcodeValue.startsWith('BEGIN:VEVENT')) {
      return 'Calendar Event';
    } else if (RegExp(r'^[0-9]+$').hasMatch(barcodeValue)) {
      return 'Product Code';
    } else {
      return 'Text';
    }
  }

  // Get appropriate icon based on barcode type
  IconData get typeIcon {
    switch (standardizedContentType.toLowerCase()) {
      case 'url/website':
        return Icons.language;
      case 'phone number':
        return Icons.phone;
      case 'email address':
      case 'email message':
        return Icons.email;
      case 'wifi network':
        return Icons.wifi;
      case 'location':
        return Icons.location_on;
      case 'contact':
        return Icons.contact_page;
      case 'calendar event':
        return Icons.event;
      case 'product code':
        return Icons.shopping_cart;
      case 'text':
        return Icons.text_fields;
      default:
        return isQrCode ? Icons.qr_code : Icons.qr_code;
    }
  }

  // Get color based on barcode type
  Color get typeColor {
    switch (standardizedContentType.toLowerCase()) {
      case 'url/website':
        return Colors.blue;
      case 'phone number':
        return Colors.green;
      case 'email address':
      case 'email message':
        return Colors.orange;
      case 'wifi network':
        return Colors.purple;
      case 'location':
        return Colors.red;
      case 'contact':
        return Colors.indigo;
      case 'calendar event':
        return Colors.teal;
      case 'product code':
        return Colors.brown;
      case 'text':
        return Colors.blueGrey;
      default:
        return Colors.grey.shade700;
    }
  }

  // Get a user-friendly display name for the barcode type
  String get displayName {
    if (isCustomized) {
      return 'Custom ${isQrCode ? "QR Code" : "Barcode"}';
    }

    if (barcodeType.isNotEmpty && barcodeType != 'TEXT') {
      return barcodeType;
    }

    return standardizedContentType;
  }

  // Get gradient colors for this type
  List<Color> get gradientColors {
    switch (standardizedContentType.toLowerCase()) {
      case 'url/website':
        return [Colors.blue.shade600, Colors.blue.shade900];
      case 'phone number':
        return [Colors.green.shade600, Colors.green.shade900];
      case 'email address':
      case 'email message':
        return [Colors.orange, Colors.deepOrange];
      case 'wifi network':
        return [Colors.purple, Colors.deepPurple];
      case 'location':
        return [Colors.red.shade600, Colors.red.shade900];
      case 'contact':
        return [Colors.indigo, Colors.blueAccent];
      case 'calendar event':
        return [Colors.teal, Colors.tealAccent];
      case 'product code':
        return [Colors.brown, Colors.brown.shade700];
      default:
        return [Colors.blueGrey, Colors.blueGrey.shade800];
    }
  }

  // Check if this scan is identical to another one
  bool isIdenticalTo(BarcodeScan other) {
    return barcodeValue == other.barcodeValue &&
        barcodeFormat == other.barcodeFormat;
  }
}

// Extension to parse barcode formats
extension BarcodeFormatExtension on String {
  bool get isQrCodeFormat {
    final qrFormats = ['QR_CODE', 'AZTEC', 'DATA_MATRIX'];
    return qrFormats.contains(this) || this.contains('QR');
  }
}
