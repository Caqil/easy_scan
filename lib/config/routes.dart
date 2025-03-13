import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/document.dart';
import '../models/folder.dart';
import '../ui/screen/camera_screen.dart';
import '../ui/screen/edit_screen.dart';
import '../ui/screen/folder_screen.dart';
import '../ui/screen/home/home_screen.dart';
import '../ui/screen/settings_screen.dart';
import '../ui/screen/view_screen.dart';

class AppRoutes {
  // Named routes
  static const String home = '/';
  static const String camera = '/camera';
  static const String edit = '/edit';
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
      case camera:
        return MaterialPageRoute(builder: (_) => const CameraScreen());
      case edit:
        return MaterialPageRoute(builder: (_) => const EditScreen());
      case view:
        final Document document = routeSettings.arguments as Document;
        return MaterialPageRoute(
            builder: (_) => ViewScreen(document: document));
      case folderRoute:
        final Folder folder = routeSettings.arguments as Folder;
        return MaterialPageRoute(builder: (_) => FolderScreen(folder: folder));
      case settings: // This line works now because 'settings' refers to the constant, not the parameter
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${routeSettings.name}'),
            ),
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

  static void navigateToEdit(BuildContext context) {
    Navigator.pushNamed(context, edit);
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
