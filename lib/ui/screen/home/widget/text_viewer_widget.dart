import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;

class TextViewerWidget extends StatelessWidget {
  final String filePath;
  final bool showAppBar;
  final VoidCallback? onShare;

  const TextViewerWidget({
    Key? key,
    required this.filePath,
    this.showAppBar = true,
    this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadTextFile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading file: ${snapshot.error}'),
              ],
            ),
          );
        }

        final textContent = snapshot.data ?? '';
        return _buildTextContent(context, textContent);
      },
    );
  }

  Future<String> _loadTextFile() async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }
      return await file.readAsString();
    } catch (e) {
      return 'Error loading file: $e';
    }
  }

  Widget _buildTextContent(BuildContext context, String content) {
    final extension =
        path.extension(filePath).toLowerCase().replaceAll('.', '');

    // For html files, use syntax highlighting
    if (extension == 'html' || extension == 'md') {
      String language = extension == 'html' ? 'html' : 'markdown';

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: HighlightView(
          content,
          language: language,
          theme: githubTheme,
          padding: const EdgeInsets.all(12),
          textStyle: GoogleFonts.sourceCodePro(fontSize: 14),
        ),
      );
    }

    // For regular text files
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        content,
        style: GoogleFonts.notoSerif(fontSize: 14),
      ),
    );
  }
}
