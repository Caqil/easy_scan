import 'package:flutter/material.dart';

import '../../../../models/format_category.dart';

class FormatSelector extends StatelessWidget {
  final List<FormatOption> formats;
  final FormatOption? selectedFormat;
  final Function(FormatOption) onFormatSelected;

  const FormatSelector({
    super.key,
    required this.formats,
    required this.selectedFormat,
    required this.onFormatSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: formats.length,
        itemBuilder: (context, index) {
          final format = formats[index];
          final isSelected = selectedFormat?.id == format.id;

          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () => onFormatSelected(format),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                decoration: BoxDecoration(
                  color: isSelected
                      ? format.color.withOpacity(0.2)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? format.color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      format.icon,
                      color: format.color,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      format.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
