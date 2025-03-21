// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:scanpro/providers/backup_provider.dart';
// import 'package:scanpro/services/backup_service.dart';
// import 'package:scanpro/ui/common/app_bar.dart';
// import 'package:scanpro/ui/common/dialogs.dart';

// class CloudBackupScreen extends ConsumerStatefulWidget {
//   final BackupDestination backupDestination;

//   const CloudBackupScreen({
//     Key? key,
//     required this.backupDestination,
//   }) : super(key: key);

//   @override
//   ConsumerState<CloudBackupScreen> createState() => _CloudBackupScreenState();
// }

// class _CloudBackupScreenState extends ConsumerState<CloudBackupScreen> {
//   bool _isLoading = true;
//   bool _isPerformingAction = false;
//   String? _errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     _loadBackups();
//   }

//   Future<void> _loadBackups() async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _errorMessage = null;
//       });

//       await ref
//           .read(backupProvider.notifier)
//           .loadAvailableBackups(widget.backupDestination);

//       setState(() {
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//         _errorMessage = e.toString();
//       });
//     }
//   }

//   String? _getCloudServiceName() {
//     switch (widget.backupDestination) {
//       case BackupDestination.googleDrive:
//         return 'Google Drive';
//       case BackupDestination.local:
//         return 'backup.local_storage'.tr();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final backupState = ref.watch(backupProvider);
//     final cloudName = _getCloudServiceName();

//     return Scaffold(
//       appBar: CustomAppBar(
//         title: AutoSizeText('$cloudName ${'backup.backups'.tr()}'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _isLoading || _isPerformingAction ? null : _loadBackups,
//             tooltip: 'backup.refresh'.tr(),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Error message
//           if (_errorMessage != null)
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(8),
//               color: Colors.red.shade100,
//               child: Row(
//                 children: [
//                   Icon(Icons.error_outline,
//                       color: Colors.red.shade800, size: 20),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: AutoSizeText(
//                       _errorMessage!,
//                       style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,

//                           color: Colors.red.shade800, fontSize: 12.sp),
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.close, size: 20),
//                     onPressed: () {
//                       setState(() {
//                         _errorMessage = null;
//                       });
//                     },
//                     color: Colors.red.shade800,
//                   ),
//                 ],
//               ),
//             ),

//           // Progress Indicator
//           if (backupState.isCreatingBackup ||
//               backupState.isRestoringBackup ||
//               _isPerformingAction)
//             LinearProgressIndicator(
//               value:
//                   backupState.isCreatingBackup || backupState.isRestoringBackup
//                       ? backupState.progress
//                       : null,
//             ),

//           // Content
//           Expanded(
//             child: _isLoading
//                 ? _buildLoadingView()
//                 : backupState.availableBackups.isEmpty
//                     ? _buildEmptyView(cloudName!)
//                     : _buildBackupsList(
//                         backupState.availableBackups, cloudName!),
//           ),
//         ],
//       ),
//       bottomNavigationBar: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: ElevatedButton.icon(
//             onPressed: _isLoading || _isPerformingAction ? null : _createBackup,
//             icon: const Icon(Icons.backup),
//             label: AutoSizeText('backup.create_new_backup'.tr()),
//             style: ElevatedButton.styleFrom(
//               minimumSize: const Size(double.infinity, 50),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLoadingView() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const CircularProgressIndicator(),
//           const SizedBox(height: 16),
//           AutoSizeText(
//             'backup.loading_backups'.tr(),
//             style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,
//),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmptyView(String cloudName) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             _getCloudIcon(),
//             size: 64,
//             color: Colors.grey.shade400,
//           ),
//           const SizedBox(height: 16),
//           AutoSizeText(
//             'backup.no_backups_found_in'.tr(namedArgs: {'cloud': cloudName}),
//             style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,

//               fontSize: 16.sp,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey.shade700,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 32),
//             child: AutoSizeText(
//               'backup.create_first_backup_description'.tr(),
//               style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,

//                 color: Colors.grey.shade600,
//                 fontSize: 14.sp,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBackupsList(
//       List<Map<String, dynamic>> backups, String cloudName) {
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: backups.length + 1, // +1 for the header
//       itemBuilder: (context, index) {
//         if (index == 0) {
//           return _buildHeader(cloudName);
//         }

//         final backup = backups[index - 1];
//         return _buildBackupItem(backup);
//       },
//     );
//   }

//   Widget _buildHeader(String cloudName) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(
//               _getCloudIcon(),
//               color: Theme.of(context).primaryColor,
//               size: 24,
//             ),
//             const SizedBox(width: 12),
//             AutoSizeText(
//               '$cloudName ${'backup.backups'.tr()}',
//               style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,

//                 fontSize: 16.sp,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         AutoSizeText(
//           'backup.available_backups'.tr(),
//           style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,

//             color: Colors.grey.shade600,
//             fontSize: 14.sp,
//           ),
//         ),
//         const Divider(height: 24),
//       ],
//     );
//   }

//   Widget _buildBackupItem(Map<String, dynamic> backup) {
//     final String name = backup['name'] ?? 'Unknown';
//     final String date = backup['date'] ?? 'Unknown';
//     final String size = backup['size'] ?? 'Unknown';

//     return Card(
//       elevation: 1,
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(
//                   Icons.backup,
//                   color: Theme.of(context).primaryColor,
//                   size: 24,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: AutoSizeText(
//                     name,
//                     style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,

//                       fontWeight: FontWeight.bold,
//                       fontSize: 14.sp,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Icon(
//                   Icons.access_time,
//                   color: Colors.grey.shade600,
//                   size: 16,
//                 ),
//                 const SizedBox(width: 8),
//                 AutoSizeText(
//                   date,
//                   style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,

//                     color: Colors.grey.shade600,
//                     fontSize: 12.sp,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Icon(
//                   Icons.storage,
//                   color: Colors.grey.shade600,
//                   size: 16,
//                 ),
//                 const SizedBox(width: 8),
//                 AutoSizeText(
//                   size,
//                   style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,

//                     color: Colors.grey.shade600,
//                     fontSize: 12.sp,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 TextButton.icon(
//                   onPressed: () => _confirmDeleteBackup(backup),
//                   icon: const Icon(Icons.delete, size: 18),
//                   label: AutoSizeText('common.delete'.tr()),
//                   style: TextButton.styleFrom(
//                     foregroundColor: Colors.red,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton.icon(
//                   onPressed: () => _confirmRestoreBackup(backup),
//                   icon: const Icon(Icons.restore, size: 18),
//                   label: AutoSizeText('backup.restore'.tr()),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Theme.of(context).primaryColor,
//                     foregroundColor: Colors.white,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   IconData? _getCloudIcon() {
//     switch (widget.backupDestination) {
//       case BackupDestination.googleDrive:
//         return Icons.drive_folder_upload;
//       case BackupDestination.local:
//         return Icons.smartphone;
//     }
//   }

//   Future<void> _createBackup() async {
//     try {
//       setState(() {
//         _isPerformingAction = true;
//       });

//       final backupService = ref.read(backupServiceProvider);

//       final result = await backupService.createBackup(
//         destination: widget.backupDestination,
//         context: context,
//         onProgress: (progress) {
//           // Update progress in UI if needed
//         },
//       );

//       if (mounted) {
//         setState(() {
//           _isPerformingAction = false;
//         });

//         // Show success message
//         AppDialogs.showSnackBar(
//           context,
//           message: result,
//           type: SnackBarType.success,
//         );

//         // Refresh the list
//         _loadBackups();
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isPerformingAction = false;
//           _errorMessage = e.toString();
//         });
//       }
//     }
//   }

//   Future<void> _confirmDeleteBackup(Map<String, dynamic> backup) async {
//     final confirmed = await AppDialogs.showConfirmDialog(
//       context,
//       title: 'backup.confirm_delete'.tr(),
//       message: 'backup.confirm_delete_message'.tr(),
//       confirmText: 'common.delete'.tr(),
//       cancelText: 'common.cancel'.tr(),
//       isDangerous: true,
//     );

//     if (confirmed && mounted) {
//       _deleteBackup(backup);
//     }
//   }

//   Future<void> _deleteBackup(Map<String, dynamic> backup) async {
//     // In a real implementation, you'd call a method to delete the backup
//     // For now, we'll just show a placeholder message

//     setState(() {
//       _isPerformingAction = true;
//     });

//     await Future.delayed(const Duration(seconds: 1)); // Simulate deletion

//     AppDialogs.showSnackBar(
//       context,
//       message: 'backup.backup_deleted'.tr(),
//       type: SnackBarType.success,
//     );

//     setState(() {
//       _isPerformingAction = false;
//     });

//     // Refresh the list
//     _loadBackups();
//   }

//   Future<void> _confirmRestoreBackup(Map<String, dynamic> backup) async {
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
//       _restoreBackup(backup);
//     }
//   }

//   Future<void> _restoreBackup(Map<String, dynamic> backup) async {
//     final backupId = backup['id'];

//     setState(() {
//       _isPerformingAction = true;
//     });

//     try {
//       await ref.read(backupProvider.notifier).restoreBackup(
//             source: widget.backupDestination,
//             context: context,
//             backupId: backupId,
//           );

//       if (mounted) {
//         AppDialogs.showSnackBar(
//           context,
//           message: 'backup.restore_success'.tr(),
//           type: SnackBarType.success,
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _errorMessage = e.toString();
//         });
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isPerformingAction = false;
//         });
//       }
//     }
//   }
// }
