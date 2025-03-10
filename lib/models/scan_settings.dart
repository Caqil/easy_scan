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
