
import 'package:easy_scan/models/barcode_scan.dart';
import 'package:hive/hive.dart';

class BarcodeScanAdapter extends TypeAdapter<BarcodeScan> {
  @override
  final int typeId =
      5; // Choose a unique typeId that doesn't conflict with other adapters

  @override
  BarcodeScan read(BinaryReader reader) {
    return BarcodeScan(
      id: reader.readString(),
      barcodeValue: reader.readString(),
      barcodeType: reader.readString(),
      barcodeFormat: reader.readString(),
      timestamp: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, BarcodeScan obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.barcodeValue);
    writer.writeString(obj.barcodeType);
    writer.writeString(obj.barcodeFormat);
    writer.writeString(obj.timestamp.toIso8601String());
  }
}
