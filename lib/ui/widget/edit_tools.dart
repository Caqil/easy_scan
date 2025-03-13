// import 'package:flutter/material.dart';
// import '../../models/scan_settings.dart';

// class EditTools extends StatelessWidget {
//   final Function(ColorMode) onColorModeChanged;
//   final VoidCallback onFilter;
//   final ColorMode currentColorMode;

//   const EditTools({
//     super.key,
//     required this.onColorModeChanged,
//     required this.onFilter,
//     required this.currentColorMode,
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
//               style: TextStyle(
//                 fontSize: 12,
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
//                 _buildToolButton(
//                   context,
//                   title: 'Filter',
//                   icon: Icons.auto_fix_high_rounded,
//                   onPressed: onFilter,
//                   backgroundColor:
//                       colorScheme.tertiaryContainer.withOpacity(0.7),
//                   iconColor: colorScheme.onTertiaryContainer,
//                 ),
//                 const SizedBox(width: 12),
//                 _buildToolButton(
//                   context,
//                   title: 'Text OCR',
//                   icon: Icons.text_fields_rounded,
//                   onPressed: () {},
//                   backgroundColor: colorScheme.surfaceVariant,
//                   iconColor: colorScheme.onSurfaceVariant,
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
//           style: TextStyle(
//             fontSize: 11,
//             fontWeight: FontWeight.w500,
//             color: colorScheme.onSurface,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildColorModeButton(
//     BuildContext context, {
//     required String title,
//     required IconData icon,
//     required ColorMode mode,
//   }) {
//     final isSelected = currentColorMode == mode;
//     final colorScheme = Theme.of(context).colorScheme;

//     return Tooltip(
//       message: title,
//       child: GestureDetector(
//         onTap: () => onColorModeChanged(mode),
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           decoration: BoxDecoration(
//             color: isSelected ? colorScheme.primary : colorScheme.surface,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: isSelected
//                   ? colorScheme.primary
//                   : colorScheme.outline.withOpacity(0.3),
//               width: 1.5,
//             ),
//             boxShadow: isSelected
//                 ? [
//                     BoxShadow(
//                       color: colorScheme.primary.withOpacity(0.3),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ]
//                 : null,
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 icon,
//                 size: 18,
//                 color:
//                     isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: isSelected
//                       ? colorScheme.onPrimary
//                       : colorScheme.onSurface,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
