import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';

enum SnackBarType {
  normal,
  success,
  error,
  warning,
}

class AppDialogs {
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDangerous = false,
  }) async {
    final result = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, setState) => CupertinoAlertDialog(
                title: Text(title),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(cancelText),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(context, true);
                    },
                    style: isDangerous
                        ? TextButton.styleFrom(foregroundColor: Colors.red)
                        : null,
                    child: Text(confirmText),
                  ),
                ],
              ),
            ));

    return result ?? false;
  }

  static Future<String?> showInputDialog(
    BuildContext context, {
    required String title,
    String? initialValue,
    String hintText = '',
    String confirmText = 'Save',
    String cancelText = 'Cancel',
    bool isPassword = false,
  }) async {
    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: Text(confirmText),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  static void showSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    SnackBarType type = SnackBarType.normal,
    Color? backgroundColor,
    Color? textColor,
    double bottomMargin = 16.0,
  }) {
    // Determine colors based on type
    Color snackBarColor;
    Color snackBarTextColor = textColor ?? Colors.white;

    switch (type) {
      case SnackBarType.success:
        snackBarColor = backgroundColor ?? Colors.green.shade700;
        break;
      case SnackBarType.error:
        snackBarColor = backgroundColor ?? Colors.red.shade700;
        break;
      case SnackBarType.warning:
        snackBarColor = backgroundColor ?? Colors.amber.shade900;
        break;
      case SnackBarType.normal:
        snackBarColor = backgroundColor ?? const Color(0xFF323232);
        break;
    }

    // Create overlay entry
    OverlayState? overlayState = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (BuildContext context) => Positioned(
        bottom: MediaQuery.of(context).viewInsets.bottom + bottomMargin,
        left: 16.0,
        right: 16.0,
        child: Material(
          elevation: 6.0,
          borderRadius: BorderRadius.circular(8.0),
          color: snackBarColor,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: action != null ? 16.0 : 24.0,
              vertical: 14.0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.slabo27px(
                      fontWeight: FontWeight.w700,
                      color: snackBarTextColor,
                      fontSize: 14.0,
                    ),
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: 8.0),
                  TextButton(
                    onPressed: () {
                      // Remove the overlay first
                      overlayEntry?.remove();
                      overlayEntry = null;

                      // Then trigger the action
                      action.onPressed();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: action.textColor ?? Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      backgroundColor: Colors.transparent,
                    ),
                    child: Text(action.label),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    // Insert the overlay and schedule removal after duration
    overlayState.insert(overlayEntry!);

    Future.delayed(duration, () {
      if (overlayEntry != null) {
        overlayEntry?.remove();
        overlayEntry = null;
      }
    });
  }
}
