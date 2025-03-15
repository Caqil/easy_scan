import 'package:easy_scan/ui/screen/compression/compression_screen.dart';
import 'package:easy_scan/ui/screen/merger/pdf_merge_screen.dart';
import 'package:flutter/material.dart';
import '../models/document.dart';
import '../models/folder.dart';
import '../ui/screen/edit/edit_screen.dart';
import '../ui/screen/folder/folder_screen.dart';
import '../ui/screen/home/home_screen.dart';
import '../ui/screen/view_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String edit = '/edit';
  static const String view = '/view';
  static const String folder = '/folder';
  static const String pdfMerger = '/pdf_merger';
  static const String compression = '/compression';
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case edit:
        final document = settings.arguments as Document?;
        return MaterialPageRoute(
            builder: (_) => EditScreen(document: document));
      case view:
        final document = settings.arguments as Document;
        return MaterialPageRoute(
            builder: (_) => ViewScreen(document: document));
      case folder:
        final folder = settings.arguments as Folder;
        return MaterialPageRoute(builder: (_) => FolderScreen(folder: folder));
      case compression:
        final args = settings.arguments as Map<String, dynamic>;
        final document = args['document'] as Document;
        return MaterialPageRoute(
          builder: (_) => CompressionScreen(document: document),
        );
      case pdfMerger:
        return MaterialPageRoute(builder: (_) => const PdfMergerScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      home,
      (route) => false,
    );
  }

  static void navigateToCompression(BuildContext context, Document document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompressionScreen(document: document),
      ),
    );
  }

  static void navigateToEdit(BuildContext context, {Document? document}) {
    Navigator.pushNamed(
      context,
      edit,
      arguments: document,
    );
  }

  static void navigateToView(BuildContext context, Document document) {
    Navigator.pushNamed(
      context,
      view,
      arguments: document,
    );
  }

  static void navigateToFolder(BuildContext context, Folder folder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderScreen(folder: folder),
      ),
    );
  }

  static void navigateToPdfMerger(BuildContext context) {
    Navigator.pushNamed(context, pdfMerger);
  }
}
