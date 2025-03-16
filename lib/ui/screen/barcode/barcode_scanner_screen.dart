import 'package:easy_scan/models/barcode_scan.dart';
import 'package:easy_scan/providers/barcode_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_scan/ui/common/app_bar.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  MobileScannerController? _controller;
  bool _isScanning = true;
  Barcode? _lastDetectedBarcode;
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  void _initScanner() {
    _controller = MobileScannerController(
      facing: _isFrontCamera ? CameraFacing.front : CameraFacing.back,
      torchEnabled: _isFlashOn,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(
          'Scan Barcode',
          style: GoogleFonts.notoSerif(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () => _toggleFlash(),
          ),
          IconButton(
            icon: Icon(_isFrontCamera ? Icons.camera_front : Icons.camera_rear),
            onPressed: () => _toggleCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scan instructions
          Container(
            padding: EdgeInsets.all(16.w),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Position the barcode within the frame to scan',
                    style: GoogleFonts.notoSerif(
                      fontSize: 14.sp,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scanner view
          Expanded(
            child: _buildScannerView(),
          ),

          // Result display
          if (_lastDetectedBarcode != null && !_isScanning) _buildResultCard(),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
      floatingActionButton: _lastDetectedBarcode != null && !_isScanning
          ? FloatingActionButton(
              onPressed: _resumeScanning,
              child: const Icon(Icons.qr_code_scanner),
            )
          : null,
    );
  }

  Widget _buildScannerView() {
    if (_controller == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Scanner
        MobileScanner(
          controller: _controller,
          onDetect: _onBarcodeDetected,
        ),

        // Scanning overlay with animation
        if (_isScanning) ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.6),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            width: 250.w,
            height: 250.w,
          ),

          // Scan line animation
          _buildScanLineAnimation(),
        ],
      ],
    );
  }

  Widget _buildScanLineAnimation() {
    return SizedBox(
        width: 250.w,
        height: 250.w,
        child: Align(
          alignment: const Alignment(0, 0),
          child: Container(
            height: 2,
            width: 230.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Theme.of(context).primaryColor,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildResultCard() {
    final barcode = _lastDetectedBarcode!;

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.qr_code,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(width: 8.w),
              Text(
                'Scan Result',
                style: GoogleFonts.notoSerif(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Spacer(),
              _buildTypeBadge(barcode.format.name),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              barcode.rawValue ?? 'No data',
              style: GoogleFonts.notoSerif(
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                  onPressed: () => _copyToClipboard(barcode.rawValue ?? ''),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('Save'),
                  onPressed: () => _saveScanToHistory(barcode),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String format) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        format,
        style: GoogleFonts.notoSerif(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing || !_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _isScanning = false;
      _lastDetectedBarcode = barcodes.first;
      _isProcessing = false;
    });

    // Vibrate for feedback
    HapticFeedback.mediumImpact();
  }

  void _resumeScanning() {
    setState(() {
      _isScanning = true;
      _lastDetectedBarcode = null;
    });
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
      _controller?.toggleTorch();
    });
  }

  void _toggleCamera() {
    setState(() {
      _isFrontCamera = !_isFrontCamera;
      _controller?.switchCamera();
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    AppDialogs.showSnackBar(
      context,
      message: 'Copied to clipboard',
      type: SnackBarType.success,
    );
  }

  void _saveScanToHistory(Barcode barcode) {
    // Create BarcodeScan object
    final scan = BarcodeScan(
      barcodeValue: barcode.rawValue ?? '',
      barcodeType: _getBarcodeType(barcode),
      barcodeFormat: barcode.format.name,
      timestamp: DateTime.now(),
    );

    // Add to provider
    ref.read(barcodeScanHistoryProvider.notifier).addScan(scan);

    // Show confirmation
    AppDialogs.showSnackBar(
      context,
      message: 'Barcode saved to history',
      type: SnackBarType.success,
    );
  }

  String _getBarcodeType(Barcode barcode) {
    // Try to determine the type of content in the barcode
    final value = barcode.rawValue ?? '';

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return 'URL';
    } else if (value.startsWith('mailto:')) {
      return 'EMAIL';
    } else if (value.startsWith('tel:')) {
      return 'PHONE';
    } else if (value.startsWith('WIFI:')) {
      return 'WIFI';
    } else if (value.startsWith('BEGIN:VCARD')) {
      return 'CONTACT';
    } else if (value.startsWith('geo:')) {
      return 'LOCATION';
    } else if (value.startsWith('smsto:') || value.startsWith('sms:')) {
      return 'SMS';
    } else {
      return 'TEXT';
    }
  }
}
