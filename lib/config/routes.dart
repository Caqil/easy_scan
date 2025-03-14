import 'package:easy_scan/providers/document_provider.dart';
import 'package:easy_scan/ui/screen/conversion/conversion_screen.dart';
import 'package:flutter/material.dart';
import '../models/document.dart';
import '../models/folder.dart';
import '../ui/screen/edit/edit_screen.dart';
import '../ui/screen/folder/folder_screen.dart';
import '../ui/screen/home/home_screen.dart';
import '../ui/screen/settings_screen.dart';
import '../ui/screen/view_screen.dart';

class AppRoutes {
  // Named routes
  static const String home = '/';
  static const String camera = '/camera';
  static const String edit = '/edit';
  static const String conversion = '/conversion';
  static const String view = '/view';
  static const String folderRoute =
      '/folder'; // Renamed to avoid naming conflict
  static const String settings = '/settings';
// Route generator
  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    // Renamed from 'settings' to 'routeSettings'
    switch (routeSettings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      // case camera:
      //   return MaterialPageRoute(builder: (_) => const CameraScreen());
      case edit:
        // Handle both with and without document arguments
        if (routeSettings.arguments != null) {
          // For editing an existing document
          return MaterialPageRoute(
            builder: (_) =>
                EditScreen(document: routeSettings.arguments as Document),
          );
        } else {
          // For creating a new document from scan
          return MaterialPageRoute(builder: (_) => const EditScreen());
        }
      case conversion:
        return MaterialPageRoute(builder: (_) => const ConversionScreen());
      case view:
        final Document document = routeSettings.arguments as Document;
        return MaterialPageRoute(
            builder: (_) => ViewScreen(document: document));
      case folderRoute:
        final Folder folder = routeSettings.arguments as Folder;
        return MaterialPageRoute(builder: (_) => FolderScreen());
      case settings: // This line works now because 'settings' refers to the constant, not the parameter
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Unknown route: ${routeSettings.name}')),
          ),
        );
    }
  }

  // Navigation helpers
  static void navigateToHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      home,
      (route) => false,
    );
  }

  static void navigateToCamera(BuildContext context) {
    Navigator.pushNamed(context, camera);
  }

  static void navigateToEdit(BuildContext context, {Document? document}) {
    if (document != null) {
      // Navigate with an existing document for editing
      Navigator.pushNamed(
        context,
        edit,
        arguments: document,
      );
    } else {
      // Navigate without a document for a new scan
      Navigator.pushNamed(context, edit);
    }
  }

  static void navigateToConversion(BuildContext context) {
    Navigator.pushNamed(context, conversion);
  }

  static void navigateToView(BuildContext context, Document document) {
    Navigator.pushNamed(
      context,
      view,
      arguments: document,
    );
  }

  static void navigateToFolder(BuildContext context, Folder folderObj) {
    Navigator.pushNamed(
      context,
      folderRoute, // Using the renamed constant
      arguments: folderObj,
    );
  }

  static void navigateToSettings(BuildContext context) {
    Navigator.pushNamed(context, settings);
  }
}
