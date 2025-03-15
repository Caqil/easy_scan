import 'dart:io';
import 'dart:typed_data';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:easy_scan/ui/screen/edit/component/document_password_widget.dart';
import 'package:easy_scan/ui/screen/edit/component/edit_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DocumentActionHandler {
  final EditScreenController controller;
  final ImagePicker _imagePicker = ImagePicker();

  DocumentActionHandler(this.controller);

  Future<void> showPasswordOptions() async {
    await showModalBottomSheet(
      context: controller.context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 2,
                width: 30,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      controller.isPasswordProtected
                          ? Icons.lock
                          : Icons.lock_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Password Protection',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DocumentPasswordWidget(
                  passwordController: controller.passwordController,
                  isPasswordProtected: controller.isPasswordProtected,
                  colorScheme: Theme.of(context).colorScheme,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        controller.isPasswordProtected =
                            controller.passwordController.text.isNotEmpty;
                        Navigator.pop(context);
                      },
                      child: Text('Apply'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showWatermarkOptions() async {
    if (controller.pages.isEmpty) {
      AppDialogs.showSnackBar(
        controller.context,
        message: 'No document to add watermark to',
        type: SnackBarType.warning,
      );
      return;
    }

    final String fileExtension = path
        .extension(controller.pages[0].path)
        .toLowerCase()
        .replaceAll('.', '');

    await showModalBottomSheet(
      context: controller.context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildWatermarkBottomSheet(context),
    ).then((watermarkInfo) async {
      if (watermarkInfo != null) {
        await _addWatermarkToPdf(
          controller.pages[0].path,
          watermarkInfo['text'],
          watermarkInfo['type'],
          watermarkInfo['opacity'],
          watermarkInfo['color'],
          watermarkInfo['fontSize'],
          watermarkInfo['imageBytes'],
        );
      }
    });
  }

  Widget _buildWatermarkBottomSheet(BuildContext context) {
    final textController = TextEditingController();
    String watermarkType = 'text';
    double opacity = 0.2;
    Color watermarkColor = Colors.red;
    double fontSize = 72;
    Uint8List? imageBytes;

    return StatefulBuilder(
      builder: (context, setState) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.water,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Add Watermark',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Row(
                      children: [
                        Text('Watermark Type:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                                value: 'text',
                                label: Text('Text'),
                                icon: Icon(Icons.text_fields)),
                            ButtonSegment(
                                value: 'image',
                                label: Text('Image'),
                                icon: Icon(Icons.image)),
                          ],
                          selected: {watermarkType},
                          onSelectionChanged: (newSelection) {
                            setState(() => watermarkType = newSelection.first);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (watermarkType == 'text')
                      TextField(
                        controller: textController,
                        decoration: InputDecoration(
                          labelText: 'Watermark Text',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.text_fields),
                        ),
                        onChanged: (value) {
                          // This ensures the preview updates as the user types
                          setState(() {});
                        },
                      ),
                    if (watermarkType == 'image')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageBytes != null)
                            Stack(
                              children: [
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  margin: EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Image.memory(
                                    imageBytes!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        imageBytes = null;
                                      });
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                final XFile? image =
                                    await _imagePicker.pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 800,
                                );
                                if (image != null) {
                                  final bytes = await image.readAsBytes();
                                  setState(() {
                                    imageBytes = bytes;
                                  });
                                }
                              } catch (e) {
                                AppDialogs.showSnackBar(
                                  controller.context,
                                  message: 'Error selecting image: $e',
                                  type: SnackBarType.error,
                                );
                              }
                            },
                            icon: Icon(Icons.upload_file),
                            label: Text(imageBytes == null
                                ? 'Select Image for Watermark'
                                : 'Change Image'),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text('Opacity:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Slider(
                            value: opacity,
                            min: 0.05,
                            max: 0.5,
                            divisions: 9,
                            label: '${(opacity * 100).round()}%',
                            onChanged: (value) =>
                                setState(() => opacity = value),
                          ),
                        ),
                        Text('${(opacity * 100).round()}%'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (watermarkType == 'text')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Color:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    _buildColorOption(
                                        Colors.red,
                                        watermarkColor,
                                        (color) => setState(
                                            () => watermarkColor = color)),
                                    _buildColorOption(
                                        Colors.blue,
                                        watermarkColor,
                                        (color) => setState(
                                            () => watermarkColor = color)),
                                    _buildColorOption(
                                        Colors.green,
                                        watermarkColor,
                                        (color) => setState(
                                            () => watermarkColor = color)),
                                    _buildColorOption(
                                        Colors.orange,
                                        watermarkColor,
                                        (color) => setState(
                                            () => watermarkColor = color)),
                                    _buildColorOption(
                                        Colors.purple,
                                        watermarkColor,
                                        (color) => setState(
                                            () => watermarkColor = color)),
                                    _buildColorOption(
                                        Colors.grey,
                                        watermarkColor,
                                        (color) => setState(
                                            () => watermarkColor = color)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Text('Font Size:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Slider(
                                  value: fontSize,
                                  min: 36,
                                  max: 144,
                                  divisions: 6,
                                  label: fontSize.round().toString(),
                                  onChanged: (value) =>
                                      setState(() => fontSize = value),
                                ),
                              ),
                              Text(fontSize.round().toString()),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    if (watermarkType == 'text')
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: RotationTransition(
                            turns: const AlwaysStoppedAnimation(-45 / 360),
                            child: Text(
                              textController.text.isEmpty
                                  ? 'WATERMARK'
                                  : textController.text,
                              style: TextStyle(
                                fontSize: fontSize / 3,
                                color: watermarkColor.withOpacity(opacity),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (watermarkType == 'image' && imageBytes != null)
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: opacity,
                              child: Image.memory(
                                imageBytes!,
                                height: 100,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                    style: BorderStyle.solid,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Footer buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (watermarkType == 'text' &&
                            textController.text.trim().isEmpty) {
                          AppDialogs.showSnackBar(
                            controller.context,
                            message: 'Please enter watermark text',
                            type: SnackBarType.warning,
                          );
                          return;
                        }
                        if (watermarkType == 'image' && imageBytes == null) {
                          AppDialogs.showSnackBar(
                            controller.context,
                            message: 'Please select an image for watermark',
                            type: SnackBarType.warning,
                          );
                          return;
                        }
                        Navigator.pop(context, {
                          'type': watermarkType,
                          'text': textController.text.trim(),
                          'opacity': opacity,
                          'color': watermarkColor,
                          'fontSize': fontSize,
                          'imageBytes': imageBytes,
                        });
                      },
                      child: Text('Apply Watermark'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(
      Color color, Color selectedColor, Function(Color) onSelect) {
    final bool isSelected = color.value == selectedColor.value;
    return GestureDetector(
      onTap: () => onSelect(color),
      child: Container(
        width: 36,
        height: 36,
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
                      color: color.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1)
                ]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  Future<void> _addWatermarkToPdf(
      String pdfPath,
      String text,
      String type,
      double opacity,
      Color color,
      double fontSize,
      Uint8List? imageBytes) async {
    controller.isProcessing = true;

    try {
      final PdfDocument document = controller.passwordController.text.isNotEmpty
          ? PdfDocument(
              inputBytes: File(pdfPath).readAsBytesSync(),
              password: controller.passwordController.text,
            )
          : PdfDocument(inputBytes: File(pdfPath).readAsBytesSync());

      if (type == 'text') {
        final PdfColor pdfColor = PdfColor(
            color.red, color.green, color.blue, (opacity * 255).round());
        final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, fontSize);
        final PdfSolidBrush brush = PdfSolidBrush(pdfColor);

        for (int i = 0; i < document.pages.count; i++) {
          final PdfPage page = document.pages[i];
          final PdfGraphics graphics = page.graphics;
          final double x = page.size.width / 2;
          final double y = page.size.height / 2;
          final Size textSize = font.measureString(text);

          graphics.save();
          graphics.translateTransform(x, y);
          graphics.rotateTransform(-45);
          graphics.drawString(
            text,
            font,
            brush: brush,
            bounds: Rect.fromCenter(
                center: Offset.zero,
                width: textSize.width,
                height: textSize.height),
          );
          graphics.restore();
        }
      } else if (type == 'image' && imageBytes != null) {
        final PdfBitmap watermarkImage = PdfBitmap(imageBytes);

        for (int i = 0; i < document.pages.count; i++) {
          final PdfPage page = document.pages[i];
          final PdfGraphics graphics = page.graphics;

          // Calculate dimensions to maintain aspect ratio
          final double pageWidth = page.size.width;
          final double pageHeight = page.size.height;
          final double imageWidth = watermarkImage.width.toDouble();
          final double imageHeight = watermarkImage.height.toDouble();

          // Calculate the scaling factor to fit the image properly
          double scaleFactor;
          if (imageWidth > imageHeight) {
            scaleFactor = (pageWidth * 0.8) / imageWidth;
          } else {
            scaleFactor = (pageHeight * 0.8) / imageHeight;
          }

          final double targetWidth = imageWidth * scaleFactor;
          final double targetHeight = imageHeight * scaleFactor;

          // Position image in center of page
          final double x = (pageWidth - targetWidth) / 2;
          final double y = (pageHeight - targetHeight) / 2;

          // Set transparency for the image
          graphics.save();
          graphics.setTransparency(opacity);
          graphics.drawImage(
              watermarkImage, Rect.fromLTWH(x, y, targetWidth, targetHeight));
          graphics.restore();
        }
      }

      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath =
          '${tempDir.path}/watermarked_${path.basename(pdfPath)}';
      File(tempPath).writeAsBytesSync(await document.save());
      await File(tempPath).copy(pdfPath);
      await File(tempPath).delete();
      document.dispose();

      AppDialogs.showSnackBar(
        controller.context,
        message: 'Watermark added successfully',
        type: SnackBarType.success,
      );
    } catch (e) {
      AppDialogs.showSnackBar(
        controller.context,
        message: 'Error adding watermark: $e',
        type: SnackBarType.error,
      );
    } finally {
      controller.isProcessing = false;
    }
  }

  Future<void> showSignatureOptions() async {
    // Code for signature feature
    // (Keeping the rest of your methods the same)
  }

  Future<void> showExtractTextOptions() async {
    // Code for text extraction feature
    // (Keeping the rest of your methods the same)
  }

  Future<void> showFindTextOptions() async {
    // Code for text finding feature
    // (Keeping the rest of your methods the same)
  }
}

class TextSearchResult {
  final int pageIndex;
  final String text;
  final Rect bounds;

  TextSearchResult({
    required this.pageIndex,
    required this.text,
    required this.bounds,
  });
}
