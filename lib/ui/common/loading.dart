import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
            Text(
              message!,
              style: GoogleFonts.notoSerif(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
