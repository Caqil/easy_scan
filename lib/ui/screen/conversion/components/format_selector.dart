import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/format_category.dart';

class ChipFormatSelector extends StatelessWidget {
  final List<FormatOption> formats;
  final FormatOption? selectedFormat;
  final Function(FormatOption) onFormatSelected;
  final String label;

  const ChipFormatSelector({
    super.key,
    required this.formats,
    required this.selectedFormat,
    required this.onFormatSelected,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoSizeText(
          label,
          style: GoogleFonts.slabo27px(
            fontWeight: FontWeight.w700,
            fontSize: 14.adaptiveSp,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8.h),
        InkWell(
          onTap: () => _showFormatSelector(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                if (selectedFormat != null) ...[
                  Icon(
                    selectedFormat!.icon,
                    color: selectedFormat!.color,
                    size: 24.adaptiveSp,
                  ),
                  SizedBox(width: 12.w),
                  AutoSizeText(
                    selectedFormat!.name,
                    style: GoogleFonts.slabo27px(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.adaptiveSp,
                    ),
                  ),
                ] else
                  AutoSizeText(
                    '$label Format',
                    style: GoogleFonts.slabo27px(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.adaptiveSp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFormatSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      builder: (context) => FormatSelectorBottomSheet(
        formats: formats,
        selectedFormat: selectedFormat,
        onFormatSelected: (format) {
          Navigator.pop(context);
          onFormatSelected(format);
        },
        label: label,
      ),
    );
  }
}

class FormatSelectorBottomSheet extends StatefulWidget {
  final List<FormatOption> formats;
  final FormatOption? selectedFormat;
  final Function(FormatOption) onFormatSelected;
  final String label;

  const FormatSelectorBottomSheet({
    super.key,
    required this.formats,
    required this.selectedFormat,
    required this.onFormatSelected,
    required this.label,
  });

  @override
  State<FormatSelectorBottomSheet> createState() =>
      _FormatSelectorBottomSheetState();
}

class _FormatSelectorBottomSheetState extends State<FormatSelectorBottomSheet> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Group formats by category or first letter
    final groupedFormats = _groupFormats();

    // Filter formats by search query
    final List<FormatOption> filteredFormats = _searchQuery.isEmpty
        ? widget.formats
        : widget.formats
            .where((format) =>
                format.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 8.h),
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
            padding: EdgeInsets.all(16.h),
            child: AutoSizeText(
              tr('chip_format_selector.select_format',
                  namedArgs: {'label': widget.label}),
              style: GoogleFonts.slabo27px(
                fontSize: 18.adaptiveSp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Search box
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'chip_format_selector.search_placeholder'.tr(),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          SizedBox(height: 16.h),

          // Format chips
          Flexible(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResults(filteredFormats)
                : _buildGroupedFormats(groupedFormats),
          ),

          // Safe area padding at bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<FormatOption> formats) {
    if (formats.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48.adaptiveSp, color: Colors.grey),
              SizedBox(height: 16.h),
              AutoSizeText(
                'No formats found',
                style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.adaptiveSp.adaptiveSp),
              ),
            ],
          ),
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

  Widget _buildGroupedFormats(Map<String, List<FormatOption>> groupedFormats) {
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: groupedFormats.length,
      itemBuilder: (context, index) {
        final category = groupedFormats.keys.elementAt(index);
        final formats = groupedFormats[category]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: AutoSizeText(
                category,
                style: GoogleFonts.slabo27px(
                  fontSize: 14.adaptiveSp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            Wrap(
              spacing: 4.w,
              runSpacing: 4.h,
              children:
                  formats.map((format) => _buildFormatChip(format)).toList(),
            ),
            SizedBox(height: 8.h),
          ],
        );
      },
    );
  }

  Widget _buildFormatChip(FormatOption format) {
    final isSelected = widget.selectedFormat?.id == format.id;

    return FilterChip(
      avatar: Icon(
        format.icon,
        color: isSelected ? Colors.white : format.color,
        size: 15.adaptiveSp,
      ),
      label: AutoSizeText(format.name),
      selected: isSelected,
      showCheckmark: false,
      backgroundColor: Colors.grey.shade100,
      selectedColor: format.color,
      labelStyle: GoogleFonts.slabo27px(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w700,
      ),
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
      onSelected: (_) => widget.onFormatSelected(format),
    );
  }

  Map<String, List<FormatOption>> _groupFormats() {
    // Group formats by type (document, image, etc.)
    final Map<String, List<FormatOption>> grouped = {};

    // Default grouping by file type
    for (var format in widget.formats) {
      String category = 'Other';

      // Determine category based on format
      if (['pdf', 'docx', 'txt', 'rtf'].contains(format.id.toLowerCase())) {
        category = 'Documents';
      } else if (['jpg', 'jpeg', 'png', 'gif', 'webp']
          .contains(format.id.toLowerCase())) {
        category = 'Images';
      } else if (['xlsx'].contains(format.id.toLowerCase())) {
        category = 'Spreadsheets';
      } else if (['pptx'].contains(format.id.toLowerCase())) {
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
