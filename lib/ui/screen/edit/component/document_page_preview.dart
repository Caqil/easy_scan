import 'dart:io';
import 'package:flutter/material.dart';

/// Widget that displays a single document page in a viewer
class DocumentPagePreview extends StatelessWidget {
  final File page;

  const DocumentPagePreview({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Future enhancement: Zoom in on image
      },
      child: Container(
        color: Colors.grey[900],
        padding: const EdgeInsets.all(8.0),
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Center(
            child: Image.file(
              page,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
