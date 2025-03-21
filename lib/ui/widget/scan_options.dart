import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
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
        AutoSizeText(
          'scan.scan_settings'.tr(),
          style: GoogleFonts.slabo27px(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        AutoSizeText('scan.color_mode'.tr()),
        const SizedBox(height: 8),
        SegmentedButton<ColorMode>(
          segments: [
            ButtonSegment(
              value: ColorMode.color,
              label: AutoSizeText('color_mode.color'.tr()),
              icon: Icon(Icons.color_lens),
            ),
            ButtonSegment(
              value: ColorMode.grayscale,
              label: AutoSizeText('color_mode.grayscale'.tr()),
              icon: Icon(Icons.browse_gallery_rounded),
            ),
            ButtonSegment(
              value: ColorMode.blackAndWhite,
              label: AutoSizeText('color_mode.black_and_white'.tr()),
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
        AutoSizeText('scan.scan_mode'.tr()),
        const SizedBox(height: 8),
        SegmentedButton<ScanMode>(
          segments: [
            ButtonSegment(
              value: ScanMode.auto,
              label: AutoSizeText('scan_mode.auto'.tr()),
              icon: Icon(Icons.auto_fix_high),
            ),
            ButtonSegment(
              value: ScanMode.manual,
              label: AutoSizeText('scan_mode.manual'.tr()),
              icon: Icon(Icons.tune),
            ),
            ButtonSegment(
              value: ScanMode.batch,
              label: AutoSizeText('scan_mode.batch'.tr()),
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
        AutoSizeText('scan.document_type'.tr()),
        const SizedBox(height: 8),
        SegmentedButton<DocumentType>(
          segments: [
            ButtonSegment(
              value: DocumentType.document,
              label: AutoSizeText('document_type.document'.tr()),
              icon: Icon(Icons.description),
            ),
            ButtonSegment(
              value: DocumentType.receipt,
              label: AutoSizeText('document_type.receipt'.tr()),
              icon: Icon(Icons.receipt),
            ),
            ButtonSegment(
              value: DocumentType.idCard,
              label: AutoSizeText('document_type.id_card'.tr()),
              icon: Icon(Icons.credit_card),
            ),
            ButtonSegment(
              value: DocumentType.photo,
              label: AutoSizeText('document_type.photo'.tr()),
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
          title: AutoSizeText('scan.enhance_image'.tr()),
          subtitle: AutoSizeText('scan.enhance_image_desc'.tr()),
          value: settings.enhanceImage,
          onChanged: (bool value) {
            onSettingsChanged(
              settings.copyWith(enhanceImage: value),
            );
          },
        ),
        SwitchListTile(
          title: AutoSizeText('scan.detect_edges'.tr()),
          subtitle: AutoSizeText('scan.detect_edges_desc'.tr()),
          value: settings.detectEdges,
          onChanged: (bool value) {
            onSettingsChanged(
              settings.copyWith(detectEdges: value),
            );
          },
        ),
        SwitchListTile(
          title: AutoSizeText('scan.ocr'.tr()),
          subtitle: AutoSizeText('scan.ocr_desc'.tr()),
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
            const AutoSizeText(
                'Quality: '), // This could be localized as "scan.quality" if desired
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
            AutoSizeText('${settings.quality}%'),
          ],
        ),
      ],
    );
  }
}
