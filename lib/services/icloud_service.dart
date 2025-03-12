// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:icloud_storage_sync/icloud_storage_sync.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:path/path.dart' as path;
// import '../models/document.dart';
// import '../utils/file_utils.dart';
// import 'pdf_service.dart';
// import 'image_service.dart';

// class ICloudService {
//   final IcloudStorageSync _iCloudStorageSync = IcloudStorageSync();
//   final PdfService _pdfService = PdfService();
//   final ImageService _imageService = ImageService();

//   /// Check if the app is running on iOS
//   bool get isIOS => Platform.isIOS;

//   /// Initialize iCloud integration
//   Future<void> initialize() async {
//     if (!isIOS) {
//       return;
//     }

//     try {
//       // Initialize iCloud service
//       await _iCloudStorageSync.getCloudFiles();
//       debugPrint('iCloud service initialized successfully');
//     } catch (e) {
//       debugPrint('Error initializing iCloud service: $e');
//     }
//   }

//   /// Check if iCloud access is available
//   Future<bool> isICloudAvailable() async {
//     if (!isIOS) {
//       return false;
//     }

//     try {
//       final bool isAvailable = await _iCloudStorageSync.isICloudAvailable();
//       return isAvailable;
//     } catch (e) {
//       debugPrint('Error checking iCloud availability: $e');
//       return false;
//     }
//   }

//   /// Enable iCloud document storage
//   Future<bool> enableICloudDocumentStorage({String? containerId}) async {
//     if (!isIOS) {
//       return false;
//     }

//     try {
//       final bool result = await _iCloudStorageSync.enableICloudDocumentStorage(
//         containerId: containerId,
//       );
//       return result;
//     } catch (e) {
//       debugPrint('Error enabling iCloud document storage: $e');
//       return false;
//     }
//   }

//   /// Get the iCloud document URL for a file
//   Future<String?> getDocumentURL(String documentName) async {
//     if (!isIOS) {
//       return null;
//     }

//     try {
//       final String? url = await _iCloudStorageSync.getDocumentURL(documentName);
//       return url;
//     } catch (e) {
//       debugPrint('Error getting iCloud document URL: $e');
//       return null;
//     }
//   }

//   /// List all available documents in iCloud
//   Future<List<String>> listAvailablePDFsInICloud() async {
//     if (!isIOS) {
//       return [];
//     }

//     try {
//       // Get all files in iCloud container
//       final List<String> allFiles =
//           await _iCloudStorageSync.listAllFiles() ?? [];

//       // Filter for PDF files only
//       return allFiles
//           .where((file) => file.toLowerCase().endsWith('.pdf'))
//           .toList();
//     } catch (e) {
//       debugPrint('Error listing iCloud documents: $e');
//       return [];
//     }
//   }

//   /// Copy PDF file from iCloud to local storage
//   Future<Document?> importPdfFromICloud(String iCloudFileName) async {
//     if (!isIOS) {
//       return null;
//     }

//     try {
//       // Make sure iCloud is available
//       final bool isAvailable = await isICloudAvailable();
//       if (!isAvailable) {
//         throw Exception('iCloud is not available or not enabled');
//       }

//       // Get file URL in iCloud
//       final String? iCloudFileUrl = await getDocumentURL(iCloudFileName);
//       if (iCloudFileUrl == null) {
//         throw Exception('Could not get file URL in iCloud');
//       }

//       // Download the file to local storage
//       final Directory tempDir = await getTemporaryDirectory();
//       final String tempFilePath = path.join(tempDir.path, iCloudFileName);

//       final File tempFile = File(tempFilePath);

//       // Use the iCloud storage sync to download the file
//       final bool success = await _iCloudStorageSync.downloadFileFromICloud(
//         documentURL: iCloudFileUrl,
//         destinationPath: tempFilePath,
//       );

//       if (!success) {
//         throw Exception('Failed to download file from iCloud');
//       }

//       // Process the PDF
//       return await _processPdfFile(tempFile, iCloudFileName);
//     } catch (e) {
//       debugPrint('Error importing PDF from iCloud: $e');
//       return null;
//     }
//   }

//   /// Upload a document to iCloud
//   Future<bool> uploadDocumentToICloud(Document document) async {
//     if (!isIOS) {
//       return false;
//     }

//     try {
//       // Make sure iCloud is available
//       final bool isAvailable = await isICloudAvailable();
//       if (!isAvailable) {
//         throw Exception('iCloud is not available or not enabled');
//       }

//       // Create file in iCloud
//       final String fileName = path.basename(document.pdfPath);
//       final bool success = await _iCloudStorageSync.uploadFileToICloud(
//         sourcePath: document.pdfPath,
//         destinationName: fileName,
//       );

//       return success;
//     } catch (e) {
//       debugPrint('Error uploading document to iCloud: $e');
//       return false;
//     }
//   }

//   /// Show iCloud file picker
//   Future<Document?> pickAndImportPdfFromICloud() async {
//     if (!isIOS) {
//       return null;
//     }

//     try {
//       // List available PDFs
//       final List<String> availablePdfs = await listAvailablePDFsInICloud();

//       if (availablePdfs.isEmpty) {
//         debugPrint('No PDF files found in iCloud');
//         return null;
//       }

//       // For a real app, you'd show a UI to let the user pick one
//       // For this example, we'll just pick the first one
//       final String selectedPdf = availablePdfs.first;

//       // Import the selected PDF
//       return await importPdfFromICloud(selectedPdf);
//     } catch (e) {
//       debugPrint('Error picking PDF from iCloud: $e');
//       return null;
//     }
//   }

//   /// Enable iCloud sync for a document
//   Future<bool> enableSyncForDocument(Document document) async {
//     if (!isIOS) {
//       return false;
//     }

//     try {
//       // Upload the document to iCloud
//       final bool uploaded = await uploadDocumentToICloud(document);

//       if (uploaded) {
//         // In a real app, you might want to update the document model to indicate it's synced
//         debugPrint('Document synced to iCloud: ${document.name}');
//         return true;
//       }

//       return false;
//     } catch (e) {
//       debugPrint('Error enabling sync for document: $e');
//       return false;
//     }
//   }

//   /// Delete a document from iCloud
//   Future<bool> deleteDocumentFromICloud(String fileName) async {
//     if (!isIOS) {
//       return false;
//     }

//     try {
//       final bool deleted = await _iCloudStorageSync.deleteFile(fileName);
//       return deleted;
//     } catch (e) {
//       debugPrint('Error deleting document from iCloud: $e');
//       return false;
//     }
//   }

//   /// Process the imported PDF file and create a Document
//   Future<Document> _processPdfFile(File sourceFile, String originalName) async {
//     // Create a name for the document based on original filename
//     final String docName = path.basenameWithoutExtension(originalName);

//     // Copy file to app documents directory
//     final String targetPath = await FileUtils.getUniqueFilePath(
//       documentName: docName,
//       extension: 'pdf',
//     );

//     final File targetFile = await sourceFile.copy(targetPath);

//     // Get page count
//     final int pageCount = await _pdfService.getPdfPageCount(targetPath);

//     // Generate thumbnail
//     File? thumbnailFile;
//     try {
//       // For now, just create a simple thumbnail - in a real app,
//       // we would extract the first page as an image
//       thumbnailFile = await _imageService.createThumbnail(
//         File(targetPath),
//         size: 300,
//       );
//     } catch (e) {
//       debugPrint('Failed to generate thumbnail: $e');
//       // Continue without thumbnail
//     }

//     // Create document model
//     return Document(
//       name: docName,
//       pdfPath: targetPath,
//       pagesPaths: [
//         targetPath
//       ], // This would normally be the image paths of each page
//       pageCount: pageCount,
//       thumbnailPath: thumbnailFile?.path,
//     );
//   }
// }
