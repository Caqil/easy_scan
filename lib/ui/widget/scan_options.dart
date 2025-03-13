import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/scan_settings.dart';

class ScanOptionsWidget extends StatelessWidget {
  final ScanSettings settings;
  final Function(ScanSettings) onSettingsChanged;

  const ScanOptionsWidget({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      shrinkWrap: true,
      children: [
        Text(
          'Scan Settings',
          style: GoogleFonts.notoSerif(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text('Color Mode'),
        const SizedBox(height: 8),
        SegmentedButton<ColorMode>(
          segments: [
            ButtonSegment(
              value: ColorMode.color,
              label: Text('Color'),
              icon: Icon(Icons.color_lens),
            ),
            ButtonSegment(
              value: ColorMode.grayscale,
              label: Text('Gray'),
              icon: Icon(Icons.browse_gallery_rounded),
            ),
            ButtonSegment(
              value: ColorMode.blackAndWhite,
              label: Text('B&W'),
              icon: Icon(Icons.monochrome_photos),
            ),
          ],
          selected: {settings.colorMode},
          onSelectionChanged: (Set<ColorMode> newSelection) {
            onSettingsChanged(
              settings.copyWith(colorMode: newSelection.first),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text('Scan Mode'),
        const SizedBox(height: 8),
        SegmentedButton<ScanMode>(
          segments: const [
            ButtonSegment(
              value: ScanMode.auto,
              label: Text('Auto'),
              icon: Icon(Icons.auto_fix_high),
            ),
            ButtonSegment(
              value: ScanMode.manual,
              label: Text('Manual'),
              icon: Icon(Icons.tune),
            ),
            ButtonSegment(
              value: ScanMode.batch,
              label: Text('Batch'),
              icon: Icon(Icons.burst_mode),
            ),
          ],
          selected: {settings.scanMode},
          onSelectionChanged: (Set<ScanMode> newSelection) {
            onSettingsChanged(
              settings.copyWith(scanMode: newSelection.first),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text('Document Type'),
        const SizedBox(height: 8),
        SegmentedButton<DocumentType>(
          segments: const [
            ButtonSegment(
              value: DocumentType.document,
              label: Text('Document'),
              icon: Icon(Icons.description),
            ),
            ButtonSegment(
              value: DocumentType.receipt,
              label: Text('Receipt'),
              icon: Icon(Icons.receipt),
            ),
            ButtonSegment(
              value: DocumentType.idCard,
              label: Text('ID Card'),
              icon: Icon(Icons.credit_card),
            ),
            ButtonSegment(
              value: DocumentType.photo,
              label: Text('Photo'),
              icon: Icon(Icons.photo),
            ),
          ],
          selected: {settings.documentType},
          onSelectionChanged: (Set<DocumentType> newSelection) {
            onSettingsChanged(
              settings.copyWith(documentType: newSelection.first),
            );
          },
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Enhance Image'),
          subtitle: const Text('Automatically improve quality'),
          value: settings.enhanceImage,
          onChanged: (bool value) {
            onSettingsChanged(
              settings.copyWith(enhanceImage: value),
            );
          },
        ),
        SwitchListTile(
          title: const Text('Detect Edges'),
          subtitle: const Text('Find document boundaries'),
          value: settings.detectEdges,
          onChanged: (bool value) {
            onSettingsChanged(
              settings.copyWith(detectEdges: value),
            );
          },
        ),
        SwitchListTile(
          title: const Text('OCR'),
          subtitle: const Text('Extract text from document'),
          value: settings.enableOCR,
          onChanged: (bool value) {
            onSettingsChanged(
              settings.copyWith(enableOCR: value),
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Quality: '),
            Expanded(
              child: Slider(
                value: settings.quality.toDouble(),
                min: 30,
                max: 100,
                divisions: 7,
                label: '${settings.quality}%',
                onChanged: (double value) {
                  onSettingsChanged(
                    settings.copyWith(quality: value.round()),
                  );
                },
              ),
            ),
            Text('${settings.quality}%'),
          ],
        ),
      ],
    );
  }
}
