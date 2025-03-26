// Add this to your lib/config/helper.dart file

/// Compression levels for PDF compression
enum CompressionLevel {
  /// Low compression - best quality
  low,

  /// Medium compression - balanced
  medium,

  /// High compression - smallest file size
  high
}

/// Helper class to map compression levels to values
class CompressionLevelMapper {
  /// Get estimated reduction percentage for a compression level
  static String getReductionEstimate(CompressionLevel level) {
    switch (level) {
      case CompressionLevel.low:
        return '20-30%';
      case CompressionLevel.medium:
        return '40-60%';
      case CompressionLevel.high:
        return '70-80%';
    }
  }

  /// Get quality percentage for a compression level
  static int getQualityPercentage(CompressionLevel level) {
    switch (level) {
      case CompressionLevel.low:
        return 80;
      case CompressionLevel.medium:
        return 50;
      case CompressionLevel.high:
        return 30;
    }
  }
}
