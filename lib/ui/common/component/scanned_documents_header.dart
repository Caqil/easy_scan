import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Header component for the scanned documents view
class ScannedDocumentsHeader extends StatelessWidget {
  final int pageCount;
  final VoidCallback onAddMore;

  const ScannedDocumentsHeader({
    super.key,
    required this.pageCount,
    required this.onAddMore,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: themeData.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildDragIndicator(themeData),
          const SizedBox(width: 12),
          _buildInfoText(themeData),
          _buildAddButton(),
        ],
      ),
    );
  }

  Widget _buildDragIndicator(ThemeData themeData) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: themeData.colorScheme.primaryContainer.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.drag_indicator,
        color: themeData.colorScheme.onPrimaryContainer,
        size: 20,
      ),
    );
  }

  Widget _buildInfoText(ThemeData themeData) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'scanned_documents.pages_scanned'.tr(
              namedArgs: {
                'count': pageCount.toString(),
                'plural': pageCount != 1 ? 's' : ''
              },
              args: [pageCount.toString()],
            ),
            style: themeData.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'scanned_documents.drag_to_reorder'.tr(),
            style: themeData.textTheme.bodySmall?.copyWith(
              color: themeData.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return TextButton.icon(
      onPressed: onAddMore,
      icon: const Icon(Icons.add_a_photo, size: 16),
      label: Text('common.add'.tr()),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
