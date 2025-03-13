// import 'dart:io';
// import 'package:easy_scan/config/routes.dart';
// import 'package:easy_scan/models/document.dart';
// import 'package:easy_scan/providers/document_provider.dart';
// import 'package:easy_scan/services/file_converter_service.dart';
// import 'package:easy_scan/ui/common/app_bar.dart';
// import 'package:easy_scan/ui/common/dialogs.dart';
// import 'package:easy_scan/ui/common/loading.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:file_picker/file_picker.dart';

// class FileConverterScreen extends ConsumerStatefulWidget {
//   const FileConverterScreen({super.key});

//   @override
//   ConsumerState<FileConverterScreen> createState() =>
//       _FileConverterScreenState();
// }

// class _FileConverterScreenState extends ConsumerState<FileConverterScreen> {
//   final FileConverterService _converterService = FileConverterService();
//   final TextEditingController _documentNameController = TextEditingController(
//       text: 'Converted_${DateTime.now().toString().substring(0, 10)}');

//   List<File> _selectedFiles = [];
//   bool _isLoading = false;
//   String _loadingMessage = '';

//   @override
//   void dispose() {
//     _documentNameController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickFiles() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowMultiple: true,
//         allowedExtensions: [
//           'pdf',
//           'doc',
//           'docx',
//           'xls',
//           'xlsx',
//           'ppt',
//           'pptx',
//           'txt',
//           'rtf',
//           'csv',
//           'odt',
//           'ods',
//           'odp',
//           'jpg',
//           'jpeg',
//           'png',
//           'gif',
//           'bmp',
//           'tiff',
//           'tif',
//           'webp',
//           'html',
//           'htm'
//         ],
//       );

//       if (result != null) {
//         setState(() {
//           _selectedFiles = result.paths
//               .where((path) => path != null)
//               .map((path) => File(path!))
//               .toList();

//           if (_selectedFiles.length == 1) {
//             // Update the document name controller with the file name
//             final fileName = _selectedFiles.first.path.split('/').last;
//             final fileNameWithoutExtension = fileName.contains('.')
//                 ? fileName.substring(0, fileName.lastIndexOf('.'))
//                 : fileName;

//             _documentNameController.text = fileNameWithoutExtension;
//           }
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         AppDialogs.showSnackBar(
//           context,
//           message: 'Error picking files: ${e.toString()}',
//         );
//       }
//     }
//   }

//   Future<void> _convertFiles() async {
//     if (_selectedFiles.isEmpty) {
//       AppDialogs.showSnackBar(
//         context,
//         message: 'Please select files to convert',
//       );
//       return;
//     }

//     if (_documentNameController.text.trim().isEmpty) {
//       AppDialogs.showSnackBar(
//         context,
//         message: 'Please enter a document name',
//       );
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _loadingMessage = 'Converting files to PDF...';
//     });

//     try {
//       Document? document;

//       if (_selectedFiles.length == 1) {
//         // Convert single file
//         document = await _converterService.convertToPdf(_selectedFiles.first);
//       } else {
//         // Convert multiple files and merge them
//         document = await _converterService.convertMultipleFilesToPdf(
//           _selectedFiles,
//           _documentNameController.text.trim(),
//         );
//       }

//       if (document != null) {
//         // Add the document to the document provider
//         await ref.read(documentsProvider.notifier).addDocument(document);

//         if (mounted) {
//           AppDialogs.showSnackBar(
//             context,
//             message: 'File(s) converted and saved successfully',
//           );

//           // Navigate to view the converted document
//           Navigator.pop(context);
//           AppRoutes.navigateToView(context, document);
//         }
//       } else {
//         if (mounted) {
//           AppDialogs.showSnackBar(
//             context,
//             message: 'Failed to convert file(s)',
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         AppDialogs.showSnackBar(
//           context,
//           message: 'Error converting files: ${e.toString()}',
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: CustomAppBar(
//         title: const Text('Convert to PDF'),
//       ),
//       body: Stack(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Document name input
//                 TextField(
//                   controller: _documentNameController,
//                   decoration: const InputDecoration(
//                     labelText: 'Document Name',
//                     border: OutlineInputBorder(),
//                     prefixIcon: Icon(Icons.description),
//                   ),
//                   enabled: !_isLoading,
//                 ),

//                 const SizedBox(height: 24),

//                 // Selected files section
//                 Expanded(
//                   child: _selectedFiles.isEmpty
//                       ? _buildEmptyState()
//                       : _buildFilesList(),
//                 ),

//                 const SizedBox(height: 16),

//                 // Action buttons
//                 Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton.icon(
//                         onPressed: _isLoading ? null : _pickFiles,
//                         icon: const Icon(Icons.upload_file),
//                         label: const Text('Select Files'),
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: ElevatedButton.icon(
//                         onPressed: _isLoading || _selectedFiles.isEmpty
//                             ? null
//                             : _convertFiles,
//                         icon: const Icon(Icons.picture_as_pdf),
//                         label: const Text('Convert to PDF'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Theme.of(context).primaryColor,
//                           foregroundColor: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // Loading overlay
//           if (_isLoading)
//             Container(
//               color: Colors.black54,
//               child: Center(
//                 child: LoadingIndicator(message: _loadingMessage),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.upload_file,
//             size: 80,
//             color: Colors.grey.shade400,
//           ),
//           const SizedBox(height: 16),
//           const Text(
//             'No files selected',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Select files to convert to PDF',
//             style: TextStyle(
//               color: Colors.grey,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilesList() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Selected Files (${_selectedFiles.length})',
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Expanded(
//           child: ListView.builder(
//             itemCount: _selectedFiles.length,
//             itemBuilder: (context, index) {
//               final file = _selectedFiles[index];
//               final fileName = file.path.split('/').last;
//               final fileExtension = fileName.contains('.')
//                   ? fileName
//                       .substring(fileName.lastIndexOf('.') + 1)
//                       .toLowerCase()
//                   : '';

//               return Card(
//                 margin: const EdgeInsets.only(bottom: 8),
//                 child: ListTile(
//                   leading: _getFileIcon(fileExtension),
//                   title: Text(fileName),
//                   subtitle: Text('${fileExtension.toUpperCase()} file'),
//                   trailing: IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: _isLoading
//                         ? null
//                         : () {
//                             setState(() {
//                               _selectedFiles.removeAt(index);
//                             });
//                           },
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _getFileIcon(String extension) {
//     IconData iconData;
//     Color iconColor;

//     switch (extension.toLowerCase()) {
//       case 'pdf':
//         iconData = Icons.picture_as_pdf;
//         iconColor = Colors.red;
//         break;
//       case 'doc':
//       case 'docx':
//       case 'odt':
//       case 'rtf':
//       case 'txt':
//         iconData = Icons.description;
//         iconColor = Colors.blue;
//         break;
//       case 'xls':
//       case 'xlsx':
//       case 'ods':
//       case 'csv':
//         iconData = Icons.table_chart;
//         iconColor = Colors.green;
//         break;
//       case 'ppt':
//       case 'pptx':
//       case 'odp':
//         iconData = Icons.slideshow;
//         iconColor = Colors.orange;
//         break;
//       case 'jpg':
//       case 'jpeg':
//       case 'png':
//       case 'gif':
//       case 'bmp':
//       case 'tiff':
//       case 'tif':
//       case 'webp':
//         iconData = Icons.image;
//         iconColor = Colors.purple;
//         break;
//       case 'html':
//       case 'htm':
//         iconData = Icons.code;
//         iconColor = Colors.teal;
//         break;
//       default:
//         iconData = Icons.insert_drive_file;
//         iconColor = Colors.grey;
//         break;
//     }

//     return Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: iconColor.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Icon(iconData, color: iconColor),
//     );
//   }
// }
