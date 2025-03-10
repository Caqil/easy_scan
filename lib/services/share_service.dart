import 'dart:io';
import 'package:share_plus/share_plus.dart';

class ShareService {
  /// Share PDF file
  Future<void> sharePdf(String pdfPath, {String? subject}) async {
    final File file = File(pdfPath);
    if (await file.exists()) {
      await Share.shareXFiles(
        [XFile(pdfPath)],
        subject: subject,
      );
    } else {
      throw Exception('File does not exist');
    }
  }

  /// Share multiple files
  Future<void> shareFiles(List<String> filePaths, {String? subject}) async {
    final List<XFile> files = [];

    for (var path in filePaths) {
      final File file = File(path);
      if (await file.exists()) {
        files.add(XFile(path));
      }
    }

    if (files.isNotEmpty) {
      await Share.shareXFiles(
        files,
        subject: subject,
      );
    } else {
      throw Exception('No valid files to share');
    }
  }
}
