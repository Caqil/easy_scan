import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 2)
class AppSettings extends HiveObject {
  @HiveField(0)
  bool darkMode;

  @HiveField(1)
  bool biometricAuthEnabled;

  @HiveField(2)
  String defaultSaveLocation;

  @HiveField(3)
  bool autoEnhanceImages;

  @HiveField(4)
  bool cloudBackupEnabled;

  @HiveField(5)
  int defaultPdfQuality;

  AppSettings({
    this.darkMode = false,
    this.biometricAuthEnabled = false,
    this.defaultSaveLocation = 'local',
    this.autoEnhanceImages = true,
    this.cloudBackupEnabled = false,
    this.defaultPdfQuality = 80,
  });
}
