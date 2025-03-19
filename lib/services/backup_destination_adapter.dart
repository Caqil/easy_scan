// import 'package:hive/hive.dart';
// import 'package:scanpro/services/backup_service.dart'; // Adjust import based on BackupDestination location

// class BackupDestinationAdapter extends TypeAdapter<BackupDestination> {
//   @override
//   final int typeId = 5; // Unique ID (adjust if conflicts exist)

//   @override
//   BackupDestination read(BinaryReader reader) {
//     final index = reader.readByte();
//     return BackupDestination.values[index];
//   }

//   @override
//   void write(BinaryWriter writer, BackupDestination obj) {
//     writer.writeByte(obj.index);
//   }
// }
