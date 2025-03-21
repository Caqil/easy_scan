import 'package:flutter/material.dart';

class ColorSelector extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorSelected;
  final List<int>?
      colorValues; // For using AppConstants.folderColors (int colors)
  final List<Color>? colors; // For using direct Color objects
  final double itemSize;
  final double spacing;

  const ColorSelector({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.colorValues,
    this.colors,
    this.itemSize = 36,
    this.spacing = 12,
  }) : assert(colorValues != null || colors != null,
            'Either colorValues or colors must be provided');

  @override
  Widget build(BuildContext context) {
    // Convert the colorValues to Color objects if provided
    final List<Color> colorsList =
        colors ?? colorValues!.map((colorValue) => Color(colorValue)).toList();

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: colorsList
          .map((color) => _buildColorOption(
                color: color,
                selectedColor: selectedColor,
                onSelect: onColorSelected,
                size: itemSize,
              ))
          .toList(),
    );
  }

  Widget _buildColorOption({
    required Color color,
    required Color selectedColor,
    required Function(Color) onSelect,
    required double size,
  }) {
    final bool isSelected = selectedColor.value == color.value;

    return GestureDetector(
      onTap: () => onSelect(color),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: isSelected
            ? Icon(Icons.check, color: Colors.white, size: size * 0.6)
            : null,
      ),
    );
  }
}
