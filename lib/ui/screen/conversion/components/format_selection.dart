import 'package:easy_scan/ui/screen/conversion/components/format_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../models/conversion.dart';
import '../../../../models/format_category.dart';
import '../../../../providers/conversion_provider.dart';
import '../components/section_container.dart';

class FormatSelectionSection extends StatelessWidget {
  final ConversionState state;
  final WidgetRef ref;

  const FormatSelectionSection({
    super.key,
    required this.state,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: "Conversion Format",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Input format dropdown
              Expanded(
                child: ChipFormatSelector(
                  formats: inputFormats,
                  selectedFormat: state.inputFormat,
                  onFormatSelected: (format) => ref
                      .read(conversionStateProvider.notifier)
                      .setInputFormat(format),
                  label: "Input",
                ),
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: ChipFormatSelector(
                  formats: outputFormats,
                  selectedFormat: state.outputFormat,
                  onFormatSelected: (format) => ref
                      .read(conversionStateProvider.notifier)
                      .setOutputFormat(format),
                  label: "Output",
                ),
              ),
            ],
          ),

          // Format selection hint
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.inputFormat != null && state.outputFormat != null)
                _buildFormatInfo(context)
              else
                _buildFormatSelectionHint(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatInfo(BuildContext context) {
    final inputFormat = state.inputFormat!;
    final outputFormat = state.outputFormat!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            inputFormat.icon,
            color: inputFormat.color,
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            inputFormat.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Icon(
              Icons.arrow_forward,
              size: 14.sp,
              color: Colors.grey,
            ),
          ),
          Icon(
            outputFormat.icon,
            color: outputFormat.color,
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            outputFormat.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelectionHint() {
    return Text(
      "Select both input and output formats to continue",
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 12.sp,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
