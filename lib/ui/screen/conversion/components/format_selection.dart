import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/conversion_state.dart';
import '../../../../models/format_category.dart';
import '../../../../providers/conversion_provider.dart';

class FormatSelectionSection extends ConsumerWidget {
  final ConversionState state;
  final WidgetRef ref;

  const FormatSelectionSection({
    super.key,
    required this.state,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(10.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title with icon
            Row(
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  color: colorScheme.primary,
                  size: 22.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  "Format Selection",
                  style: GoogleFonts.notoSerif(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Format selectors
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Input format
                Expanded(
                  child: _buildFormatSelector(
                    context: context,
                    formats: inputFormats,
                    selectedFormat: state.inputFormat,
                    onFormatSelected: (format) => ref
                        .read(conversionStateProvider.notifier)
                        .setInputFormat(format),
                    label: "From",
                    colorScheme: colorScheme,
                  ),
                ),
                SizedBox(width: 4.h),
                Expanded(
                  child: _buildFormatSelector(
                    context: context,
                    formats: outputFormats,
                    selectedFormat: state.outputFormat,
                    onFormatSelected: (format) => ref
                        .read(conversionStateProvider.notifier)
                        .setOutputFormat(format),
                    label: "To",
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),

            SizedBox(height: 7.h),

            // Format info or hint
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: state.inputFormat != null && state.outputFormat != null
                  ? _buildFormatInfo(context, colorScheme)
                  : _buildFormatSelectionHint(colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSelector({
    required BuildContext context,
    required List<FormatOption> formats,
    required FormatOption? selectedFormat,
    required Function(FormatOption) onFormatSelected,
    required String label,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: GoogleFonts.notoSerif(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        SizedBox(height: 8.h),

        // Selector button
        InkWell(
          onTap: () => _showFormatPicker(
            context: context,
            formats: formats,
            selectedFormat: selectedFormat,
            onFormatSelected: onFormatSelected,
            label: label,
          ),
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: selectedFormat != null
                    ? colorScheme.primary.withOpacity(0.5)
                    : colorScheme.outlineVariant.withOpacity(0.5),
                width: 1.5,
              ),
              color: selectedFormat != null
                  ? colorScheme.primaryContainer.withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                if (selectedFormat != null) ...[
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: selectedFormat.color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      selectedFormat.icon,
                      color: selectedFormat.color,
                      size: 18.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      selectedFormat.name,
                      style: GoogleFonts.notoSerif(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else
                  Expanded(
                    child: Text(
                      'Select $label Format',
                      style: GoogleFonts.notoSerif(
                        fontSize: 14.sp,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                  ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormatInfo(BuildContext context, ColorScheme colorScheme) {
    final inputFormat = state.inputFormat!;
    final outputFormat = state.outputFormat!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18.sp,
            color: colorScheme.primary,
          ),
          SizedBox(width: 10.w),
          Text(
            "Converting ",
            style: GoogleFonts.notoSerif(
              fontSize: 13.sp,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            inputFormat.name,
            style: GoogleFonts.notoSerif(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: inputFormat.color,
            ),
          ),
          Text(
            " to ",
            style: GoogleFonts.notoSerif(
              fontSize: 13.sp,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            outputFormat.name,
            style: GoogleFonts.notoSerif(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: outputFormat.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelectionHint(ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18.sp,
            color: Colors.amber.shade800,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              "Please select both input and output formats to continue",
              style: GoogleFonts.notoSerif(
                fontSize: 13.sp,
                color: Colors.amber.shade800,
              ),
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
    // Show the format picker bottom sheet here
    // You can implement this using showModalBottomSheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FormatPickerBottomSheet(
        formats: formats,
        selectedFormat: selectedFormat,
        onFormatSelected: onFormatSelected,
        label: label,
      ),
    );
  }
}

class FormatPickerBottomSheet extends StatefulWidget {
  final List<FormatOption> formats;
  final FormatOption? selectedFormat;
  final Function(FormatOption) onFormatSelected;
  final String label;

  const FormatPickerBottomSheet({
    Key? key,
    required this.formats,
    required this.selectedFormat,
    required this.onFormatSelected,
    required this.label,
  }) : super(key: key);

  @override
  State<FormatPickerBottomSheet> createState() =>
      _FormatPickerBottomSheetState();
}

class _FormatPickerBottomSheetState extends State<FormatPickerBottomSheet> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Group formats by category
    Map<String, List<FormatOption>> groupedFormats = _groupFormats();

    // Filter formats based on search query
    final List<FormatOption> filteredFormats = _searchQuery.isEmpty
        ? widget.formats
        : widget.formats
            .where((format) =>
                format.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 12.h),
              height: 4.h,
              width: 40.w,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Icon(Icons.format_shapes_rounded, color: colorScheme.primary),
                SizedBox(width: 12.w),
                Text(
                  "Select ${widget.label} Format",
                  style: GoogleFonts.notoSerif(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Search box
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search formats...',
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Format list
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResults(filteredFormats, colorScheme)
                : _buildCategorizedFormats(groupedFormats, colorScheme),
          ),

          // Safe area padding at bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
      List<FormatOption> formats, ColorScheme colorScheme) {
    if (formats.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48.sp,
              color: Colors.grey,
            ),
            SizedBox(height: 16.h),
            Text(
              'No formats found',
              style: GoogleFonts.notoSerif(
                fontSize: 16.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
        ),
        itemCount: formats.length,
        itemBuilder: (context, index) {
          return _buildFormatChip(formats[index], colorScheme);
        },
      ),
    );
  }

  Widget _buildCategorizedFormats(
    Map<String, List<FormatOption>> groupedFormats,
    ColorScheme colorScheme,
  ) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: groupedFormats.length,
      itemBuilder: (context, index) {
        final category = groupedFormats.keys.elementAt(index);
        final formats = groupedFormats[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Padding(
              padding: EdgeInsets.only(bottom: 12.h, top: index > 0 ? 24.h : 0),
              child: Row(
                children: [
                  Container(
                    width: 6.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    category,
                    style: GoogleFonts.notoSerif(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Formats grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
              ),
              itemCount: formats.length,
              itemBuilder: (context, formatIndex) {
                return _buildFormatChip(formats[formatIndex], colorScheme);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormatChip(FormatOption format, ColorScheme colorScheme) {
    final bool isSelected = widget.selectedFormat?.id == format.id;

    return InkWell(
      onTap: () {
        widget.onFormatSelected(format);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color:
              isSelected ? format.color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? format.color
                : colorScheme.outlineVariant.withOpacity(0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: format.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                format.icon,
                color: format.color,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    format.name,
                    style: GoogleFonts.notoSerif(
                      fontSize: 13.sp,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    format.id.toUpperCase(),
                    style: GoogleFonts.notoSerif(
                      fontSize: 10.sp,
                      color: isSelected ? format.color : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: format.color,
                size: 18.sp,
              ),
          ],
        ),
      ),
    );
  }

  Map<String, List<FormatOption>> _groupFormats() {
    Map<String, List<FormatOption>> grouped = {};

    // Group formats by type
    for (var format in widget.formats) {
      String category = 'Other';

      // Determine category based on format
      if (['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt']
          .contains(format.id.toLowerCase())) {
        category = 'Documents';
      } else if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'tiff']
          .contains(format.id.toLowerCase())) {
        category = 'Images';
      } else if (['xlsx', 'xls', 'csv', 'ods']
          .contains(format.id.toLowerCase())) {
        category = 'Spreadsheets';
      } else if (['pptx', 'ppt', 'odp'].contains(format.id.toLowerCase())) {
        category = 'Presentations';
      }

      grouped.putIfAbsent(category, () => []).add(format);
    }

    // Sort formats within each category
    for (var category in grouped.keys) {
      grouped[category]!.sort((a, b) => a.name.compareTo(b.name));
    }

    return grouped;
  }
}
