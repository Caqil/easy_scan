import 'package:flutter/material.dart';

enum ScanMode {
  auto, // Automatic mode (default)
  manual, // Manual adjustments
  batch // Multiple pages in succession
}

enum ColorMode {
  color, // Original colors
  grayscale, // Grayscale version
  blackAndWhite // Black and white (high contrast)
}

enum DocumentType {
  document, // Default document type
  receipt, // Receipt with optimized settings
  idCard, // ID card with optimized settings
  photo // Photo with original quality
}

class ScanSettings {
  ScanMode scanMode;
  ColorMode colorMode;
  DocumentType documentType;
  bool enhanceImage;
  bool detectEdges;
  bool enableOCR;
  int quality; // 1-100

  ScanSettings({
    this.scanMode = ScanMode.auto,
    this.colorMode = ColorMode.color,
    this.documentType = DocumentType.document,
    this.enhanceImage = true,
    this.detectEdges = true,
    this.enableOCR = false,
    this.quality = 80,
  });

  // Create a copy of settings with some changes
  ScanSettings copyWith({
    ScanMode? scanMode,
    ColorMode? colorMode,
    DocumentType? documentType,
    bool? enhanceImage,
    bool? detectEdges,
    bool? enableOCR,
    int? quality,
  }) {
    return ScanSettings(
      scanMode: scanMode ?? this.scanMode,
      colorMode: colorMode ?? this.colorMode,
      documentType: documentType ?? this.documentType,
      enhanceImage: enhanceImage ?? this.enhanceImage,
      detectEdges: detectEdges ?? this.detectEdges,
      enableOCR: enableOCR ?? this.enableOCR,
      quality: quality ?? this.quality,
    );
  }
}

/// Extension for ColorMode enum to provide additional functionality
extension ColorModeExtension on ColorMode {
  /// Get display name of the color mode
  String get displayName {
    switch (this) {
      case ColorMode.color:
        return 'Color';
      case ColorMode.grayscale:
        return 'Grayscale';
      case ColorMode.blackAndWhite:
        return 'Black & White';
    }
  }

  /// Get icon for the color mode
  IconData get icon {
    switch (this) {
      case ColorMode.color:
        return Icons.color_lens;
      case ColorMode.grayscale:
        return Icons.browse_gallery_rounded;
      case ColorMode.blackAndWhite:
        return Icons.monochrome_photos;
    }
  }

  /// Get description of the color mode
  String get description {
    switch (this) {
      case ColorMode.color:
        return 'Preserve original colors';
      case ColorMode.grayscale:
        return 'Convert to shades of gray';
      case ColorMode.blackAndWhite:
        return 'High contrast black and white';
    }
  }

  /// Get processing parameters for this color mode
  Map<String, dynamic> get processingParams {
    switch (this) {
      case ColorMode.color:
        return {
          'contrast': 1.2,
          'brightness': 1.0,
          'saturation': 1.1,
          'preserveColors': true
        };
      case ColorMode.grayscale:
        return {
          'contrast': 1.3,
          'brightness': 1.0,
          'saturation': 0.0,
          'preserveColors': false
        };
      case ColorMode.blackAndWhite:
        return {
          'contrast': 1.5,
          'brightness': 1.0,
          'saturation': 0.0,
          'threshold': 128,
          'preserveColors': false
        };
    }
  }
}

/// Extension for ScanMode enum to provide additional functionality
extension ScanModeExtension on ScanMode {
  /// Get display name of the scan mode
  String get displayName {
    switch (this) {
      case ScanMode.auto:
        return 'Auto';
      case ScanMode.manual:
        return 'Manual';
      case ScanMode.batch:
        return 'Batch';
    }
  }

  /// Get icon for the scan mode
  IconData get icon {
    switch (this) {
      case ScanMode.auto:
        return Icons.auto_fix_high;
      case ScanMode.manual:
        return Icons.tune;
      case ScanMode.batch:
        return Icons.burst_mode;
    }
  }

  /// Get description of the scan mode
  String get description {
    switch (this) {
      case ScanMode.auto:
        return 'Automatically detect and process documents';
      case ScanMode.manual:
        return 'Manually adjust settings for each scan';
      case ScanMode.batch:
        return 'Scan multiple pages in succession';
    }
  }

  /// Get configuration for this scan mode
  Map<String, dynamic> get configuration {
    switch (this) {
      case ScanMode.auto:
        return {
          'autoDetectEdges': true,
          'autoEnhance': true,
          'stayInCameraScreen': false,
          'confirmAfterCapture': true
        };
      case ScanMode.manual:
        return {
          'autoDetectEdges': false,
          'autoEnhance': false,
          'stayInCameraScreen': false,
          'confirmAfterCapture': true,
          'showAdjustmentControls': true
        };
      case ScanMode.batch:
        return {
          'autoDetectEdges': true,
          'autoEnhance': true,
          'stayInCameraScreen': true,
          'confirmAfterCapture': false,
          'showCounter': true
        };
    }
  }
}

/// Extension for DocumentType enum to provide additional functionality
extension DocumentTypeExtension on DocumentType {
  /// Get display name of the document type
  String get displayName {
    switch (this) {
      case DocumentType.document:
        return 'Document';
      case DocumentType.receipt:
        return 'Receipt';
      case DocumentType.idCard:
        return 'ID Card';
      case DocumentType.photo:
        return 'Photo';
    }
  }

  /// Get icon for the document type
  IconData get icon {
    switch (this) {
      case DocumentType.document:
        return Icons.description;
      case DocumentType.receipt:
        return Icons.receipt;
      case DocumentType.idCard:
        return Icons.credit_card;
      case DocumentType.photo:
        return Icons.photo;
    }
  }

  /// Get description of the document type
  String get description {
    switch (this) {
      case DocumentType.document:
        return 'Standard document with text';
      case DocumentType.receipt:
        return 'Narrow receipt with small text';
      case DocumentType.idCard:
        return 'ID card or small document';
      case DocumentType.photo:
        return 'Photo with high image quality';
    }
  }

  /// Get optimized settings for this document type
  ScanSettings get optimizedSettings {
    switch (this) {
      case DocumentType.document:
        return ScanSettings(
          colorMode: ColorMode.color,
          enhanceImage: true,
          detectEdges: true,
          enableOCR: true,
          quality: 80,
        );
      case DocumentType.receipt:
        return ScanSettings(
          colorMode: ColorMode.grayscale,
          enhanceImage: true,
          detectEdges: true,
          enableOCR: true,
          quality: 85,
        );
      case DocumentType.idCard:
        return ScanSettings(
          colorMode: ColorMode.color,
          enhanceImage: true,
          detectEdges: true,
          enableOCR: false,
          quality: 90,
        );
      case DocumentType.photo:
        return ScanSettings(
          colorMode: ColorMode.color,
          enhanceImage: false, // Preserve original quality
          detectEdges: false,
          enableOCR: false,
          quality: 95, // Higher quality
        );
    }
  }

  /// Get recommended aspect ratio for this document type
  double get aspectRatio {
    switch (this) {
      case DocumentType.document:
        return 1.414; // A4 paper ratio
      case DocumentType.receipt:
        return 0.33; // Long and narrow
      case DocumentType.idCard:
        return 1.58; // ID card typical ratio
      case DocumentType.photo:
        return 1.33; // 4:3 photo ratio
    }
  }
}

/// Utility function to get all available color modes
List<ColorMode> getAllColorModes() {
  return ColorMode.values;
}

/// Utility function to get all available scan modes
List<ScanMode> getAllScanModes() {
  return ScanMode.values;
}

/// Utility function to get all available document types
List<DocumentType> getAllDocumentTypes() {
  return DocumentType.values;
}

/// Factory class to create preset scan settings
class ScanSettingsFactory {
  /// Create document preset scan settings
  static ScanSettings documentPreset() {
    return DocumentType.document.optimizedSettings;
  }

  /// Create receipt preset scan settings
  static ScanSettings receiptPreset() {
    return DocumentType.receipt.optimizedSettings;
  }

  /// Create ID card preset scan settings
  static ScanSettings idCardPreset() {
    return DocumentType.idCard.optimizedSettings;
  }

  /// Create photo preset scan settings
  static ScanSettings photoPreset() {
    return DocumentType.photo.optimizedSettings;
  }

  /// Create a high-quality preset for any type
  static ScanSettings highQualityPreset() {
    return ScanSettings(
      scanMode: ScanMode.manual,
      colorMode: ColorMode.color,
      documentType: DocumentType.document,
      enhanceImage: true,
      detectEdges: true,
      enableOCR: true,
      quality: 95,
    );
  }

  /// Create a speed-optimized preset for quick scanning
  static ScanSettings quickScanPreset() {
    return ScanSettings(
      scanMode: ScanMode.batch,
      colorMode: ColorMode.grayscale,
      documentType: DocumentType.document,
      enhanceImage: true,
      detectEdges: true,
      enableOCR: false, // Disable OCR for speed
      quality: 75, // Lower quality for speed
    );
  }
}
