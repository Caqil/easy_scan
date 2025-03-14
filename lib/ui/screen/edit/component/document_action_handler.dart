import 'dart:io';
import 'dart:typed_data';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:easy_scan/ui/screen/edit/component/document_password_widget.dart';
import 'package:easy_scan/ui/screen/edit/component/edit_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class DocumentActionHandler {
  final EditScreenController controller;

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

    if (fileExtension != 'pdf') {
      AppDialogs.showSnackBar(
        controller.context,
        message: 'Please save the document as PDF first to add a watermark',
      );
      return;
    }

    await showModalBottomSheet(
      context: controller.context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildWatermarkBottomSheet(),
    ).then((watermarkInfo) async {
      if (watermarkInfo != null) {
        await _addWatermarkToPdf(
          controller.pages[0].path,
          watermarkInfo['text'],
          watermarkInfo['type'],
          watermarkInfo['opacity'],
          watermarkInfo['color'],
          watermarkInfo['fontSize'],
        );
      }
    });
  }

  Widget _buildWatermarkBottomSheet() {
    final textController = TextEditingController(text: 'CONFIDENTIAL');
    String watermarkType = 'text';
    double opacity = 0.2;
    Color watermarkColor = Colors.red;
    double fontSize = 72;

    return StatefulBuilder(
      builder: (context, setState) => Container(
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
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
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
                    'Add Watermark',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
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
                    ),
                  if (watermarkType == 'image')
                    OutlinedButton.icon(
                      onPressed: () {
                        AppDialogs.showSnackBar(
                          controller.context,
                          message:
                              'Image watermark will be supported in future update',
                        );
                      },
                      icon: Icon(Icons.upload_file),
                      label: Text('Select Image for Watermark'),
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
                          label: (opacity * 100).round().toString() + '%',
                          onChanged: (value) => setState(() => opacity = value),
                        ),
                      ),
                      Text('${(opacity * 100).round()}%'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text('Color:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Wrap(
                        spacing: 12,
                        children: [
                          _buildColorOption(
                              Colors.red,
                              watermarkColor,
                              (color) =>
                                  setState(() => watermarkColor = color)),
                          _buildColorOption(
                              Colors.blue,
                              watermarkColor,
                              (color) =>
                                  setState(() => watermarkColor = color)),
                          _buildColorOption(
                              Colors.green,
                              watermarkColor,
                              (color) =>
                                  setState(() => watermarkColor = color)),
                          _buildColorOption(
                              Colors.orange,
                              watermarkColor,
                              (color) =>
                                  setState(() => watermarkColor = color)),
                          _buildColorOption(
                              Colors.purple,
                              watermarkColor,
                              (color) =>
                                  setState(() => watermarkColor = color)),
                          _buildColorOption(
                              Colors.grey,
                              watermarkColor,
                              (color) =>
                                  setState(() => watermarkColor = color)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (watermarkType == 'text')
                    Row(
                      children: [
                        Text('Font Size:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(controller.context),
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
                      Navigator.pop(controller.context, {
                        'type': watermarkType,
                        'text': textController.text.trim(),
                        'opacity': opacity,
                        'color': watermarkColor,
                        'fontSize': fontSize,
                      });
                    },
                    child: Text('Apply Watermark'),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(controller.context).padding.bottom),
          ],
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

  Future<void> _addWatermarkToPdf(String pdfPath, String text, String type,
      double opacity, Color color, double fontSize) async {
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
      } else if (type == 'image') {
        AppDialogs.showSnackBar(
          controller.context,
          message: 'Image watermark will be supported in future update',
        );
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
    if (controller.pages.isEmpty) {
      AppDialogs.showSnackBar(
        controller.context,
        message: 'No document to sign',
        type: SnackBarType.warning,
      );
      return;
    }

    final String fileExtension = path
        .extension(controller.pages[0].path)
        .toLowerCase()
        .replaceAll('.', '');

    if (fileExtension != 'pdf') {
      AppDialogs.showSnackBar(
        controller.context,
        message: 'Please save the document as PDF first to add a signature',
      );
      return;
    }

    await showModalBottomSheet(
      context: controller.context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSignatureBottomSheet(),
    ).then((signatureInfo) async {
      if (signatureInfo != null) {
        await _addDigitalSignatureToPdf(
          controller.pages[0].path,
          signatureInfo['name'],
          signatureInfo['reason'],
          signatureInfo['location'],
          signatureInfo['contactInfo'],
          signatureInfo['signatureImage'],
        );
      }
    });
  }

  Widget _buildSignatureBottomSheet() {
    final nameController = TextEditingController();
    final reasonController = TextEditingController(text: 'Document approval');
    final locationController = TextEditingController();
    final contactInfoController = TextEditingController();
    Uint8List? signatureImage;

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
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.draw,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Add Digital Signature',
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
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: signatureImage != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(signatureImage!,
                                    fit: BoxFit.contain),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: IconButton(
                                    icon: Icon(Icons.close),
                                    onPressed: () =>
                                        setState(() => signatureImage = null),
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.draw_outlined,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text('Tap to draw signature',
                                    style:
                                        TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.draw),
                            label: Text('Draw Signature'),
                            onPressed: () {
                              setState(() {
                                signatureImage = Uint8List.fromList([
                                  137,
                                  80,
                                  78,
                                  71,
                                  13,
                                  10,
                                  26,
                                  10,
                                  0,
                                  0,
                                  0,
                                  13,
                                  73,
                                  72,
                                  68,
                                  82,
                                  0,
                                  0,
                                  0,
                                  100,
                                  0,
                                  0,
                                  0,
                                  50,
                                  8,
                                  6,
                                  0,
                                  0,
                                  0,
                                  232,
                                  157,
                                  78,
                                  215,
                                  0,
                                  0,
                                  0,
                                  1,
                                  115,
                                  82,
                                  71,
                                  66,
                                  0,
                                  174,
                                  206,
                                  28,
                                  233,
                                  0,
                                  0,
                                  0,
                                  4,
                                  103,
                                  65,
                                  77,
                                  65,
                                  0,
                                  0,
                                  177,
                                  143,
                                  11,
                                  252,
                                  97,
                                  5,
                                  0,
                                  0,
                                  0,
                                  9,
                                  112,
                                  72,
                                  89,
                                  115,
                                  0,
                                  0,
                                  14,
                                  195,
                                  0,
                                  0,
                                  14,
                                  195,
                                  1,
                                  199,
                                  111,
                                  168,
                                  100,
                                  0,
                                  0,
                                  0,
                                  72,
                                  73,
                                  68,
                                  65,
                                  84,
                                ]);
                              });
                            },
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton.icon(
                            icon: Icon(Icons.image),
                            label: Text('Import Image'),
                            onPressed: () {
                              setState(() {
                                signatureImage = Uint8List.fromList([
                                  137,
                                  80,
                                  78,
                                  71,
                                  13,
                                  10,
                                  26,
                                  10,
                                  0,
                                  0,
                                  0,
                                  13,
                                  73,
                                  72,
                                  68,
                                  82,
                                  0,
                                  0,
                                  0,
                                  100,
                                  0,
                                  0,
                                  0,
                                  50,
                                  8,
                                  6,
                                  0,
                                  0,
                                  0,
                                  232,
                                  157,
                                  78,
                                  215,
                                  0,
                                  0,
                                  0,
                                  1,
                                  115,
                                  82,
                                  71,
                                  66,
                                  0,
                                  174,
                                  206,
                                  28,
                                  233,
                                  0,
                                  0,
                                  0,
                                  4,
                                  103,
                                  65,
                                  77,
                                  65,
                                  0,
                                  0,
                                  177,
                                  143,
                                  11,
                                  252,
                                  97,
                                  5,
                                  0,
                                  0,
                                  0,
                                  9,
                                  112,
                                  72,
                                  89,
                                  115,
                                  0,
                                  0,
                                  14,
                                  195,
                                  0,
                                  0,
                                  14,
                                  195,
                                  1,
                                  199,
                                  111,
                                  168,
                                  100,
                                  0,
                                  0,
                                  0,
                                  72,
                                  73,
                                  68,
                                  65,
                                  84,
                                ]);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name *',
                        hintText: 'Enter your name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        labelText: 'Reason for Signing *',
                        hintText: 'e.g., Document approval',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        hintText: 'e.g., New York, NY',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contactInfoController,
                      decoration: InputDecoration(
                        labelText: 'Contact Information',
                        hintText: 'e.g., Email or phone number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.contact_mail_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Fields marked with * are required',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic),
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
                      onPressed: () => Navigator.pop(controller.context),
                      child: Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.trim().isEmpty) {
                          AppDialogs.showSnackBar(
                            controller.context,
                            message: 'Please enter your name',
                            type: SnackBarType.warning,
                          );
                          return;
                        }
                        if (reasonController.text.trim().isEmpty) {
                          AppDialogs.showSnackBar(
                            controller.context,
                            message: 'Please enter a reason for signing',
                            type: SnackBarType.warning,
                          );
                          return;
                        }
                        Navigator.pop(controller.context, {
                          'name': nameController.text.trim(),
                          'reason': reasonController.text.trim(),
                          'location': locationController.text.trim(),
                          'contactInfo': contactInfoController.text.trim(),
                          'signatureImage': signatureImage,
                        });
                      },
                      child: Text('Sign Document'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addDigitalSignatureToPdf(
      String pdfPath,
      String name,
      String reason,
      String location,
      String contactInfo,
      Uint8List? signatureImage) async {
    controller.isProcessing = true;

    try {
      final Directory tempDir = await getTemporaryDirectory();
      final String signedPdfPath =
          '${tempDir.path}/signed_${path.basename(pdfPath)}';
      final PdfDocument document = controller.passwordController.text.isNotEmpty
          ? PdfDocument(
              inputBytes: File(pdfPath).readAsBytesSync(),
              password: controller.passwordController.text,
            )
          : PdfDocument(inputBytes: File(pdfPath).readAsBytesSync());

      final PdfSignatureField signatureField = PdfSignatureField(
        document.pages[0],
        'Signature1',
        bounds: Rect.fromLTWH(
          document.pages[0].size.width - 200,
          document.pages[0].size.height - 100,
          180,
          60,
        ),
      );

      signatureField.signature = PdfSignature(
        certificate: null,
        digestAlgorithm: DigestAlgorithm.sha256,
      );
      signatureField.signature!.signedName = name;
      signatureField.signature!.reason = reason;
      signatureField.signature!.locationInfo = location;
      signatureField.signature!.contactInfo = contactInfo;

      if (signatureImage != null) {
        PdfBitmap signatureBitmap = PdfBitmap(signatureImage);
        signatureField.appearance.normal.graphics!
            .drawImage(signatureBitmap, Rect.fromLTWH(0, 0, 180, 60));
      } else {
        final PdfGraphics graphics = signatureField.appearance.normal.graphics!;
        graphics.drawRectangle(
            pen: PdfPens.black, bounds: Rect.fromLTWH(0, 0, 180, 60));
        final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 10);
        graphics.drawString(
          'Digitally signed by: $name',
          font,
          brush: PdfSolidBrush(PdfColor(0, 0, 0)),
          bounds: Rect.fromLTWH(5, 5, 170, 20),
        );
        graphics.drawString(
          'Date: ${DateTime.now().toString().substring(0, 19)}',
          font,
          brush: PdfSolidBrush(PdfColor(0, 0, 0)),
          bounds: Rect.fromLTWH(5, 25, 170, 20),
        );
        if (reason.isNotEmpty) {
          graphics.drawString(
            'Reason: $reason',
            font,
            brush: PdfSolidBrush(PdfColor(0, 0, 0)),
            bounds: Rect.fromLTWH(5, 45, 170, 15),
          );
        }
      }

      document.form.fields.add(signatureField);
      File(signedPdfPath).writeAsBytesSync(await document.save());
      await File(signedPdfPath).copy(pdfPath);
      await File(signedPdfPath).delete();
      document.dispose();

      AppDialogs.showSnackBar(
        controller.context,
        message: 'Digital signature added successfully',
        type: SnackBarType.success,
      );
    } catch (e) {
      AppDialogs.showSnackBar(
        controller.context,
        message: 'Error adding signature: $e',
        type: SnackBarType.error,
      );
    } finally {
      controller.isProcessing = false;
    }
  }

  Future<void> showExtractTextOptions() async {
    if (controller.pages.isEmpty) {
      AppDialogs.showSnackBar(
        controller.context,
        message: 'No document to extract text from',
        type: SnackBarType.warning,
      );
      return;
    }

    controller.isProcessing = true;

    try {
      final String fileExtension = path
          .extension(controller.pages[0].path)
          .toLowerCase()
          .replaceAll('.', '');
      if (fileExtension != 'pdf') {
        final String tempPdfPath =
            await controller.pdfService.createPdfFromImages(
          controller.pages,
          'temp_for_extraction',
        );
        final String extractedText = await _extractTextFromPdf(
            tempPdfPath, controller.passwordController.text);
        File(tempPdfPath).deleteSync();
        _showExtractedTextDialog(extractedText);
      } else {
        final String extractedText = await _extractTextFromPdf(
            controller.pages[0].path, controller.passwordController.text);
        _showExtractedTextDialog(extractedText);
      }
    } catch (e) {
      AppDialogs.showSnackBar(
        controller.context,
        message: 'Error extracting text: $e',
        type: SnackBarType.error,
      );
    } finally {
      controller.isProcessing = false;
    }
  }

  Future<String> _extractTextFromPdf(String pdfPath, [String? password]) async {
    try {
      final PdfDocument document = password?.isNotEmpty == true
          ? PdfDocument(
              inputBytes: File(pdfPath).readAsBytesSync(), password: password)
          : PdfDocument(inputBytes: File(pdfPath).readAsBytesSync());
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final int pageCount = document.pages.count;
      StringBuffer textBuffer = StringBuffer();

      for (int i = 0; i < pageCount; i++) {
        final String pageText =
            extractor.extractText(startPageIndex: i, endPageIndex: i);
        textBuffer.write('Page ${i + 1}:\n$pageText\n\n');
      }

      document.dispose();
      return textBuffer.toString();
    } catch (e) {
      throw Exception('Failed to extract text: $e');
    }
  }

  void _showExtractedTextDialog(String text) {
    showModalBottomSheet(
      context: controller.context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
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
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Extracted Text',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: text));
                            Navigator.pop(context);
                            AppDialogs.showSnackBar(
                              controller.context,
                              message: 'Text copied to clipboard',
                              type: SnackBarType.success,
                            );
                          },
                          tooltip: 'Copy to clipboard',
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              Expanded(
                child: text.isEmpty
                    ? Center(
                        child: Text(
                          'No text found in document',
                          style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey),
                        ),
                      )
                    : SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(text,
                            style: TextStyle(fontSize: 14, height: 1.5)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showFindTextOptions() async {
    if (controller.pages.isEmpty) {
      AppDialogs.showSnackBar(
        controller.context,
        message: 'No document to search',
        type: SnackBarType.warning,
      );
      return;
    }

    final TextEditingController searchController = TextEditingController();

    await showModalBottomSheet(
      context: controller.context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
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
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.search,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'Find Text in Document',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Text',
                    hintText: 'Enter text to find',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        final searchText = searchController.text.trim();
                        if (searchText.isNotEmpty)
                          Navigator.pop(context, searchText);
                      },
                    ),
                  ),
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (text) {
                    if (text.trim().isNotEmpty)
                      Navigator.pop(context, text.trim());
                  },
                ),
              ),
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
                        final searchText = searchController.text.trim();
                        if (searchText.isNotEmpty) {
                          Navigator.pop(context, searchText);
                        } else {
                          AppDialogs.showSnackBar(
                            controller.context,
                            message: 'Please enter text to search',
                            type: SnackBarType.warning,
                          );
                        }
                      },
                      child: Text('Search'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    ).then((searchText) async {
      if (searchText != null && searchText.isNotEmpty) {
        await _searchTextInPdf(searchText);
      }
    });
  }

  Future<void> _searchTextInPdf(String searchText) async {
    controller.isProcessing = true;

    try {
      final String fileExtension = path
          .extension(controller.pages[0].path)
          .toLowerCase()
          .replaceAll('.', '');
      String pdfPath;
      bool isTemporary = false;

      if (fileExtension != 'pdf') {
        pdfPath = await controller.pdfService
            .createPdfFromImages(controller.pages, 'temp_for_search');
        isTemporary = true;
      } else {
        pdfPath = controller.pages[0].path;
      }

      final List<TextSearchResult> searchResults = await _findTextInPdf(
          pdfPath, searchText, controller.passwordController.text);

      if (isTemporary) File(pdfPath).deleteSync();
      _showSearchResultsDialog(searchText, searchResults);
    } catch (e) {
      AppDialogs.showSnackBar(
        controller.context,
        message: 'Error searching text: $e',
        type: SnackBarType.error,
      );
    } finally {
      controller.isProcessing = false;
    }
  }

  Future<List<TextSearchResult>> _findTextInPdf(
      String pdfPath, String searchText,
      [String? password]) async {
    try {
      final PdfDocument document = password?.isNotEmpty == true
          ? PdfDocument(
              inputBytes: File(pdfPath).readAsBytesSync(), password: password)
          : PdfDocument(inputBytes: File(pdfPath).readAsBytesSync());
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final int pageCount = document.pages.count;
      List<TextSearchResult> allResults = [];

      for (int i = 0; i < pageCount; i++) {
        try {
          final List<MatchedItem> pageResults = extractor
              .findText([searchText], startPageIndex: i, endPageIndex: i);
          for (var item in pageResults) {
            allResults.add(TextSearchResult(
                pageIndex: i, text: item.text, bounds: item.bounds));
          }
        } catch (e) {
          print('Error searching on page $i: $e');
        }
      }

      document.dispose();
      return allResults;
    } catch (e) {
      throw Exception('Failed to search text: $e');
    }
  }

  void _showSearchResultsDialog(
      String searchText, List<TextSearchResult> results) {
    showModalBottomSheet(
      context: controller.context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.search,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Search Results',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            'Found ${results.length} matches for "$searchText"',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'No matches found',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Text('Try searching with different keywords',
                                style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final result = results[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Text(
                                '${result.pageIndex + 1}',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                  fontSize: 14,
                                ),
                                children: _highlightOccurrences(
                                  result.text,
                                  searchText,
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            subtitle: Text('Page ${result.pageIndex + 1}'),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> _highlightOccurrences(
      String text, String searchQuery, Color highlightColor) {
    if (searchQuery.isEmpty) return [TextSpan(text: text)];

    List<TextSpan> spans = [];
    int start = 0;
    final String lowerCaseText = text.toLowerCase();
    final String lowerCaseQuery = searchQuery.toLowerCase();

    while (true) {
      final int index = lowerCaseText.indexOf(lowerCaseQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start)
        spans.add(TextSpan(text: text.substring(start, index)));
      spans.add(TextSpan(
        text: text.substring(index, index + searchQuery.length),
        style: TextStyle(
          backgroundColor: highlightColor.withOpacity(0.3),
          fontWeight: FontWeight.bold,
          color: highlightColor.computeLuminance() > 0.5
              ? Colors.black
              : Colors.white,
        ),
      ));
      start = index + searchQuery.length;
    }
    return spans;
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
