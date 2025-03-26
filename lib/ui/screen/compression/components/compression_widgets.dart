import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/config/helper.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/utils/file_utils.dart';

class DocumentInfoCard extends StatelessWidget {
  final Document document;
  final int fileSize;

  const DocumentInfoCard({
    super.key,
    required this.document,
    required this.fileSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: document.thumbnailPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.file(
                      File(document.thumbnailPath!),
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.picture_as_pdf,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  document.name,
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.adaptiveSp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                AutoSizeText(
                  'stats.file_size'.tr(
                      namedArgs: {'size': FileUtils.formatFileSize(fileSize)}),
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.adaptiveSp,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                AutoSizeText(
                  'stats.pages'
                      .tr(namedArgs: {'count': '${document.pageCount}'}),
                  style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.adaptiveSp,
                    color: Colors.grey.shade700,
                  ),
                ),
                if (document.isPasswordProtected) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      AutoSizeText(
                        'stats.password_protected',
                        style: GoogleFonts.slabo27px(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.adaptiveSp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CompressionLevelSelector extends StatelessWidget {
  final CompressionLevel selectedLevel;
  final Function(CompressionLevel) onLevelChanged;

  const CompressionLevelSelector({
    super.key,
    required this.selectedLevel,
    required this.onLevelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CompressionOption(
                label: 'options.low'.tr(),
                icon: Icons.compress,
                isSelected: selectedLevel == CompressionLevel.low,
                onTap: () => onLevelChanged(CompressionLevel.low),
              ),
            ),
            Expanded(
              child: CompressionOption(
                label: 'options.medium'.tr(),
                icon: Icons.compress,
                isSelected: selectedLevel == CompressionLevel.medium,
                onTap: () => onLevelChanged(CompressionLevel.medium),
              ),
            ),
            Expanded(
              child: CompressionOption(
                label: 'options.high'.tr(),
                icon: Icons.compress,
                isSelected: selectedLevel == CompressionLevel.high,
                onTap: () => onLevelChanged(CompressionLevel.high),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CompressionOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const CompressionOption({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 8),
            AutoSizeText(
              label,
              style: GoogleFonts.slabo27px(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w700,
                fontSize: 14.adaptiveSp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SliderWithLabel extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final Function(double) onChanged;

  const SliderWithLabel({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AutoSizeText(
              label,
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
                fontSize: 14.adaptiveSp,
              ),
            ),
            AutoSizeText(
              '${value.round()}%',
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 14.adaptiveSp,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: '${value.round()}%',
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AutoSizeText(
              'slider.more_compression'.tr(),
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
                fontSize: 10.adaptiveSp,
                color: Colors.grey.shade600,
              ),
            ),
            AutoSizeText(
              'slider.better_quality'.tr(),
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
                fontSize: 10.adaptiveSp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CompressionStatsCard extends StatelessWidget {
  final int originalSize;
  final int estimatedSize;

  const CompressionStatsCard({
    super.key,
    required this.originalSize,
    required this.estimatedSize,
  });

  @override
  Widget build(BuildContext context) {
    final sizeDifference = originalSize - estimatedSize;
    final percentageReduction =
        (originalSize > 0) ? (sizeDifference / originalSize * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatColumn(
                label: 'document.original_size'.tr(),
                value: FileUtils.formatFileSize(originalSize),
              ),
              Icon(
                Icons.arrow_forward,
                color: Colors.grey.shade400,
              ),
              StatColumn(
                label: 'document.estimated_size'.tr(),
                value: FileUtils.formatFileSize(estimatedSize),
                valueColor: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatColumn(
                label: 'document.size_reduction'.tr(),
                value: FileUtils.formatFileSize(sizeDifference),
                valueColor: Colors.green.shade700,
              ),
              StatColumn(
                label: 'document.percentage'.tr(),
                value: '$percentageReduction%',
                valueColor: Colors.green.shade700,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const StatColumn({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AutoSizeText(
          label,
          style: GoogleFonts.slabo27px(
            fontWeight: FontWeight.w700,
            fontSize: 12.adaptiveSp,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        AutoSizeText(
          value,
          style: GoogleFonts.slabo27px(
            fontSize: 16.adaptiveSp,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class CompressionBottomBar extends StatelessWidget {
  final bool isCompressing;
  final VoidCallback onCancel;
  final VoidCallback onCompress;

  const CompressionBottomBar({
    super.key,
    required this.isCompressing,
    required this.onCancel,
    required this.onCompress,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isCompressing ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: AutoSizeText('common.cancel'.tr()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: isCompressing ? null : onCompress,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: AutoSizeText(isCompressing
                    ? 'buttons.compressing'.tr()
                    : 'buttons.compress'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
