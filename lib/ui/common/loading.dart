import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;

  const LoadingIndicator({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            AutoSizeText(
              message!,
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
                fontSize: 14.adaptiveSp,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
