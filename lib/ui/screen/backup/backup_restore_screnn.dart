// import 'dart:io';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:scanpro/providers/backup_provider.dart';
// import 'package:scanpro/services/backup_service.dart';
// import 'package:scanpro/ui/common/app_bar.dart';
// import 'package:scanpro/ui/common/dialogs.dart';

// class BackupRestoreScreen extends ConsumerStatefulWidget {
//   const BackupRestoreScreen({Key? key}) : super(key: key);

//   @override
//   ConsumerState<BackupRestoreScreen> createState() =>
//       _BackupRestoreScreenState();
// }

// class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   BackupDestination _selectedDestination = BackupDestination.local;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//     _selectedDestination = BackupDestination.local;

//     // Load available backups
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ref
//           .read(backupProvider.notifier)
//           .loadAvailableBackups(_selectedDestination);
//     });
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final backupState = ref.watch(backupProvider);

//     return Scaffold(
//       appBar: CustomAppBar(
//         title: Text(
//           'backup.title'.tr(),
//           style: GoogleFonts.lilitaOne(fontSize: 25.sp),
//         ),
//       ),
//       body: Column(
//         children: [
//           Container(
//             color: Theme.of(context).primaryColor.withOpacity(0.05),
//             child: TabBar(
//               controller: _tabController,
//               labelColor: Theme.of(context).primaryColor,
//               unselectedLabelColor: Colors.grey,
//               indicatorColor: Theme.of(context).primaryColor,
//               tabs: [
//                 Tab(text: 'backup.backup'.tr()),
//                 Tab(text: 'backup.restore'.tr()),
//               ],
//             ),
//           ),
//           if (backupState.errorMessage != null)
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(12),
//               color: Colors.red.shade100,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.error_outline,
//                           color: Colors.red.shade800, size: 20),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           'Error occurred:',
//                           style: GoogleFonts.notoSerif(
//                             color: Colors.red.shade800,
//                             fontSize: 14.sp,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     backupState.errorMessage!,
//                     style: GoogleFonts.notoSerif(
//                       color: Colors.red.shade800,
//                       fontSize: 12.sp,
//                     ),
//                   ),
//                   TextButton(
//                     onPressed: () =>
//                         ref.read(backupProvider.notifier).clearMessages(),
//                     child: Text('Dismiss'),
//                   ),
//                 ],
//               ),
//             ),
//           if (backupState.successMessage != null)
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(12),
//               color: Colors.green.shade100,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.check_circle_outline,
//                           color: Colors.green.shade800, size: 20),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           'Success!',
//                           style: GoogleFonts.notoSerif(
//                             color: Colors.green.shade800,
//                             fontSize: 14.sp,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     backupState.successMessage!,
//                     style: GoogleFonts.notoSerif(
//                       color: Colors.green.shade800,
//                       fontSize: 12.sp,
//                     ),
//                   ),
//                   if (backupState.successMessage?.contains('restored') ?? false)
//                     ElevatedButton.icon(
//                       onPressed: () {
//                         // This will exit the app - the user will need to manually restart
//                         exit(0);
//                       },
//                       icon: Icon(Icons.refresh),
//                       label: Text('Restart App Now'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green.shade700,
//                         foregroundColor: Colors.white,
//                       ),
//                     ),
//                   TextButton(
//                     onPressed: () =>
//                         ref.read(backupProvider.notifier).clearMessages(),
//                     child: Text('Dismiss'),
//                   ),
//                 ],
//               ),
//             ),
//           if (backupState.isCreatingBackup || backupState.isRestoringBackup)
//             _buildProgressIndicator(backupState),
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildBackupTab(backupState),
//                 _buildRestoreTab(backupState),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProgressIndicator(BackupState state) {
//     final isBackup = state.isCreatingBackup;
//     final progress = state.progress;

//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       color: Theme.of(context).cardColor,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           LinearProgressIndicator(
//             value: progress,
//             backgroundColor: Colors.grey.shade200,
//             color: Theme.of(context).primaryColor,
//           ),
//           const SizedBox(height: 8),
//           Text(
//             isBackup ? 'backup.creating_backup'.tr() : 'backup.restoring'.tr(),
//             style: GoogleFonts.notoSerif(
//               color: Theme.of(context).primaryColor,
//               fontSize: 14.sp,
//             ),
//           ),
//           Text(
//             '${(progress * 100).toStringAsFixed(0)}%',
//             style: GoogleFonts.notoSerif(
//               color: Theme.of(context).primaryColor,
//               fontSize: 12.sp,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBackupTab(BackupState state) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildLastBackupInfo(state),
//           const SizedBox(height: 24),
//           Text(
//             'backup.destination'.tr(),
//             style: GoogleFonts.notoSerif(
//               fontSize: 16.sp,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 16),
//           _buildDestinationSelector(),
//           const SizedBox(height: 24),
//           _buildBackupDescription(),
//           const SizedBox(height: 24),
//           ElevatedButton.icon(
//             onPressed: state.isCreatingBackup || state.isRestoringBackup
//                 ? null
//                 : () => _createBackup(),
//             icon: const Icon(Icons.backup),
//             label: Text('backup.backup_now'.tr()),
//             style: ElevatedButton.styleFrom(
//               minimumSize: const Size(double.infinity, 50),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRestoreTab(BackupState state) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'backup.restore'.tr(),
//                 style: GoogleFonts.notoSerif(
//                   fontSize: 16.sp,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 16),
//               _buildDestinationSelector(),
//               const SizedBox(height: 8),
//               OutlinedButton.icon(
//                 onPressed: state.isCreatingBackup || state.isRestoringBackup
//                     ? null
//                     : () => ref
//                         .read(backupProvider.notifier)
//                         .loadAvailableBackups(_selectedDestination),
//                 icon: const Icon(Icons.refresh),
//                 label: Text('backup.refresh'.tr()),
//                 style: OutlinedButton.styleFrom(
//                   minimumSize: const Size(double.infinity, 40),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const Divider(height: 1),
//         Expanded(
//           child: state.availableBackups.isEmpty
//               ? _buildEmptyBackupsList()
//               : _buildBackupsList(state.availableBackups),
//         ),
//       ],
//     );
//   }

//   Widget _buildLastBackupInfo(BackupState state) {
//     final lastBackupDate = state.lastBackupDate;

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey.shade300),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Theme.of(context).primaryColor.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               Icons.history,
//               color: Theme.of(context).primaryColor,
//               size: 24,
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'backup.last_backup'.tr(),
//                   style: GoogleFonts.notoSerif(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 14.sp,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   lastBackupDate != null
//                       ? DateFormat('MMM dd, yyyy HH:mm').format(lastBackupDate)
//                       : 'backup.never'.tr(),
//                   style: GoogleFonts.notoSerif(
//                     color: Colors.grey.shade700,
//                     fontSize: 12.sp,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDestinationSelector() {
//     final isIOS = Platform.isIOS;
//     final isAndroid = Platform.isAndroid;

//     return Column(
//       children: [
//         if (isAndroid || isIOS)
//           _buildDestinationOption(
//             icon: Icons.drive_folder_upload,
//             title: 'Google Drive',
//             subtitle: 'backup.gdrive_description'.tr(),
//             destination: BackupDestination.googleDrive,
//           ),
//         _buildDestinationOption(
//           icon: Icons.smartphone,
//           title: 'backup.local_storage'.tr(),
//           subtitle: 'backup.local_storage_description'.tr(),
//           destination: BackupDestination.local,
//         ),
//       ],
//     );
//   }

//   Widget _buildDestinationOption({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required BackupDestination destination,
//   }) {
//     final isSelected = _selectedDestination == destination;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         border: Border.all(
//           color: isSelected
//               ? Theme.of(context).primaryColor
//               : Colors.grey.shade300,
//           width: isSelected ? 2 : 1,
//         ),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: InkWell(
//         onTap: () {
//           setState(() {
//             _selectedDestination = destination;
//           });
//           ref.read(backupProvider.notifier).loadAvailableBackups(destination);
//         },
//         borderRadius: BorderRadius.circular(10),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: isSelected
//                       ? Theme.of(context).primaryColor.withOpacity(0.1)
//                       : Colors.grey.shade100,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(
//                   icon,
//                   color: isSelected
//                       ? Theme.of(context).primaryColor
//                       : Colors.grey.shade600,
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: GoogleFonts.notoSerif(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14.sp,
//                         color:
//                             isSelected ? Theme.of(context).primaryColor : null,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       subtitle,
//                       style: GoogleFonts.notoSerif(
//                         color: Colors.grey.shade600,
//                         fontSize: 12.sp,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Radio<BackupDestination>(
//                 value: destination,
//                 groupValue: _selectedDestination,
//                 onChanged: (value) {
//                   if (value != null) {
//                     setState(() {
//                       _selectedDestination = value;
//                     });
//                     ref
//                         .read(backupProvider.notifier)
//                         .loadAvailableBackups(value);
//                   }
//                 },
//                 activeColor: Theme.of(context).primaryColor,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBackupDescription() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.blue.shade50,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.blue.shade200),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
//               const SizedBox(width: 8),
//               Text(
//                 'backup.what_is_included'.tr(),
//                 style: GoogleFonts.notoSerif(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue.shade700,
//                   fontSize: 14.sp,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'backup.included_items'.tr(),
//             style: GoogleFonts.notoSerif(
//               color: Colors.blue.shade800,
//               fontSize: 12.sp,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'backup.warning'.tr(),
//             style: GoogleFonts.notoSerif(
//               color: Colors.red.shade800,
//               fontSize: 12.sp,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyBackupsList() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.backup_outlined,
//             size: 64,
//             color: Colors.grey.shade400,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'backup.no_backups_found'.tr(),
//             style: GoogleFonts.notoSerif(
//               fontSize: 16.sp,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey.shade700,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'backup.create_first_backup'.tr(),
//             style: GoogleFonts.notoSerif(
//               color: Colors.grey.shade600,
//               fontSize: 14.sp,
//             ),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 24),
//           OutlinedButton.icon(
//             onPressed: () {
//               _tabController.animateTo(0); // Switch to backup tab
//             },
//             icon: const Icon(Icons.add),
//             label: Text('backup.backup_now'.tr()),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBackupsList(List<Map<String, dynamic>> backups) {
//     return ListView.builder(
//       itemCount: backups.length,
//       itemBuilder: (context, index) {
//         final backup = backups[index];

//         return ListTile(
//           leading: Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: Theme.of(context).primaryColor.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               Icons.backup,
//               color: Theme.of(context).primaryColor,
//             ),
//           ),
//           title: Text(
//             backup['name'] ?? 'Unknown',
//             style: GoogleFonts.notoSerif(
//               fontWeight: FontWeight.bold,
//               fontSize: 14.sp,
//             ),
//           ),
//           subtitle: Text(
//             '${backup['date'] ?? 'Unknown'} • ${backup['size'] ?? 'Unknown'}',
//             style: GoogleFonts.notoSerif(
//               fontSize: 12.sp,
//               color: Colors.grey.shade600,
//             ),
//           ),
//           trailing: IconButton(
//             icon: const Icon(Icons.restore),
//             tooltip: 'backup.restore'.tr(),
//             onPressed: () => _confirmRestore(backup),
//           ),
//           onTap: () => _confirmRestore(backup),
//         );
//       },
//     );
//   }

//   void _createBackup() async {
//     // Check if the selected destination is supported
//     if (!ref
//         .read(backupProvider.notifier)
//         .isPlatformSupported(_selectedDestination)) {
//       AppDialogs.showSnackBar(
//         context,
//         message: 'backup.platform_not_supported'.tr(),
//         type: SnackBarType.error,
//       );
//       return;
//     }

//     // Confirm backup
//     final confirmed = await AppDialogs.showConfirmDialog(
//       context,
//       title: 'backup.confirm_backup'.tr(),
//       message: 'backup.confirm_backup_message'.tr(),
//       confirmText: 'backup.backup'.tr(),
//       cancelText: 'common.cancel'.tr(),
//     );

//     if (confirmed && mounted) {
//       ref.read(backupProvider.notifier).createBackup(
//             destination: _selectedDestination,
//             context: context,
//           );
//     }
//   }

//   void _confirmRestore(Map<String, dynamic> backup) async {
//     final backupId = backup['id'];
//     if (backupId == null) {
//       AppDialogs.showSnackBar(
//         context,
//         message: 'backup.invalid_backup'.tr(),
//         type: SnackBarType.error,
//       );
//       return;
//     }

//     // Confirm restore
//     final confirmed = await AppDialogs.showConfirmDialog(
//       context,
//       title: 'backup.confirm_restore'.tr(),
//       message: 'backup.confirm_restore_message'.tr(),
//       confirmText: 'backup.restore'.tr(),
//       cancelText: 'common.cancel'.tr(),
//       isDangerous: true,
//     );

//     if (confirmed && mounted) {
//       ref.read(backupProvider.notifier).restoreBackup(
//             source: _selectedDestination,
//             context: context,
//             backupId: backupId,
//           );
//     }
//   }
// }
