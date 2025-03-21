// import 'package:flutter/material.dart';
// import 'package:auto_size_text/auto_size_text.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:scanpro/config/helper.dart';
// import 'package:scanpro/services/pdf_compression_api_service.dart';
// import 'package:scanpro/utils/compress_limit_utils.dart';
// import 'package:scanpro/services/compression_service.dart';
// import 'package:scanpro/ui/screen/premium/premium_screen.dart';

// /// Provider to track selected compression level
// final selectedCompressionLevelProvider = StateProvider<CompressionLevel>((ref) {
//   return CompressionLevel.low; // Default to low compression
// });

// /// A widget to select compression levels with premium indicators
// class CompressionLevelSelector extends ConsumerWidget {
//   final Function(CompressionLevel)? onLevelSelected;

//   const CompressionLevelSelector({
//     super.key,
//     this.onLevelSelected,
//   });

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final selectedLevel = ref.watch(selectedCompressionLevelProvider);
//     final compressionService = ref.watch(compressionServiceProvider);

//     return FutureBuilder<List<Map<String, dynamic>>>(
//       future: CompressionLimitUtils.getCompressionLevelOptions(ref),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         }

//         if (!snapshot.hasData || snapshot.data!.isEmpty) {
//           return Center(
//             child: Text('compression.error_loading_options'.tr()),
//           );
//         }

//         final options = snapshot.data!;

//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//               child: Text(
//                 'compression.select_level'.tr(),
//                 style: GoogleFonts.slabo27px(
//                   fontSize: 18.sp,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             ListView.builder(
//               shrinkWrap: true,
//               physics: NeverScrollableScrollPhysics(),
//               itemCount: options.length,
//               itemBuilder: (context, index) {
//                 final option = options[index];
//                 final level = option['level'] as CompressionLevel;
//                 final levelName = CompressionLevelMapper.getName(level).tr();
//                 final isAvailable = option['isAvailable'] as bool;
//                 final isPremium = option['isPremium'] as bool;

//                 return _buildLevelOption(
//                   context,
//                   ref,
//                   level: level,
//                   name: levelName,
//                   isSelected: selectedLevel == level,
//                   isAvailable: isAvailable,
//                   isPremium: isPremium,
//                   estimatedReduction:
//                       compressionService.getFileSizeReductionEstimate(level),
//                 );
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildLevelOption(
//     BuildContext context,
//     WidgetRef ref, {
//     required CompressionLevel level,
//     required String name,
//     required bool isSelected,
//     required bool isAvailable,
//     required bool isPremium,
//     required String estimatedReduction,
//   }) {
//     return InkWell(
//       onTap: () async {
//         if (isAvailable) {
//           // If level is available, select it
//           ref.read(selectedCompressionLevelProvider.notifier).state = level;
//           if (onLevelSelected != null) {
//             onLevelSelected!(level);
//           }
//         } else {
//           // If level is not available, show premium dialog
//           await CompressionLimitUtils.showPremiumCompressionDialog(
//               context, level);
//         }
//       },
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
//         margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? Theme.of(context).primaryColor.withOpacity(0.1)
//               : Theme.of(context).cardColor,
//           borderRadius: BorderRadius.circular(12.r),
//           border: Border.all(
//             color: isSelected
//                 ? Theme.of(context).primaryColor
//                 : Theme.of(context).dividerColor,
//             width: isSelected ? 2 : 1,
//           ),
//         ),
//         child: Row(
//           children: [
//             // Radio button
//             Container(
//               width: 24.w,
//               height: 24.w,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: isSelected
//                     ? Theme.of(context).primaryColor
//                     : Colors.transparent,
//                 border: Border.all(
//                   color: isSelected
//                       ? Theme.of(context).primaryColor
//                       : Theme.of(context).dividerColor,
//                   width: 2,
//                 ),
//               ),
//               child: isSelected
//                   ? Icon(
//                       Icons.check,
//                       size: 16.r,
//                       color: Colors.white,
//                     )
//                   : null,
//             ),
//             SizedBox(width: 16.w),

//             // Level info
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       AutoSizeText(
//                         name,
//                         style: GoogleFonts.slabo27px(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16.sp,
//                           color: isAvailable
//                               ? Theme.of(context).textTheme.titleMedium?.color
//                               : Theme.of(context).disabledColor,
//                         ),
//                       ),
//                       SizedBox(width: 8.w),
//                       if (isPremium)
//                         Container(
//                           padding: EdgeInsets.symmetric(
//                               horizontal: 8.w, vertical: 2.h),
//                           decoration: BoxDecoration(
//                             color: Colors.amber.withOpacity(0.2),
//                             borderRadius: BorderRadius.circular(12.r),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(
//                                 Icons.star,
//                                 size: 12.r,
//                                 color: Colors.amber,
//                               ),
//                               SizedBox(width: 4.w),
//                               AutoSizeText(
//                                 'compression.premium'.tr(),
//                                 style: GoogleFonts.slabo27px(
//                                   fontSize: 10.sp,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.amber,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                     ],
//                   ),
//                   SizedBox(height: 4.h),
//                   AutoSizeText(
//                     'compression.estimated_reduction'.tr(
//                       namedArgs: {'percentage': estimatedReduction},
//                     ),
//                     style: GoogleFonts.slabo27px(
//                       fontSize: 12.sp,
//                       color: isAvailable
//                           ? Theme.of(context).textTheme.bodySmall?.color
//                           : Theme.of(context).disabledColor,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // Lock icon for premium levels
//             if (!isAvailable)
//               IconButton(
//                 icon: Icon(
//                   Icons.lock_outline,
//                   color: Theme.of(context).primaryColor,
//                 ),
//                 onPressed: () {
//                   Navigator.of(context).push(
//                     MaterialPageRoute(builder: (_) => const PremiumScreen()),
//                   );
//                 },
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
