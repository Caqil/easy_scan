import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/ui/screen/edit/component/document_password_widget.dart';
import 'package:scanpro/ui/screen/edit/component/edit_screen_controller.dart';
import 'package:scanpro/ui/widget/color_selector.dart';
import 'package:scanpro/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
                      'document_actions.password_protection'.tr(),
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
                      child: Text('common.cancel'.tr()),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        controller.isPasswordProtected =
                            controller.passwordController.text.isNotEmpty;
                        Navigator.pop(context);
                      },
                      child: Text('document_actions.apply'.tr()),
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
        message: 'document_actions.no_document_to_add_watermark'.tr(),
        type: SnackBarType.warning,
      );
      return;
    }

    final String fileExtension =
        path.extension(controller.pages[0].path).toLowerCase();

    if (controller.currentEditMode == EditMode.pdfEdit) {
      if (fileExtension != '.pdf') {
        controller.isProcessing = true;
        controller.updateUI();

        try {
          await controller.preparePdfPreview();

          if (path.extension(controller.pages[0].path).toLowerCase() !=
              '.pdf') {
            throw Exception('Could not create PDF for watermarking');
          }
        } catch (e) {
          AppDialogs.showSnackBar(
            controller.context,
            message: 'document_actions.could_not_prepare_pdf'
                .tr(namedArgs: {'error': e.toString()}),
            type: SnackBarType.error,
          );
          controller.isProcessing = false;
          controller.updateUI();
          return;
        }

        controller.isProcessing = false;
        controller.updateUI();
      }
    } else {
      AppDialogs.showSnackBar(
        controller.context,
        message: 'document_actions.switching_to_pdf_mode'.tr(),
      );

      controller.switchEditMode(EditMode.pdfEdit);
      return;
    }

    String watermarkType = 'text';
    String watermarkText = "ScanPro";
    double opacity = 0.2;
    Color watermarkColor = Colors.red;
    double fontSize = 72;
    Uint8List? imageBytes;

    final result = await showModalBottomSheet(
      context: controller.context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return _buildCustomWatermarkBottomSheet(
            context: context,
            watermarkType: watermarkType,
            watermarkText: watermarkText,
            opacity: opacity,
            watermarkColor: watermarkColor,
            fontSize: fontSize,
            imageBytes: imageBytes,
            onWatermarkTypeChanged: (type) {
              setState(() => watermarkType = type);
            },
            onWatermarkTextChanged: (text) {
              setState(() => watermarkText = text);
            },
            onOpacityChanged: (value) {
              setState(() => opacity = value);
            },
            onColorChanged: (color) {
              setState(() => watermarkColor = color);
            },
            onFontSizeChanged: (size) {
              setState(() => fontSize = size);
            },
            onImageChanged: (bytes) {
              setState(() => imageBytes = bytes);
            },
          );
        });
      },
    );

    if (result == true) {
      await _addWatermarkToPdf(
        controller.pages[0].path,
        watermarkText,
        watermarkType,
        opacity,
        watermarkColor,
        fontSize,
        imageBytes,
      );
    }
  }

  Widget _buildCustomWatermarkBottomSheet({
    required BuildContext context,
    required String watermarkType,
    required String watermarkText,
    required double opacity,
    required Color watermarkColor,
    required double fontSize,
    required Uint8List? imageBytes,
    required Function(String) onWatermarkTypeChanged,
    required Function(String) onWatermarkTextChanged,
    required Function(double) onOpacityChanged,
    required Function(Color) onColorChanged,
    required Function(double) onFontSizeChanged,
    required Function(Uint8List?) onImageChanged,
  }) {
    final textController = TextEditingController(text: watermarkText);
    textController.addListener(() {
      onWatermarkTextChanged(textController.text);
    });

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.water,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'document_actions.add_watermark'.tr(),
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Row(
                      children: [
                        Text('document_actions.watermark_type'.tr(),
                            style: GoogleFonts.slabo27px(
                                fontWeight: FontWeight.bold)),
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
                            onWatermarkTypeChanged(newSelection.first);
                            controller.updateUI();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (watermarkType == 'text')
                      TextField(
                        controller: textController,
                        decoration: InputDecoration(
                          labelText: 'document_actions.watermark_text'.tr(),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.text_fields),
                          hintText:
                              'document_actions.enter_watermark_text'.tr(),
                        ),
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
                                    imageBytes,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      onImageChanged(null);
                                      controller.updateUI();
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
                                  onImageChanged(bytes);
                                  logger.info('Opacity slider value: $opacity');
                                  controller.updateUI();
                                }
                              } catch (e) {
                                AppDialogs.showSnackBar(
                                  controller.context,
                                  message:
                                      'document_actions.error_adding_watermark'
                                          .tr(namedArgs: {
                                    'error': e.toString()
                                  }),
                                  type: SnackBarType.error,
                                );
                              }
                            },
                            icon: Icon(Icons.upload_file),
                            label: Text(imageBytes == null
                                ? 'document_actions.select_image'.tr()
                                : 'document_actions.change_image'.tr()),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text('document_actions.opacity'.tr(),
                            style: GoogleFonts.slabo27px(
                                fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Slider(
                            value: opacity,
                            min: 0.05,
                            max: 0.5,
                            divisions: 9,
                            label: '${(opacity * 100).round()}%',
                            onChanged: (value) {
                              onOpacityChanged(value);
                              controller.updateUI();
                            },
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
                              Text('document_actions.color_mode.color'.tr(),
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ColorSelector(
                                  selectedColor: watermarkColor,
                                  onColorSelected: (color) {
                                    onColorChanged(color);
                                    controller.updateUI();
                                  },
                                  colorValues: AppConstants.folderColors,
                                  itemSize: 36,
                                  spacing: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Text('document_actions.font_size'.tr(),
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Slider(
                                  value: fontSize,
                                  min: 36,
                                  max: 144,
                                  divisions: 6,
                                  label: fontSize.round().toString(),
                                  onChanged: (value) {
                                    onFontSizeChanged(value);
                                    controller.updateUI();
                                  },
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
                              watermarkText.isEmpty
                                  ? 'WATERMARK'
                                  : watermarkText,
                              style: GoogleFonts.slabo27px(
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
                                imageBytes,
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('common.cancel'.tr()),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: () {
                        if (watermarkType == 'text' &&
                            textController.text.trim().isEmpty) {
                          AppDialogs.showSnackBar(
                            controller.context,
                            message:
                                'document_actions.please_enter_watermark_text'
                                    .tr(),
                            type: SnackBarType.warning,
                          );
                          return;
                        }
                        if (watermarkType == 'image' && imageBytes == null) {
                          AppDialogs.showSnackBar(
                            controller.context,
                            message:
                                'document_actions.please_select_image'.tr(),
                            type: SnackBarType.warning,
                          );
                          return;
                        }
                        Navigator.pop(context, true);
                      },
                      child: Text('document_actions.apply_watermark'.tr()),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
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
    controller.updateUI();

    try {
      PdfDocument document;
      try {
        document = controller.passwordController.text.isNotEmpty
            ? PdfDocument(
                inputBytes: await File(pdfPath).readAsBytes(),
                password: controller.passwordController.text,
              )
            : PdfDocument(inputBytes: await File(pdfPath).readAsBytes());
      } catch (e) {
        logger.error('Error opening PDF: $e');
        throw Exception('Could not open PDF file: $e');
      }

      if (type == 'text' && text.isNotEmpty) {
        double safeFontSize = fontSize;
        if (safeFontSize > 144) safeFontSize = 144;
        final PdfStandardFont font =
            PdfStandardFont(PdfFontFamily.helvetica, safeFontSize);
        for (int i = 0; i < document.pages.count; i++) {
          final PdfPage page = document.pages[i];
          final PdfGraphics graphics = page.graphics;
          final double x = page.size.width / 2;
          final double y = page.size.height / 2;
          final PdfStringFormat format = PdfStringFormat(
              alignment: PdfTextAlignment.center,
              lineAlignment: PdfVerticalAlignment.middle);
          Size textSize = font.measureString(text, format: format);
          graphics.save();
          graphics.setTransparency(opacity);
          graphics.translateTransform(x, y);
          graphics.rotateTransform(-45);
          final PdfColor pdfColor =
              PdfColor(color.red, color.green, color.blue);
          final PdfSolidBrush brush = PdfSolidBrush(pdfColor);
          graphics.drawString(
            text,
            font,
            brush: brush,
            format: format,
            bounds: Rect.fromCenter(
              center: Offset.zero,
              width: textSize.width,
              height: textSize.height,
            ),
          );
          graphics.restore();
        }
      } else if (type == 'image' && imageBytes != null) {
        try {
          final PdfBitmap watermarkImage = PdfBitmap(imageBytes);
          for (int i = 0; i < document.pages.count; i++) {
            final PdfPage page = document.pages[i];
            final PdfGraphics graphics = page.graphics;
            final double pageWidth = page.size.width;
            final double pageHeight = page.size.height;
            double watermarkWidth = pageWidth * 0.5;
            double watermarkHeight =
                (watermarkWidth / watermarkImage.width) * watermarkImage.height;
            if (watermarkHeight > pageHeight * 0.5) {
              watermarkHeight = pageHeight * 0.5;
              watermarkWidth = (watermarkHeight / watermarkImage.height) *
                  watermarkImage.width;
            }
            final double x = (pageWidth - watermarkWidth) / 2;
            final double y = (pageHeight - watermarkHeight) / 2;
            graphics.save();
            graphics.setTransparency(opacity);
            graphics.drawImage(
              watermarkImage,
              Rect.fromLTWH(x, y, watermarkWidth, watermarkHeight),
            );
            graphics.restore();
          }
        } catch (e) {
          logger.error('Error applying image watermark: $e');
          throw Exception('Failed to apply image watermark: $e');
        }
      }

      try {
        final Directory tempDir = await getTemporaryDirectory();
        final String tempPath =
            '${tempDir.path}/watermarked_${path.basename(pdfPath)}';
        File(tempPath).writeAsBytesSync(await document.save());
        await File(tempPath).copy(pdfPath);
        await File(tempPath).delete();
        document.dispose();
      } catch (e) {
        logger.error('Error saving watermarked PDF: $e');
        throw Exception('Failed to save watermarked document: $e');
      }

      AppDialogs.showSnackBar(
        controller.context,
        message: 'document_actions.watermark_added_successfully'.tr(),
        type: SnackBarType.success,
      );
    } catch (e) {
      AppDialogs.showSnackBar(
        controller.context,
        message: 'document_actions.error_adding_watermark'
            .tr(namedArgs: {'error': e.toString()}),
        type: SnackBarType.error,
      );
    } finally {
      controller.isProcessing = false;
      controller.updateUI();
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
