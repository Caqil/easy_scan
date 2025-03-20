import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumBanner extends StatelessWidget {
  final VoidCallback onTap;

  const PremiumBanner({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFFF8A1C4), // Pink color
              Color(0xFFFFC107), // Orange color
            ],
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock Full Access!',
                    style: GoogleFonts.slabo27px(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Get Premium with a 3-day free trial',
                    style: GoogleFonts.slabo27px(
                      fontSize: 12.sp,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Play Now button
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 15.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A3EA1), // Purple button color
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      'Try Now',
                      style: GoogleFonts.slabo27px(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Candy graphics
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/icons/document.png', // Replace with your candy star asset
                  width: 60.w,
                  height: 60.h,
                  fit: BoxFit.contain,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Image.asset(
                    'assets/images/candy_circle.png', // Replace with your candy circle asset
                    width: 40.w,
                    height: 40.h,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
