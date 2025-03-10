import 'package:flutter/material.dart';

import '../../models/scan_settings.dart';

class EditTools extends StatelessWidget {
  final Function(ColorMode) onColorModeChanged;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onCrop;
  final VoidCallback onFilter;
  final ColorMode currentColorMode;

  const EditTools({
    super.key,
    required this.onColorModeChanged,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onCrop,
    required this.onFilter,
    required this.currentColorMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color mode selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildColorModeButton(
                  context,
                  title: 'Original',
                  icon: Icons.color_lens,
                  mode: ColorMode.color,
                ),
                _buildColorModeButton(
                  context,
                  title: 'Grayscale',
                  icon: Icons.monochrome_photos,
                  mode: ColorMode.grayscale,
                ),
                _buildColorModeButton(
                  context,
                  title: 'B&W',
                  icon: Icons.filter_b_and_w,
                  mode: ColorMode.blackAndWhite,
                ),
              ],
            ),
          ),

          const Divider(),

          // Transform tools
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToolButton(
                context,
                title: 'Rotate L',
                icon: Icons.rotate_left,
                onPressed: onRotateLeft,
              ),
              _buildToolButton(
                context,
                title: 'Rotate R',
                icon: Icons.rotate_right,
                onPressed: onRotateRight,
              ),
              _buildToolButton(
                context,
                title: 'Crop',
                icon: Icons.crop,
                onPressed: onCrop,
              ),
              _buildToolButton(
                context,
                title: 'Filter',
                icon: Icons.auto_fix_high,
                onPressed: onFilter,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorModeButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required ColorMode mode,
  }) {
    final isSelected = currentColorMode == mode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () => onColorModeChanged(mode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).iconTheme.color,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
