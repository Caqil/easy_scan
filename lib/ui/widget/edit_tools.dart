// import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// class EditTools extends StatelessWidget {
//   final VoidCallback onEditText;
//   const EditTools({
//     super.key,
//     required this.onEditText,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = Theme.of(context).colorScheme;

//     return Container(
//       decoration: BoxDecoration(
//         color: colorScheme.surface,
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(20),
//           topRight: Radius.circular(20),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(left: 12, bottom: 8),
//             child: Text(
//               'EDIT TOOLS',
//               style: GoogleFonts.notoSerif(
//                 fontSize: 10.sp,
//                 fontWeight: FontWeight.bold,
//                 color: colorScheme.onSurface.withOpacity(0.7),
//                 letterSpacing: 1.2,
//               ),
//             ),
//           ),
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: [
//                 const SizedBox(width: 12),
//                 _buildToolButton(
//                   context,
//                   title: 'Edit Text',
//                   icon: Icons.text_fields,
//                   onPressed: onEditText,
//                   backgroundColor:
//                       colorScheme.tertiaryContainer.withOpacity(0.7),
//                   iconColor: colorScheme.onTertiaryContainer,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildToolButton(
//     BuildContext context, {
//     required String title,
//     required IconData icon,
//     required VoidCallback onPressed,
//     required Color backgroundColor,
//     required Color iconColor,
//   }) {
//     final colorScheme = Theme.of(context).colorScheme;

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           decoration: BoxDecoration(
//             color: backgroundColor,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.05),
//                 blurRadius: 4,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Material(
//             color: Colors.transparent,
//             child: InkWell(
//               onTap: onPressed,
//               borderRadius: BorderRadius.circular(16),
//               child: Container(
//                 padding: const EdgeInsets.all(16),
//                 child: Icon(
//                   icon,
//                   size: 24,
//                   color: iconColor,
//                 ),
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           title.split(' ').last,
//           style: GoogleFonts.notoSerif(
//             fontSize: 11,
//             fontWeight: FontWeight.w500,
//             color: colorScheme.onSurface,
//           ),
//         ),
//       ],
//     );
//   }
// }
