import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/utils/file_utils.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import '../../../../models/conversion_state.dart';
import '../../../../providers/conversion_provider.dart';
import '../../../../utils/date_utils.dart';
import '../components/section_container.dart';

class FileSelectionSection extends StatelessWidget {
  final ConversionState state;
  final WidgetRef ref;

  const FileSelectionSection({
    super.key,
    required this.state,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return SectionContainer(
      title: "file_selection.title".tr(), // Localized string
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 8.h),
          if (state.selectedFile != null)
            _buildSelectedFileInfo(context)
          else
            _buildEmptyFileSelector(),
          SizedBox(height: 16.h),
          OutlinedButton.icon(
            onPressed: state.isConverting
                ? null
                : () => ref.read(conversionStateProvider.notifier).pickFile(),
            icon: const Icon(Icons.upload_file),
            label: AutoSizeText(
                "file_selection.select_file_button".tr()), // Localized string
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFileInfo(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            state.inputFormat?.icon ?? Icons.file_present,
            color: state.inputFormat?.color ??
                Theme.of(context).colorScheme.primary,
            size: 28.adaptiveSp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  path.basename(state.selectedFile!.path),
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.adaptiveSp,
                  ),
                ),
                SizedBox(height: 4.h),
                FutureBuilder<String>(
                  future: _getFileInfo(state.selectedFile!),
                  builder: (context, snapshot) {
                    final info = snapshot.data ??
                        "file_selection.file_info.loading"
                            .tr(); // Localized string
                    return AutoSizeText(
                      info,
                      style: GoogleFonts.slabo27px(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                        fontSize: 14.adaptiveSp,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFileSelector() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.file_upload_outlined,
            size: 40.adaptiveSp,
            color: Colors.grey,
          ),
          SizedBox(height: 12.h),
          AutoSizeText(
            "file_selection.no_file_selected.title".tr(), // Localized string
            style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700, fontSize: 16.adaptiveSp),
          ),
          SizedBox(height: 8.h),
          AutoSizeText(
            "file_selection.no_file_selected.subtitle".tr(), // Localized string
            style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
                fontSize: 14.adaptiveSp,
                color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<String> _getFileInfo(File file) async {
    try {
      final size = await file.length();
      final sizeStr = FileUtils.formatFileSize(size);
      final dateModified = await file.lastModified();
      return "file_selection.file_info.size_modified".tr(
        namedArgs: {
          'size': sizeStr,
          'modified': DateTimeUtils.getRelativeTime(dateModified)
        }, // Dynamic arguments
      );
    } catch (e) {
      return "file_selection.file_info.error".tr(); // Localized string
    }
  }
}
