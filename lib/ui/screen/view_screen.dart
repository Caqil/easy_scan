import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:easy_scan/providers/document_provider.dart';
import 'package:easy_scan/utils/file_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/services/share_service.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:easy_scan/utils/date_utils.dart';
import 'home/widget/document_viewer_widget.dart';

class ViewScreen extends ConsumerStatefulWidget {
  final Document document;

  const ViewScreen({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<ViewScreen> createState() => _ViewScreenState();
}

class _ViewScreenState extends ConsumerState<ViewScreen>
    with SingleTickerProviderStateMixin {
  final ShareService _shareService = ShareService();
  bool _isLoading = false;
  bool _isToolbarVisible = true;
  bool _isInfoPanelVisible = false;
  late AnimationController _animationController;
  late Animation<Offset> _toolbarAnimation;
  late Animation<Offset> _infoPanelAnimation;

  @override
  void initState() {
    super.initState();

    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _toolbarAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _infoPanelAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Set status bar to match app theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    super.dispose();
  }

  void _toggleToolbar() {
    setState(() {
      _isToolbarVisible = !_isToolbarVisible;
      if (_isToolbarVisible) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }

      // Always hide info panel when toggling toolbar
      if (_isInfoPanelVisible) {
        _isInfoPanelVisible = false;
      }
    });
  }

  void _toggleInfoPanel() {
    setState(() {
      _isInfoPanelVisible = !_isInfoPanelVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.grey[100],
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: _toggleToolbar,
        child: Stack(
          children: [
            // PDF Viewer
            Positioned.fill(
              child: Hero(
                  tag: 'document_${widget.document.id}',
                  child: DocumentViewerWidget(
                    document: widget.document,
                    showAppBar: false,
                    onShare: _shareDocument,
                  )),
            ),

            // Top toolbar with animation
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _toolbarAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey[900]!.withOpacity(0.95)
                        : Colors.white.withOpacity(0.95),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              // Back button with border
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.grey[800]!
                                        : Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_rounded,
                                      size: 18),
                                  onPressed: () => Navigator.pop(context),
                                  tooltip: 'common.back'.tr(),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),

                              // Document title
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.document.name,
                                      style: GoogleFonts.notoSerif(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${widget.document.pageCount} pages',
                                      style: GoogleFonts.notoSerif(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Action buttons row with borders
                              Row(
                                children: [
                                  _buildActionButton(
                                    icon: Icons.share_rounded,
                                    tooltip: 'common.share'.tr(),
                                    onTap: _shareDocument,
                                    isDarkMode: isDarkMode,
                                  ),
                                  _buildActionButton(
                                    icon: Icons.print_rounded,
                                    tooltip: 'share.print'.tr(),
                                    onTap: _printPDF,
                                    isDarkMode: isDarkMode,
                                  ),
                                  _buildActionButton(
                                    icon: Icons.info_outline_rounded,
                                    tooltip: 'Document Info',
                                    onTap: _toggleInfoPanel,
                                    isActive: _isInfoPanelVisible,
                                    activeColor: primaryColor,
                                    isDarkMode: isDarkMode,
                                  ),
                                  _buildActionButton(
                                    icon: widget.document.isFavorite
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    tooltip: widget.document.isFavorite
                                        ? 'Remove from Favorites'
                                        : 'Add to Favorites',
                                    onTap: () {
                                      final updatedDoc =
                                          widget.document.copyWith(
                                        isFavorite: !widget.document.isFavorite,
                                        modifiedAt: DateTime.now(),
                                      );
                                      ref
                                          .read(documentsProvider.notifier)
                                          .updateDocument(updatedDoc);
                                      setState(() {
                                        widget.document.isFavorite =
                                            !widget.document.isFavorite;
                                      });
                                    }, // Implement favorite toggle
                                    isDarkMode: isDarkMode,
                                    isActive: widget.document.isFavorite,
                                    activeColor: Colors.amber,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Information panel (slides in from bottom)
            if (_isInfoPanelVisible)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey[900]!.withOpacity(0.95)
                        : Colors.white.withOpacity(0.95),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -4),
                      )
                    ],
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Handle bar
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          // Title with thumbnail
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Document thumbnail with border
                              Container(
                                width: 70,
                                height: 90,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: widget.document.thumbnailPath != null
                                      ? Image.file(
                                          File(widget.document.thumbnailPath!),
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: isDarkMode
                                              ? Colors.grey[800]
                                              : Colors.grey[200],
                                          child: Icon(
                                            Icons.picture_as_pdf,
                                            color:
                                                primaryColor.withOpacity(0.7),
                                            size: 30,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Document details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.document.name,
                                      style: GoogleFonts.notoSerif(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      icon: FileUtils.getFileTypeIcon(
                                          widget.document.pdfPath),
                                      label: FileUtils.getFileTypeLabel(
                                          widget.document.pdfPath),
                                      isDarkMode: isDarkMode,
                                    ),
                                    _buildInfoRow(
                                      icon: Icons.description_outlined,
                                      label:
                                          '${widget.document.pageCount} pages',
                                      isDarkMode: isDarkMode,
                                    ),
                                    _buildInfoRow(
                                      icon: Icons.access_time,
                                      label:
                                          'Created: ${DateTimeUtils.formatDateTime(widget.document.createdAt)}',
                                      isDarkMode: isDarkMode,
                                    ),
                                    if (widget.document.modifiedAt !=
                                        widget.document.createdAt)
                                      _buildInfoRow(
                                        icon: Icons.edit_calendar_outlined,
                                        label:
                                            'Modified: ${DateTimeUtils.formatDateTime(widget.document.modifiedAt)}',
                                        isDarkMode: isDarkMode,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Processing...',
                          style: GoogleFonts.notoSerif(
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper to build action buttons
  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDarkMode,
    bool isActive = false,
    Color activeColor = Colors.blue,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive
              ? activeColor.withOpacity(0.5)
              : (isDarkMode ? Colors.grey[800]! : Colors.grey[300]!),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive
              ? activeColor
              : (isDarkMode ? Colors.white70 : Colors.black54),
          size: 20,
        ),
        onPressed: onTap,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  // Helper to build info rows
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required bool isDarkMode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.notoSerif(
                fontSize: 13,
                color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareDocument() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _shareService.sharePdf(
        widget.document.pdfPath,
        subject: widget.document.name,
      );
    } catch (e) {
      // Show error
      // ignore: use_build_context_synchronously
      AppDialogs.showSnackBar(
        context,
        message: 'Error sharing document: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _printPDF() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Printing.layoutPdf(
        onLayout: (format) async => File(widget.document.pdfPath).readAsBytes(),
        name: widget.document.name,
      );
    } catch (e) {
      // Show error
      // ignore: use_build_context_synchronously
      AppDialogs.showSnackBar(
        context,
        message: 'Error printing document: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
