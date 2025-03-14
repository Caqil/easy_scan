import 'package:easy_scan/ui/screen/conversion/components/advance_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../providers/conversion_provider.dart';
import '../../../ui/common/app_bar.dart';
import 'components/conversion_button.dart';
import 'components/conversion_result.dart';
import 'components/file_selection.dart';
import 'components/format_selection.dart';

class ConversionScreen extends ConsumerWidget {
  const ConversionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversionStateProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: const Text("Document Converter"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(conversionStateProvider.notifier).reset(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Output format selection
            FormatSelectionSection(
              state: state,
              ref: ref,
            ),

            SizedBox(height: 16.h),

            // File selection
            FileSelectionSection(
              state: state,
              ref: ref,
            ),

            SizedBox(height: 16.h),

            // Advanced options (conditionally displayed)
            if (state.inputFormat != null && state.outputFormat != null) ...[
              AdvancedOptionsSection(
                state: state,
                ref: ref,
              ),
              SizedBox(height: 16.h),
            ],

            // Error & Success messages
            if (state.error != null || state.convertedFilePath != null)
              ConversionResultSection(
                state: state,
                ref: ref,
              ),

            // Conversion button
            ConversionButton(
              state: state,
              ref: ref,
            ),

            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }
}
