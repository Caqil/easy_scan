// import 'dart:io';
// import 'dart:typed_data';
// import 'package:cunning_document_scanner/cunning_document_scanner.dart';
// import 'package:easy_scan/models/document.dart';
// import 'package:easy_scan/utils/permission_utils.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:image_picker/image_picker.dart';

// import '../../../config/routes.dart';
// import '../../../providers/scan_provider.dart';
// import '../../../services/pdf_service.dart';
// import '../../common/app_bar.dart';
// import '../../common/dialogs.dart';
// import 'component/scan_initial_view.dart';

// class CameraScreen extends ConsumerStatefulWidget {
//   final Document? document;
//   const CameraScreen({
//     super.key,
//     this.document,
//   });

//   @override
//   ConsumerState<CameraScreen> createState() => _CameraScreenState();
// }

// class _CameraScreenState extends ConsumerState<CameraScreen> {
//   final PdfService _pdfService = PdfService();
//   final ImagePicker _imagePicker = ImagePicker();
//   bool _isLoading = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(
//         title: const Text('Scan Document'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.close),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           ScanInitialView(
//             onScanPressed: _scanDocuments,
//             onImportPressed: _pickImages,
//           ),
//           if (_isLoading)
//             Container(
//               color: Colors.black.withOpacity(0.5),
//               child: const Center(child: CircularProgressIndicator()),
//             ),
//         ],
//       ),
//     );
//   }

//   void _showPermissionDialog() {
//     AppDialogs.showConfirmDialog(
//       context,
//       title: 'Permission Required',
//       message:
//           'Camera permission is needed to scan documents. Would you like to open app settings?',
//       confirmText: 'Open Settings',
//       cancelText: 'Cancel',
//     ).then((confirmed) {
//       if (confirmed) {
//         PermissionUtils.openAppSettings();
//       }
//     });
//   }

//   Future<void> _scanDocuments() async {
//     // Check for camera permission first
//     final hasPermission = await PermissionUtils.hasCameraPermission();
//     if (!hasPermission) {
//       final granted = await PermissionUtils.requestCameraPermission();
//       if (!granted) {
//         _showPermissionDialog();
//         return;
//       }
//     }

//     try {
//       setState(() {
//         _isLoading = true;
//       });

//       // Get the pictures - this will show the scanner UI
//       List<String> imagePaths = [];
//       try {
//         imagePaths = await CunningDocumentScanner.getPictures(
//                 isGalleryImportAllowed: true) ??
//             [];
//       } catch (e) {
//         if (mounted) {
//           AppDialogs.showSnackBar(
//             context,
//             message: 'Error scanning: ${e.toString()}',
//           );
//         }
//         setState(() {
//           _isLoading = false;
//         });
//         return;
//       }

//       // User canceled or no images captured
//       if (imagePaths.isEmpty) {
//         setState(() {
//           _isLoading = false;
//         });
//         return;
//       }

//       // Pre-process path validation
//       List<File> validImageFiles = [];
//       for (String path in imagePaths) {
//         final File file = File(path);
//         if (await file.exists()) {
//           validImageFiles.add(file);
//         }
//       }

//       if (validImageFiles.isEmpty) {
//         if (mounted) {
//           AppDialogs.showSnackBar(
//             context,
//             message: 'No valid images found',
//           );
//         }
//         setState(() {
//           _isLoading = false;
//         });
//         return;
//       }

//       // Processing loading screen
//       if (mounted) {
//         showDialog(
//           context: context,
//           barrierDismissible: false,
//           builder: (context) => const AlertDialog(
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 16),
//                 Text('Processing scanned images...')
//               ],
//             ),
//           ),
//         );
//       }

//       // Process all images and add to scan provider
//       ref.read(scanProvider.notifier).clearPages(); // Clear any existing pages

//       for (File imageFile in validImageFiles) {
//         try {
//           ref.read(scanProvider.notifier).addPage(imageFile);
//         } catch (e) {
//           // Just skip failed images to improve reliability
//           print('Failed to process image: $e');
//         }
//       }

//       // Close the processing dialog
//       if (mounted && Navigator.of(context).canPop()) {
//         Navigator.of(context).pop();
//       }

//       setState(() {
//         _isLoading = false;
//       });

//       // If we have pages, navigate to edit screen
//       if (ref.read(scanProvider).hasPages) {
//         if (mounted) {
//           // Navigate to edit screen
//           AppRoutes.navigateToEdit(context);
//         }
//       }
//     } catch (e) {
//       // Close the processing dialog if it's open
//       if (mounted && Navigator.of(context).canPop()) {
//         Navigator.of(context).pop();
//       }

//       if (mounted) {
//         AppDialogs.showSnackBar(
//           context,
//           message: 'Error: ${e.toString()}',
//         );
//       }
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _pickImages() async {
//     try {
//       setState(() {
//         _isLoading = true;
//       });

//       final List<XFile> images = await _imagePicker.pickMultiImage();
//       if (images.isEmpty || !mounted) {
//         setState(() => _isLoading = false);
//         return;
//       }

//       // Clear any existing pages
//       ref.read(scanProvider.notifier).clearPages();

//       for (var image in images) {
//         final File imageFile = File(image.path);
//         ref.read(scanProvider.notifier).addPage(imageFile);
//       }

//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });

//         if (ref.read(scanProvider).hasPages) {
//           if (mounted) {
//             AppRoutes.navigateToEdit(context);
//           }
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         AppDialogs.showSnackBar(context, message: 'Error: ${e.toString()}');
//         setState(() => _isLoading = false);
//       }
//     }
//   }
// }
