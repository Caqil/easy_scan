import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/main.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class CustomizableQRCode extends StatefulWidget {
  final String data;
  final String? initialTitle;
  final Function(File) onSaveQR;

  const CustomizableQRCode({
    super.key,
    required this.data,
    this.initialTitle,
    required this.onSaveQR,
  });

  @override
  State<CustomizableQRCode> createState() => _CustomizableQRCodeState();
}

class _CustomizableQRCodeState extends State<CustomizableQRCode> {
  // QR Code customization options
  late String title;
  Color foregroundColor = Colors.black;
  Color backgroundColor = Colors.white;
  List<Color> gradientColors = [Colors.blue, Colors.purple];
  bool useGradient = false;
  QrEyeShape eyeShape = QrEyeShape.square;
  QrDataModuleShape dataModuleShape = QrDataModuleShape.square;
  double qrSize = 250;
  double borderRadius = 16;
  bool showShadow = true;

  // Logo options
  Uint8List? logoBytes;
  double logoSize = 60;
  bool showLogo = false;

  // Controller for the QR code global key (for capturing)
  final GlobalKey qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    title = widget.initialTitle ?? 'custom_qr.default_title'.tr();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // QR Code Preview
        RepaintBoundary(
          key: qrKey,
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: useGradient
                  ? LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: useGradient ? null : backgroundColor,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: showShadow
                  ? [
                      BoxShadow(
                        color:
                            (useGradient ? gradientColors[0] : foregroundColor)
                                .withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                        spreadRadius: 5,
                      )
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                AutoSizeText(
                  title,
                  style: GoogleFonts.slabo27px(
                    color: useGradient ? Colors.white : foregroundColor,
                    fontSize: 16.adaptiveSp,
                    fontWeight: FontWeight.bold,
                    shadows: useGradient
                        ? [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            )
                          ]
                        : null,
                  ),
                ),
                SizedBox(height: 16.h),
                // QR Code
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(borderRadius / 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: widget.data,
                    version: QrVersions.auto,
                    size: qrSize,
                    backgroundColor: Colors.white,
                    foregroundColor: foregroundColor,
                    embeddedImage: showLogo && logoBytes != null
                        ? MemoryImage(logoBytes!)
                        : null,
                    embeddedImageStyle: showLogo && logoBytes != null
                        ? QrEmbeddedImageStyle(
                            size: Size(logoSize, logoSize),
                          )
                        : null,
                    eyeStyle: QrEyeStyle(
                      eyeShape: eyeShape,
                      color: useGradient ? gradientColors[1] : foregroundColor,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: dataModuleShape,
                      color: useGradient ? gradientColors[0] : foregroundColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 24.h),

        // Customization Controls
        _buildCustomizationPanel(),
      ],
    );
  }

  Widget _buildCustomizationPanel() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(
            'custom_qr.customize_title'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 16.adaptiveSp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),

          // Title input
          TextFormField(
            decoration: InputDecoration(
              labelText: 'custom_qr.title_label'.tr(),
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            ),
            initialValue: title,
            onChanged: (value) {
              setState(() {
                title = value;
              });
            },
          ),
          SizedBox(height: 16.h),

          // Gradient toggle
          SwitchListTile(
            title: AutoSizeText('custom_qr.use_gradient'.tr()),
            value: useGradient,
            onChanged: (value) {
              setState(() {
                useGradient = value;
              });
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),

          // Color selection
          if (useGradient)
            _buildColorSelection(
              'custom_qr.gradient_colors'.tr(),
              gradientColors,
              (colors) {
                setState(() {
                  gradientColors = colors;
                });
              },
            )
          else
            _buildColorPicker(
              'custom_qr.qr_color'.tr(),
              foregroundColor,
              (color) {
                setState(() {
                  foregroundColor = color;
                });
              },
            ),

          SizedBox(height: 16.h),

          // Eye shape selection
          AutoSizeText(
            'custom_qr.eye_shape'.tr(),
            style: GoogleFonts.slabo27px(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          _buildEyeShapeSelector(),

          SizedBox(height: 16.h),

          // Data module shape selection
          AutoSizeText(
            'custom_qr.data_module_shape'.tr(),
            style: GoogleFonts.slabo27px(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          _buildDataModuleShapeSelector(),

          SizedBox(height: 16.h),

          // Shadow toggle
          SwitchListTile(
            title: AutoSizeText('custom_qr.show_shadow'.tr()),
            value: showShadow,
            onChanged: (value) {
              setState(() {
                showShadow = value;
              });
            },
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),

          SizedBox(height: 16.h),

          // Logo options
          ExpansionTile(
            title: AutoSizeText('custom_qr.logo_options'.tr()),
            children: [
              SwitchListTile(
                title: AutoSizeText('custom_qr.show_logo'.tr()),
                value: showLogo,
                onChanged: (value) {
                  setState(() {
                    showLogo = value;
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              if (showLogo) ...[
                SizedBox(height: 12.h),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickLogo,
                      icon: Icon(Icons.image),
                      label: AutoSizeText('custom_qr.select_logo'.tr()),
                    ),
                    SizedBox(width: 12.w),
                    if (logoBytes != null)
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: Image.memory(
                            logoBytes!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
                AutoSizeText('custom_qr.logo_size'.tr()),
                Slider(
                  value: logoSize,
                  min: 30,
                  max: 100,
                  divisions: 14,
                  label: logoSize.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      logoSize = value;
                    });
                  },
                ),
              ],
            ],
          ),

          SizedBox(height: 24.h),

          // Export button
          OutlinedButton.icon(
            onPressed: _captureAndExportQR,
            icon: Icon(Icons.save),
            label: AutoSizeText('custom_qr.save_qr'.tr()),
            style: OutlinedButton.styleFrom(
              minimumSize: Size(double.infinity, 48.h),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(
      String label, Color currentColor, Function(Color) onColorChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoSizeText(
          label,
          style: GoogleFonts.slabo27px(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 12.h,
          children: [
            _buildColorOption(Colors.black, currentColor, onColorChanged),
            _buildColorOption(
                Colors.blue.shade800, currentColor, onColorChanged),
            _buildColorOption(
                Colors.red.shade800, currentColor, onColorChanged),
            _buildColorOption(
                Colors.green.shade800, currentColor, onColorChanged),
            _buildColorOption(
                Colors.purple.shade800, currentColor, onColorChanged),
            _buildColorOption(
                Colors.orange.shade800, currentColor, onColorChanged),
            _buildColorOption(
                Colors.teal.shade800, currentColor, onColorChanged),
            _buildColorOption(
                Colors.indigo.shade800, currentColor, onColorChanged),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSelection(String label, List<Color> currentColors,
      Function(List<Color>) onColorsChanged) {
    // Predefined gradient pairs
    final gradientPairs = [
      [Colors.blue, Colors.purple],
      [Colors.green, Colors.teal],
      [Colors.orange, Colors.red],
      [Colors.pink, Colors.purple],
      [Colors.indigo, Colors.blue],
      [Colors.deepPurple, Colors.indigo],
      [Colors.red, Colors.pink],
      [Colors.teal, Colors.cyan],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoSizeText(
          label,
          style: GoogleFonts.slabo27px(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 50.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: gradientPairs.length,
            itemBuilder: (context, index) {
              final gradient = gradientPairs[index];
              final isSelected = currentColors[0] == gradient[0] &&
                  currentColors[1] == gradient[1];

              return GestureDetector(
                onTap: () => onColorsChanged(gradient),
                child: Container(
                  width: 60.w,
                  margin: EdgeInsets.only(right: 12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? Center(
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorOption(
      Color color, Color selectedColor, Function(Color) onColorChanged) {
    final isSelected = color.value == selectedColor.value;

    return GestureDetector(
      onTap: () => onColorChanged(color),
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color: Colors.white,
                size: 20.adaptiveSp,
              )
            : null,
      ),
    );
  }

  Widget _buildEyeShapeSelector() {
    final eyeShapes = {
      QrEyeShape.square: 'custom_qr.eye_shape_square'.tr(),
      QrEyeShape.circle: 'custom_qr.eye_shape_circle'.tr(),
    };

    return Wrap(
      spacing: 12.w,
      children: eyeShapes.entries.map((entry) {
        final isSelected = eyeShape == entry.key;

        return ChoiceChip(
          label: AutoSizeText(entry.value),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                eyeShape = entry.key;
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildDataModuleShapeSelector() {
    final moduleShapes = {
      QrDataModuleShape.square: 'custom_qr.data_module_square'.tr(),
      QrDataModuleShape.circle: 'custom_qr.data_module_circle'.tr(),
    };

    return Wrap(
      spacing: 12.w,
      children: moduleShapes.entries.map((entry) {
        final isSelected = dataModuleShape == entry.key;

        return ChoiceChip(
          label: AutoSizeText(entry.value),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                dataModuleShape = entry.key;
              });
            }
          },
        );
      }).toList(),
    );
  }

  Future<void> _pickLogo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final imageBytes = await image.readAsBytes();
        setState(() {
          logoBytes = imageBytes;
        });
      }
    } catch (e) {
      logger.error('Error picking logo: $e');
      // Show error to user
    }
  }

  Future<void> _captureAndExportQR() async {
    try {
      // Capture the QR code widget
      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('custom_qr.capture_failed'.tr());
      }

      // Convert to uint8list
      Uint8List pngBytes = byteData.buffer.asUint8List();

      // Create temporary file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final filePath = '${tempDir.path}/qr_code_$timestamp.png';

      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // Return the file to the callback
      widget.onSaveQR(file);
    } catch (e) {
      logger.error('Error capturing QR code: $e');
      // Show error to user
    }
  }
}
