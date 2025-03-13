import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/format_category.dart';
import '../../../providers/conversion_provider.dart';
import '../../../utils/date_utils.dart';
import '../../../ui/common/app_bar.dart';
import '../../../ui/common/dialogs.dart';
import '../../../ui/common/loading.dart';
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
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Input format section
                _buildSectionContainer(
                  context: context,
                  title: "Input Format",
                  child: FormatSelector(
                    formats: inputFormats,
                    selectedFormat: state.inputFormat,
                    onFormatSelected: (format) => ref
                        .read(conversionStateProvider.notifier)
                        .setInputFormat(format),
                  ),
                ),

                SizedBox(height: 16.h),

                // Output format section
                _buildSectionContainer(
                  context: context,
                  title: "Output Format",
                  child: FormatSelector(
                    formats: outputFormats,
                    selectedFormat: state.outputFormat,
                    onFormatSelected: (format) => ref
                        .read(conversionStateProvider.notifier)
                        .setOutputFormat(format),
                  ),
                ),

                SizedBox(height: 16.h),

                // File selection
                _buildSectionContainer(
                  context: context,
                  title: "Select File",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 8.h),
                      if (state.selectedFile != null)
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                state.inputFormat?.icon ?? Icons.file_present,
                                color: state.inputFormat?.color ??
                                    Theme.of(context).colorScheme.primary,
                                size: 28.sp,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      path.basename(state.selectedFile!.path),
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    FutureBuilder<String>(
                                      future: _getFileInfo(state.selectedFile!),
                                      builder: (context, snapshot) {
                                        final info = snapshot.data ??
                                            'Loading file info...';
                                        return Text(
                                          info,
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14.sp,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 24.h, horizontal: 16.w),
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
                                size: 40.sp,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                "No file selected",
                                style: TextStyle(fontSize: 16.sp),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                "Select a file to convert",
                                style: TextStyle(
                                    fontSize: 14.sp, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: 16.h),
                      ElevatedButton.icon(
                        onPressed: state.isConverting
                            ? null
                            : () => ref
                                .read(conversionStateProvider.notifier)
                                .pickFile(),
                        icon: const Icon(Icons.upload_file),
                        label: const Text("Select File"),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Advanced options (conditionally displayed)
                if (state.inputFormat != null &&
                    state.outputFormat != null) ...[
                  _buildSectionContainer(
                    context: context,
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
                          subtitle:
                              const Text("Extract text from scanned documents"),
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
                        if (state.outputFormat?.id == 'jpg' ||
                            state.outputFormat?.id == 'png' ||
                            state.outputFormat?.id == 'jpeg') ...[
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

                        // Password field (for PDF inputs)
                        if (state.inputFormat?.id == 'pdf') ...[
                          SizedBox(height: 16.h),
                          TextField(
                            decoration: InputDecoration(
                              labelText: "PDF Password (if protected)",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              hintText: "Leave empty if not password-protected",
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            enabled: !state.isConverting,
                            onChanged: (value) => ref
                                .read(conversionStateProvider.notifier)
                                .setPassword(value.isNotEmpty ? value : null),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                // Error message
                if (state.error != null) ...[
                  Container(
                    padding: EdgeInsets.all(16.w),
                    margin: EdgeInsets.only(bottom: 16.h),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade700, size: 20.sp),
                            SizedBox(width: 8.w),
                            Text(
                              "Conversion Failed",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          state.error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
                ],

                // Success message
                if (state.convertedFilePath != null) ...[
                  Container(
                    padding: EdgeInsets.all(16.w),
                    margin: EdgeInsets.only(bottom: 16.h),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Colors.green.shade700, size: 20.sp),
                            SizedBox(width: 8.w),
                            Text(
                              "Conversion Successful",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                                fontSize: 16.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                            "File saved to: ${path.basename(state.convertedFilePath!)}"),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    OpenFile.open(state.convertedFilePath!),
                                icon: const Icon(Icons.file_open),
                                label: const Text("Open"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Implement share functionality
                                  AppDialogs.showSnackBar(
                                    context,
                                    message: "Sharing file...",
                                  );
                                },
                                icon: const Icon(Icons.share),
                                label: const Text("Share"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Conversion button
                SizedBox(
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: (state.selectedFile == null ||
                            state.inputFormat == null ||
                            state.outputFormat == null ||
                            state.isConverting)
                        ? null
                        : () => ref
                            .read(conversionStateProvider.notifier)
                            .convertFile(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: state.isConverting
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20.w,
                                    height: 20.h,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  const Text("Converting..."),
                                ],
                              ),
                              SizedBox(height: 6.h),
                              LinearProgressIndicator(
                                value: state.progress,
                                backgroundColor: Colors.white30,
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  state.inputFormat?.icon ?? Icons.file_present,
                                  size: 20.sp),
                              SizedBox(width: 8.w),
                              Text(
                                "Convert",
                                style: TextStyle(fontSize: 16.sp),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                  state.outputFormat?.icon ??
                                      Icons.file_present,
                                  size: 20.sp),
                            ],
                          ),
                  ),
                ),

                SizedBox(height: 16.h),
              ],
            ),
          ),

          // Overlay loading indicator for conversion process
          if (state.isConverting)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: LoadingIndicator(message: "Converting file..."),
              ),
            ),
        ],
      ),
    );
  }

  // Helper widget for section containers to replace cards
  Widget _buildSectionContainer({
    required BuildContext context,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.r),
                topRight: Radius.circular(8.r),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing,
              ],
            ),
          ),

          // Content
          Container(
            padding: EdgeInsets.all(16.w),
            width: double.infinity,
            child: child,
          ),
        ],
      ),
    );
  }

  Future<String> _getFileInfo(File file) async {
    try {
      final size = await file.length();
      final sizeStr = _formatFileSize(size);
      final dateModified = await file.lastModified();
      return "$sizeStr • Modified ${DateTimeUtils.getRelativeTime(dateModified)}";
    } catch (e) {
      return "Error getting file info";
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Advanced Options Help"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _helpItem("OCR (Optical Character Recognition)",
                "Extracts text from images or scanned PDFs. Enables searching and text selection."),
            SizedBox(height: 8.h),
            _helpItem("Image Quality",
                "Higher quality produces larger files with better details. Lower quality reduces file size."),
            SizedBox(height: 8.h),
            _helpItem("PDF Password",
                "Required only if your source PDF is password-protected."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _helpItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(description),
      ],
    );
  }
}
