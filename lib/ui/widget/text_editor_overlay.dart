import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/models/scan_result.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextEditorOverlay extends StatefulWidget {
  final File imageFile;
  final List<TextElementData> textElements;
  final Function(List<TextElementData>) onTextUpdated;

  const TextEditorOverlay({
    super.key,
    required this.imageFile,
    required this.textElements,
    required this.onTextUpdated,
  });

  @override
  State<TextEditorOverlay> createState() => _TextEditorOverlayState();
}

class _TextEditorOverlayState extends State<TextEditorOverlay> {
  late List<TextElementData> _editableElements;
  TextElementData? _selectedElement;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _editableElements = List.from(widget.textElements);
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _selectElement(TextElementData element) {
    setState(() {
      _selectedElement = element;
      _textController.text = element.text;
    });
  }

  void _updateElementText(String newText) {
    if (_selectedElement == null) return;

    final index = _editableElements.indexOf(_selectedElement!);
    if (index != -1) {
      setState(() {
        final updatedElement = TextElementData(
          text: newText,
          boundingBox: _selectedElement!.boundingBox,
        );
        _editableElements[index] = updatedElement;
        _selectedElement = updatedElement;
      });
      widget.onTextUpdated(_editableElements);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image with InteractiveViewer for zoom/pan
        InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Image.file(widget.imageFile),
        ),

        // Overlay for text elements
        for (var element in _editableElements)
          Positioned(
            left: element.boundingBox.left,
            top: element.boundingBox.top,
            width: element.boundingBox.width,
            height: element.boundingBox.height,
            child: GestureDetector(
              onTap: () => _selectElement(element),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedElement == element
                        ? Colors.blue
                        : Colors.green,
                    width: 2,
                  ),
                  color: _selectedElement == element
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    element.text,
                    style: GoogleFonts.slabo27px(
                      color: _selectedElement == element
                          ? Colors.white
                          : Colors.black,
                      fontWeight: _selectedElement == element
                          ? FontWeight.bold
                          : FontWeight.normal,
                      shadows: [
                        Shadow(
                          color: Colors.white,
                          offset: Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),

        // Text editing controls (when an element is selected)
        if (_selectedElement != null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        labelText: 'Edit Text',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: _updateElementText,
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedElement = null;
                            });
                          },
                          child: Text('common.done'.tr()),
                        ),
                        TextButton(
                          onPressed: () {
                            // Delete the element
                            setState(() {
                              _editableElements.remove(_selectedElement);
                              _selectedElement = null;
                            });
                            widget.onTextUpdated(_editableElements);
                          },
                          child: Text('common.delete'.tr(),
                              style: GoogleFonts.slabo27px(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
