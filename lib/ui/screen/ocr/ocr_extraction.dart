import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/services/ocr_service.dart';
import 'package:scanpro/ui/common/app_bar.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/ui/screen/premium/premium_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class OcrExtractionScreen extends ConsumerStatefulWidget {
  final Document document;

  const OcrExtractionScreen({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<OcrExtractionScreen> createState() =>
      _OcrExtractionScreenState();
}

class _OcrExtractionScreenState extends ConsumerState<OcrExtractionScreen> {
  bool _isProcessing = false;
  bool _isExtracted = false;
  String _extractedText = '';
  String _errorMessage = '';
  double _progress = 0.0;
  String _selectedLanguage = 'eng';
  bool _enhanceScanned = true;
  bool _preserveLayout = true;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _languages = [
    {'code': 'eng', 'name': 'English'},
    {'code': 'spa', 'name': 'Spanish'},
    {'code': 'fra', 'name': 'French'},
    {'code': 'deu', 'name': 'German'},
    {'code': 'ita', 'name': 'Italian'},
    {'code': 'por', 'name': 'Portuguese'},
    {'code': 'rus', 'name': 'Russian'},
    {'code': 'chi_sim', 'name': 'Chinese (Simplified)'},
    {'code': 'chi_tra', 'name': 'Chinese (Traditional)'},
    {'code': 'jpn', 'name': 'Japanese'},
    {'code': 'kor', 'name': 'Korean'},
    {'code': 'ara', 'name': 'Arabic'},
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOcrAvailability();
    });
  }

  Future<void> _checkOcrAvailability() async {
    final ocrService = ref.read(ocrServiceProvider);
    final isAvailable = await ocrService.isOcrAvailable();

    if (!isAvailable && mounted) {
      _showPremiumDialog();
    }
  }

  void _showPremiumDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('ocr.premium_required.title'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              color: Colors.amber,
              size: 64.r,
            ),
            SizedBox(height: 16.h),
            Text(
              'ocr.premium_required.message'.tr(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: Text('common.upgrade'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _extractText() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = '';
      _progress = 0.0;
    });

    try {
      final ocrService = ref.read(ocrServiceProvider);

      final result = await ocrService.extractTextFromDocument(
        document: widget.document,
        language: _selectedLanguage,
        enhanceScanned: _enhanceScanned,
        preserveLayout: _preserveLayout,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );

      if (result.success) {
        setState(() {
          _extractedText = result.text;
          _textController.text = result.text;
          _isExtracted = true;
          _isProcessing = false;
        });
      } else {
        setState(() {
          _errorMessage = result.error ?? 'ocr.unknown_error'.tr();
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isProcessing = false;
      });
    }
  }

  void _shareExtractedText() {
    if (_extractedText.isEmpty) return;

    Share.share(
      _extractedText,
      subject: 'Extracted text from ${widget.document.name}',
    );
  }

  void _copyToClipboard() {
    if (_extractedText.isEmpty) return;

    Clipboard.setData(ClipboardData(text: _extractedText)).then((_) {
      AppDialogs.showSnackBar(
        context,
        message: 'ocr.copied_to_clipboard'.tr(),
        type: SnackBarType.success,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(
          'ocr.extract_text'.tr(),
          style: GoogleFonts.slabo27px(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: _isExtracted
            ? [
                IconButton(
                  icon: const Icon(Icons.content_copy),
                  tooltip: 'ocr.copy'.tr(),
                  onPressed: _copyToClipboard,
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'common.share'.tr(),
                  onPressed: _shareExtractedText,
                ),
              ]
            : null,
      ),
      body: _isExtracted ? _buildResultsView() : _buildExtractionView(),
    );
  }

  Widget _buildExtractionView() {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document info card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  // Document thumbnail or icon
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: widget.document.thumbnailPath != null &&
                            File(widget.document.thumbnailPath!).existsSync()
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.file(
                              File(widget.document.thumbnailPath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.picture_as_pdf,
                            color: Theme.of(context).primaryColor,
                            size: 32.r,
                          ),
                  ),
                  SizedBox(width: 16.w),
                  // Document details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.document.name,
                          style: GoogleFonts.slabo27px(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'ocr.pages_count'.tr(
                            namedArgs: {
                              'count': widget.document.pageCount.toString(),
                              's': widget.document.pageCount != 1 ? 's' : '',
                            },
                          ),
                          style: GoogleFonts.slabo27px(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 24.h),

          // OCR Settings
          Text(
            'ocr.extraction_settings'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 16.h),

          // Language selection
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'ocr.language'.tr(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              prefixIcon: const Icon(Icons.language),
            ),
            value: _selectedLanguage,
            items: _languages.map((language) {
              return DropdownMenuItem<String>(
                value: language['code'],
                child: Text(language['name']),
              );
            }).toList(),
            onChanged: _isProcessing
                ? null
                : (value) {
                    if (value != null) {
                      setState(() {
                        _selectedLanguage = value;
                      });
                    }
                  },
          ),

          SizedBox(height: 16.h),

          // OCR Options
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: Text(
                    'ocr.enhance_scanned'.tr(),
                    style: GoogleFonts.slabo27px(
                      fontSize: 14.sp,
                    ),
                  ),
                  value: _enhanceScanned,
                  onChanged: _isProcessing
                      ? null
                      : (value) {
                          setState(() {
                            _enhanceScanned = value ?? true;
                          });
                        },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: Text(
                    'ocr.preserve_layout'.tr(),
                    style: GoogleFonts.slabo27px(
                      fontSize: 14.sp,
                    ),
                  ),
                  value: _preserveLayout,
                  onChanged: _isProcessing
                      ? null
                      : (value) {
                          setState(() {
                            _preserveLayout = value ?? true;
                          });
                        },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          if (_errorMessage.isNotEmpty)
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 24.r,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: GoogleFonts.slabo27px(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          if (_isProcessing)
            Column(
              children: [
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                SizedBox(height: 8.h),
                Text(
                  'ocr.processing'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),

          SizedBox(height: 16.h),

          // Start extraction button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _extractText,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16.r),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'ocr.start_extraction'.tr(),
                style: GoogleFonts.slabo27px(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    return Column(
      children: [
        // Options bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                'ocr.extracted_text'.tr(),
                style: GoogleFonts.slabo27px(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.save_alt),
                tooltip: 'ocr.save'.tr(),
                onPressed: _saveExtractedText,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'ocr.extract_again'.tr(),
                onPressed: _resetExtraction,
              ),
            ],
          ),
        ),

        // Text area
        Expanded(
          child: _extractedText.isEmpty
              ? Center(
                  child: Text(
                    'ocr.no_text_found'.tr(),
                    style: GoogleFonts.slabo27px(
                      fontSize: 16.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                )
              : Padding(
                  padding: EdgeInsets.all(16.r),
                  child: TextField(
                    controller: _textController,
                    scrollController: _scrollController,
                    maxLines: null,
                    expands: true,
                    readOnly: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      hintText: 'ocr.extracted_text_placeholder'.tr(),
                      contentPadding: EdgeInsets.all(16.r),
                    ),
                    style: GoogleFonts.robotoMono(
                      fontSize: 14.sp,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _resetExtraction() {
    setState(() {
      _isExtracted = false;
      _extractedText = '';
      _textController.clear();
    });
  }

  Future<void> _saveExtractedText() async {
    if (_extractedText.isEmpty) return;

    try {
      // Create a text file with the extracted content
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${widget.document.name}_ocr_$timestamp.txt';
      final filePath = path.join(directory.path, fileName);

      final file = File(filePath);
      await file.writeAsString(_extractedText);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Extracted text from ${widget.document.name}',
      );
    } catch (e) {
      AppDialogs.showSnackBar(
        context,
        message: 'ocr.save_error'.tr(namedArgs: {'error': e.toString()}),
        type: SnackBarType.error,
      );
    }
  }
}
