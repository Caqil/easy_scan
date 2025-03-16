
import 'package:uuid/uuid.dart';

class BarcodeScan {
  final String id;
  final String barcodeValue;
  final String barcodeType;
  final String barcodeFormat;
  final DateTime timestamp;

  BarcodeScan({
    String? id,
    required this.barcodeValue,
    required this.barcodeType,
    required this.barcodeFormat,
    DateTime? timestamp,
  })  : this.id = id ?? const Uuid().v4(),
        this.timestamp = timestamp ?? DateTime.now();
  // For storage purposes
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcodeValue': barcodeValue,
      'barcodeType': barcodeType,
      'barcodeFormat': barcodeFormat,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory BarcodeScan.fromJson(Map<String, dynamic> json) {
    return BarcodeScan(
      id: json['id'],
      barcodeValue: json['barcodeValue'],
      barcodeType: json['barcodeType'],
      barcodeFormat: json['barcodeFormat'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
