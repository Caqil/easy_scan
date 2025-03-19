import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/conversion_state.dart';
import '../../../../models/format_category.dart';
import '../../../../providers/conversion_provider.dart';

class FormatSelectionSection extends ConsumerWidget {
  final ConversionState state;

  const FormatSelectionSection({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // More compact header
            Row(
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  color: colorScheme.primary,
                  size: 18.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  "format_selection.title".tr(), // Localized string
                  style: GoogleFonts.slabo27px(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Format selectors using chips
            Row(
              children: [
                // From format
                _buildChipSelector(
                  context: context,
                  label: "format_selection.from_label".tr(), // Localized string
                  selectedFormat: state.inputFormat,
                  onTap: () => _showFormatPicker(
                    context: context,
                    formats: inputFormats,
                    selectedFormat: state.inputFormat,
                    onFormatSelected: (format) => ref
                        .read(conversionStateProvider.notifier)
                        .setInputFormat(format),
                    label:
                        "format_selection.from_label".tr(), // Localized string
                  ),
                  colorScheme: colorScheme,
                ),

                // Arrow indicator
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 16.sp,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                // To format
                _buildChipSelector(
                  context: context,
                  label: "format_selection.to_label".tr(), // Localized string
                  selectedFormat: state.outputFormat,
                  onTap: () => _showFormatPicker(
                    context: context,
                    formats: outputFormats,
                    selectedFormat: state.outputFormat,
                    onFormatSelected: (format) => ref
                        .read(conversionStateProvider.notifier)
                        .setOutputFormat(format),
                    label: "format_selection.to_label".tr(), // Localized string
                  ),
                  colorScheme: colorScheme,
                ),
              ],
            ),

            SizedBox(height: 8.h),

            // Format info hint (more compact)
            if (state.inputFormat != null && state.outputFormat != null)
              _buildCompactFormatInfo(colorScheme),

            // Hint when formats not selected
            if (state.inputFormat == null || state.outputFormat == null)
              _buildCompactHint(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildChipSelector({
    required BuildContext context,
    required String label,
    required FormatOption? selectedFormat,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
          decoration: BoxDecoration(
            color: selectedFormat != null
                ? selectedFormat.color.withOpacity(0.1)
                : colorScheme.surfaceVariant.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: selectedFormat != null
                  ? selectedFormat.color.withOpacity(0.6)
                  : colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Format icon or label icon
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: selectedFormat != null
                      ? selectedFormat.color.withOpacity(0.2)
                      : colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  selectedFormat?.icon ?? Icons.file_present_outlined,
                  size: 14.sp,
                  color: selectedFormat?.color ?? colorScheme.primary,
                ),
              ),

              SizedBox(width: 6.w),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Label text
                    Text(
                      label,
                      style: GoogleFonts.slabo27px(
                        fontWeight: FontWeight.w700,
                        fontSize: 10.sp,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),

                    // Format name or placeholder
                    Text(
                      selectedFormat?.name ??
                          "format_selection.select_placeholder"
                              .tr(), // Localized string
                      style: GoogleFonts.slabo27px(
                        fontSize: 13.sp,
                        fontWeight: selectedFormat != null
                            ? FontWeight.bold
                            : FontWeight.w700,
                        color: selectedFormat != null
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.keyboard_arrow_down,
                size: 16.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactFormatInfo(ColorScheme colorScheme) {
    final inputFormat = state.inputFormat!;
    final outputFormat = state.outputFormat!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline,
            size: 14.sp,
            color: colorScheme.primary,
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp,
                  color: colorScheme.onSurfaceVariant,
                ),
                children: [
                  TextSpan(
                    text: "format_selection.format_info.converting".tr(
                        namedArgs: {
                          'input': inputFormat.name,
                          'output': outputFormat.name
                        }),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHint(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 14.sp,
            color: Colors.amber.shade800,
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              "format_selection.format_info.hint".tr(), // Localized string
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
                fontSize: 12.sp,
                color: Colors.amber.shade800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showFormatPicker({
    required BuildContext context,
    required List<FormatOption> formats,
    required FormatOption? selectedFormat,
    required Function(FormatOption) onFormatSelected,
    required String label,
  }) {
    // Show format picker
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => FormatPickerSheet(
        formats: formats,
        selectedFormat: selectedFormat,
        onFormatSelected: onFormatSelected,
        label: label,
      ),
    );
  }
}

class FormatPickerSheet extends StatefulWidget {
  final List<FormatOption> formats;
  final FormatOption? selectedFormat;
  final Function(FormatOption) onFormatSelected;
  final String label;

  const FormatPickerSheet({
    super.key,
    required this.formats,
    required this.selectedFormat,
    required this.onFormatSelected,
    required this.label,
  });

  @override
  State<FormatPickerSheet> createState() => _FormatPickerSheetState();
}

class _FormatPickerSheetState extends State<FormatPickerSheet> {
  String _searchQuery = '';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Group formats
    Map<String, List<FormatOption>> groupedFormats = _groupFormats();
    // Filtered formats for search
    final filteredFormats = _searchQuery.isEmpty
        ? widget.formats
        : widget.formats
            .where((f) =>
                f.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.symmetric(vertical: 8.h),
            height: 4.h,
            width: 40.w,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                Text(
                  "format_selection.format_picker.title".tr(
                      namedArgs: {'label': widget.label}), // Localized string
                  style: GoogleFonts.slabo27px(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                // Search field
                Container(
                  width: 140.w,
                  height: 36.h,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withOpacity(0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText:
                          "format_selection.format_picker.search_placeholder"
                              .tr(), // Localized string
                      hintStyle: TextStyle(fontSize: 13.sp),
                      prefixIcon: Icon(Icons.search, size: 16.sp),
                      border: InputBorder.none,
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _controller.clear();
                                setState(() => _searchQuery = '');
                              },
                              child: Icon(Icons.clear, size: 16.sp),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Format list
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResults(filteredFormats)
                : _buildCategoryList(groupedFormats),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<FormatOption> formats) {
    if (formats.isEmpty) {
      return Center(
        child: Text(
          "format_selection.format_picker.no_formats_found"
              .tr(), // Localized string
          style: GoogleFonts.slabo27px(
              fontWeight: FontWeight.w700, color: Colors.grey),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: formats.map((format) => _buildFormatChip(format)).toList(),
      ),
    );
  }

  Widget _buildCategoryList(Map<String, List<FormatOption>> groupedFormats) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: groupedFormats.length,
      itemBuilder: (context, index) {
        final category = groupedFormats.keys.elementAt(index);
        final formats = groupedFormats[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Padding(
              padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
              child: Text(
                "format_selection.format_picker.categories.$category"
                    .tr(), // Localized string
                style: GoogleFonts.slabo27px(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Format chips
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children:
                  formats.map((format) => _buildFormatChip(format)).toList(),
            ),
            SizedBox(height: 16.h),
          ],
        );
      },
    );
  }

  Widget _buildFormatChip(FormatOption format) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = widget.selectedFormat?.id == format.id;

    return InkWell(
      onTap: () {
        widget.onFormatSelected(format);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10.w,
          vertical: 6.h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? format.color.withOpacity(0.1)
              : colorScheme.surfaceContainerHighest.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? format.color
                : colorScheme.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              format.icon,
              size: 16.sp,
              color: format.color,
            ),
            SizedBox(width: 4.w),
            Text(
              format.name,
              style: GoogleFonts.slabo27px(
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w700,
              ),
            ),
            if (isSelected) ...[
              SizedBox(width: 4.w),
              Icon(
                Icons.check_circle,
                size: 14.sp,
                color: format.color,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, List<FormatOption>> _groupFormats() {
    Map<String, List<FormatOption>> grouped = {};

    for (var format in widget.formats) {
      String category = 'other'; // Default category

      if (['pdf', 'docx', 'txt', 'rtf'].contains(format.id.toLowerCase())) {
        category = 'documents';
      } else if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'tiff']
          .contains(format.id.toLowerCase())) {
        category = 'images';
      } else if (['xlsx'].contains(format.id.toLowerCase())) {
        category = 'spreadsheets';
      } else if (['pptx'].contains(format.id.toLowerCase())) {
        category = 'presentations';
      }

      grouped.putIfAbsent(category, () => []).add(format);
    }

    // Sort formats in each category
    for (var category in grouped.keys) {
      grouped[category]!.sort((a, b) => a.name.compareTo(b.name));
    }

    return grouped;
  }
}
