import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/conversion_provider.dart';
import '../../../ui/common/app_bar.dart';
import 'components/conversion_button.dart';
import 'components/conversion_result.dart';
import 'components/file_selection.dart';
import 'components/format_selection.dart';
import 'components/advance_option.dart';

class ConversionScreen extends ConsumerWidget {
  const ConversionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversionStateProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: CustomAppBar(
        title: Text(
          "conversion_screen.title".tr(),
          style: GoogleFonts.lilitaOne(fontSize: 25.sp),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "conversion_screen.reset_tooltip".tr(),
            onPressed: () => ref.read(conversionStateProvider.notifier).reset(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header section
                _buildHeader(context, colorScheme),

                SizedBox(height: 24.h),

                // Format selection
                FormatSelectionSection(
                  state: state,
                ),

                SizedBox(height: 24.h),

                // File selection
                FileSelectionSection(
                  state: state,
                  ref: ref,
                ),

                SizedBox(height: 24.h),

                // Advanced options (conditionally displayed)
                if (state.inputFormat != null &&
                    state.outputFormat != null) ...[
                  AdvancedOptionsSection(
                    state: state,
                    ref: ref,
                  ),
                  SizedBox(height: 24.h),
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
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and description
        Text(
          "conversion_screen.header_title".tr(),
          style: GoogleFonts.notoSerif(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          "conversion_screen.header_description".tr(),
          style: GoogleFonts.notoSerif(
            fontSize: 14.sp,
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        // Horizontal divider with gradient
        Container(
          height: 2.h,
          margin: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
