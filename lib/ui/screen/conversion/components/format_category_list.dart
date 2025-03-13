// // Format category list
// import 'package:flutter/material.dart';

// import '../../../../models/format_category.dart';

// class FormatCategoryList extends StatelessWidget {
//   final List<FormatCategory> categories;
//   final Function(FormatOption) onFormatSelected;

//   const FormatCategoryList({
//     super.key,
//     required this.categories,
//     required this.onFormatSelected,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       itemCount: categories.length,
//       itemBuilder: (context, index) {
//         final category = categories[index];

//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding:
//                   const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
//               child: Row(
//                 children: [
//                   Icon(category.icon),
//                   const SizedBox(width: 8),
//                   Text(
//                     category.name,
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             GridView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 childAspectRatio: 1.5,
//                 crossAxisSpacing: 10,
//                 mainAxisSpacing: 10,
//               ),
//               itemCount: category.formats.length,
//               itemBuilder: (context, formatIndex) {
//                 final format = category.formats[formatIndex];

//                 return InkWell(
//                   onTap: () => onFormatSelected(format),
//                   child: Card(
//                     elevation: 2,
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           format.icon,
//                           size: 40,
//                           color: format.color,
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           format.label,
//                           textAlign: TextAlign.center,
//                           style: const TextStyle(fontWeight: FontWeight.w500),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//             const SizedBox(height: 8),
//           ],
//         );
//       },
//     );
//   }
// }
