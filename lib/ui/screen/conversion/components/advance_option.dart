import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../models/conversion_state.dart';
import '../../../../providers/conversion_provider.dart';
import '../components/section_container.dart';
import '../components/help_dialog.dart';

class AdvancedOptionsSection extends StatelessWidget {
  final ConversionState state;
  final WidgetRef ref;

  const AdvancedOptionsSection({
    super.key,
    required this.state,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: "Advanced Options",
      trailing: IconButton(
        icon: Icon(Icons.help_outline, size: 20.sp),
        onPressed: () => _showHelpDialog(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // OCR option
          SwitchListTile(
            title: const Text("Enable OCR"),
            subtitle: const Text("Extract text from scanned documents"),
            secondary: Icon(
              Icons.document_scanner,
              color: state.ocrEnabled
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            value: state.ocrEnabled,
            onChanged: state.isConverting
                ? null
                : (value) => ref
                    .read(conversionStateProvider.notifier)
                    .setOcrEnabled(value),
          ),

          // Quality slider (for image outputs)
          if (_showQualitySlider()) ...[
            SizedBox(height: 8.h),
            ListTile(
              leading: const Icon(Icons.high_quality),
              title: const Text("Image Quality"),
              subtitle: Slider(
                value: state.quality.toDouble(),
                min: 10,
                max: 100,
                divisions: 18,
                label: "${state.quality}%",
                onChanged: state.isConverting
                    ? null
                    : (value) => ref
                        .read(conversionStateProvider.notifier)
                        .setQuality(value.toInt()),
              ),
              trailing: Text(
                "${state.quality}%",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _showQualitySlider() {
    final outputFormatId = state.outputFormat?.id.toLowerCase();
    return outputFormatId == 'jpg' ||
        outputFormatId == 'png' ||
        outputFormatId == 'jpeg';
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const HelpDialog(),
    );
  }
}
