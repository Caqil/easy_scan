import 'package:hive/hive.dart';

part 'language.g.dart';

@HiveType(typeId: 0)
class Language {
  @HiveField(0)
  final String label;

  @HiveField(1)
  final String languageCode;

  @HiveField(2)
  final String countryCode;

  Language({
    required this.label,
    required this.languageCode,
    required this.countryCode,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      label: json['label'] ?? "Unknown",
      languageCode: json['language_code'] ?? "en",
      countryCode: json['country_code'] ?? "US",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'language_code': languageCode,
      'country_code': countryCode,
    };
  }
}
