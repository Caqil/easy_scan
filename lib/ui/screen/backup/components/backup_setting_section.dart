// import 'dart:io';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:scanpro/models/backup_settings.dart';
// import 'package:scanpro/providers/backup_provider.dart';
// import 'package:scanpro/services/backup_service.dart';
// import 'package:scanpro/services/storage_service.dart';
// import 'package:scanpro/ui/common/dialogs.dart';
// import 'package:scanpro/ui/screen/backup/backup_restore_screnn.dart';
// import 'package:scanpro/ui/screen/backup/cloud_backup_screen.dart';
// import 'package:scanpro/ui/screen/backup/components/backup_dialogs.dart';

// class BackupSettingsSection extends ConsumerStatefulWidget {
//   const BackupSettingsSection({Key? key}) : super(key: key);

//   @override
//   ConsumerState<BackupSettingsSection> createState() =>
//       _BackupSettingsSectionState();
// }

// class _BackupSettingsSectionState extends ConsumerState<BackupSettingsSection> {
//   bool _isLoading = true;
//   BackupSettings? _backupSettings;
//   bool _isAutoBackupEnabled = false;
//   String _autoBackupFrequency = 'weekly';
//   BackupDestination _autoBackupDestination = BackupDestination.local;
//   int _maxBackupCount = 5;

//   @override
//   void initState() {
//     super.initState();
//     _loadBackupSettings();
//   }

//   Future<void> _loadBackupSettings() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final storageService = StorageService();
//       final settings = await storageService.getBackupSettings();

//       setState(() {
//         _backupSettings = settings;
//         _isAutoBackupEnabled = settings.autoBackupEnabled;
//         _autoBackupFrequency = settings.frequency;
//         _autoBackupDestination = settings.backupDestination;
//         _maxBackupCount = settings.maxLocalBackups;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _saveBackupSettings() async {
//     try {
//       if (_backupSettings == null) return;

//       final updatedSettings = BackupSettings(
//         autoBackupEnabled: _isAutoBackupEnabled,
//         frequency: _autoBackupFrequency,
//         backupDestination: _autoBackupDestination,
//         maxLocalBackups: _maxBackupCount,
//         lastBackupDate: _backupSettings!.lastBackupDate,
//       );

//       final storageService = StorageService();
//       await storageService.saveBackupSettings(updatedSettings);

//       if (mounted) {
//         AppDialogs.showSnackBar(
//           context,
//           message: 'backup.settings_saved'.tr(),
//           type: SnackBarType.success,
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         AppDialogs.showSnackBar(
//           context,
//           message: 'backup.settings_save_error'
//               .tr(namedArgs: {'error': e.toString()}),
//           type: SnackBarType.error,
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final backupState = ref.watch(backupProvider);
//     final lastBackupDate =
//         backupState.lastBackupDate ?? _backupSettings?.lastBackupDate;

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Section header
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           child: Text(
//             'backup.title'.tr(),
//             style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,

//               fontSize: 16.sp,
//               fontWeight: FontWeight.bold,
//               color: Theme.of(context).primaryColor,
//             ),
//           ),
//         ),

//         // Last backup info
//         Card(
//           margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//           elevation: 1,
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.history,
//                       color: Theme.of(context).primaryColor,
//                       size: 20,
//                     ),
//                     const SizedBox(width: 12),
//                     Text(
//                       'backup.last_backup'.tr(),
//                       style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,

//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Padding(
//                   padding: const EdgeInsets.only(left: 32),
//                   child: Text(
//                     lastBackupDate != null
//                         ? DateFormat('MMM dd, yyyy HH:mm')
//                             .format(lastBackupDate)
//                         : 'backup.never'.tr(),
//                     style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,

//                       color: Colors.grey.shade700,
//                     ),
//                   ),
//                 ),
//                 if (lastBackupDate != null) ...[
//                   const SizedBox(height: 4),
//                   Padding(
//                     padding: const EdgeInsets.only(left: 32),
//                     child: Text(
//                       _getRelativeTime(lastBackupDate),
//                       style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,

//                         color: _getTimeColor(lastBackupDate, context),
//                         fontStyle: FontStyle.italic,
//                         fontSize: 12.sp,
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),

//         // Quick backup button
//         _buildSettingsItem(
//           context: context,
//           title: 'backup.quick_backup'.tr(),
//           subtitle: 'backup.create_new_backup'.tr(),
//           iconData: Icons.backup,
//           onTap: () {
//             BackupDialogs.showQuickBackupBottomSheet(context, ref);
//           },
//         ),

//         // Backup & Restore
//         _buildSettingsItem(
//           context: context,
//           title: 'backup.backup_restore'.tr(),
//           subtitle: 'backup.manage_backups'.tr(),
//           iconData: Icons.settings_backup_restore,
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => const BackupRestoreScreen(),
//               ),
//             );
//           },
//         ),

//         if (Platform.isAndroid || Platform.isIOS)
//           _buildSettingsItem(
//             context: context,
//             title: 'Google Drive ${'backup.backup'.tr()}',
//             subtitle: 'backup.gdrive_description'.tr(),
//             iconData: Icons.drive_folder_upload,
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const CloudBackupScreen(
//                     backupDestination: BackupDestination.googleDrive,
//                   ),
//                 ),
//               );
//             },
//           ),

//         // Auto backup settings
//         _buildSettingsItem(
//           context: context,
//           title: 'backup.auto_backup'.tr(),
//           subtitle: _isAutoBackupEnabled
//               ? 'backup.auto_backup_enabled_desc'
//                   .tr(namedArgs: {'frequency': _getFrequencyText()})
//               : 'backup.auto_backup_disabled'.tr(),
//           iconData: Icons.schedule,
//           onTap: () {
//             _showAutoBackupSettingsDialog();
//           },
//         ),

//         const SizedBox(height: 8),
//       ],
//     );
//   }

//   String _getFrequencyText() {
//     switch (_autoBackupFrequency) {
//       case 'daily':
//         return 'backup.daily'.tr();
//       case 'weekly':
//         return 'backup.weekly'.tr();
//       case 'monthly':
//         return 'backup.monthly'.tr();
//       default:
//         return _autoBackupFrequency;
//     }
//   }

//   Widget _buildSettingsItem({
//     required BuildContext context,
//     required String title,
//     required String subtitle,
//     required IconData iconData,
//     required VoidCallback onTap,
//   }) {
//     return ListTile(
//       leading: Container(
//         padding: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: Theme.of(context).primaryColor.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Icon(
//           iconData,
//           color: Theme.of(context).primaryColor,
//         ),
//       ),
//       title: Text(
//         title,
//         style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,

//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       subtitle: Text(
//         subtitle,
//         style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,

//           fontSize: 12.sp,
//           color: Colors.grey.shade600,
//         ),
//       ),
//       trailing: const Icon(Icons.chevron_right),
//       onTap: onTap,
//     );
//   }

//   String _getRelativeTime(DateTime date) {
//     final now = DateTime.now();
//     final difference = now.difference(date);

//     if (difference.inDays > 30) {
//       return 'backup.backup_old'.tr();
//     } else if (difference.inDays > 7) {
//       return 'backup.backup_week_old'.tr();
//     } else if (difference.inDays > 0) {
//       return 'backup.backup_days'
//           .tr(namedArgs: {'days': difference.inDays.toString()});
//     } else if (difference.inHours > 0) {
//       return 'backup.backup_hours'
//           .tr(namedArgs: {'hours': difference.inHours.toString()});
//     } else {
//       return 'backup.backup_recent'.tr();
//     }
//   }

//   Color _getTimeColor(DateTime date, BuildContext context) {
//     final now = DateTime.now();
//     final difference = now.difference(date);

//     if (difference.inDays > 30) {
//       return Colors.red.shade700;
//     } else if (difference.inDays > 7) {
//       return Colors.orange.shade700;
//     } else {
//       return Colors.green.shade700;
//     }
//   }

//   void _showAutoBackupSettingsDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) => AlertDialog(
//           title: Text('backup.auto_backup_settings'.tr()),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 SwitchListTile(
//                   title: Text(
//                     'backup.enable_auto_backup'.tr(),
//                     style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,
//),
//                   ),
//                   value: _isAutoBackupEnabled,
//                   onChanged: (value) {
//                     setState(() {
//                       _isAutoBackupEnabled = value;
//                     });
//                   },
//                   activeColor: Theme.of(context).primaryColor,
//                 ),
//                 const Divider(),
//                 if (_isAutoBackupEnabled) ...[
//                   Text(
//                     'backup.backup_frequency'.tr(),
//                     style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,

//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   RadioListTile<String>(
//                     title: Text('backup.daily'.tr()),
//                     value: 'daily',
//                     groupValue: _autoBackupFrequency,
//                     onChanged: (value) {
//                       setState(() {
//                         _autoBackupFrequency = value!;
//                       });
//                     },
//                     activeColor: Theme.of(context).primaryColor,
//                   ),
//                   RadioListTile<String>(
//                     title: Text('backup.weekly'.tr()),
//                     value: 'weekly',
//                     groupValue: _autoBackupFrequency,
//                     onChanged: (value) {
//                       setState(() {
//                         _autoBackupFrequency = value!;
//                       });
//                     },
//                     activeColor: Theme.of(context).primaryColor,
//                   ),
//                   RadioListTile<String>(
//                     title: Text('backup.monthly'.tr()),
//                     value: 'monthly',
//                     groupValue: _autoBackupFrequency,
//                     onChanged: (value) {
//                       setState(() {
//                         _autoBackupFrequency = value!;
//                       });
//                     },
//                     activeColor: Theme.of(context).primaryColor,
//                   ),
//                   const Divider(),
//                   Text(
//                     'backup.destination'.tr(),
//                     style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,

//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   _buildDestinationOptions(setState),
//                   const Divider(),
//                   Text(
//                     'backup.max_backups'.tr(),
//                     style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,

//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Slider(
//                     value: _maxBackupCount.toDouble(),
//                     min: 1,
//                     max: 10,
//                     divisions: 9,
//                     label: _maxBackupCount.toString(),
//                     onChanged: (value) {
//                       setState(() {
//                         _maxBackupCount = value.toInt();
//                       });
//                     },
//                   ),
//                   Center(
//                     child: Text(
//                       'backup.max_backups_count'.tr(
//                         namedArgs: {'count': _maxBackupCount.toString()},
//                       ),
//                       style: GoogleFonts.slabo27px( fontWeight: FontWeight.w700,

//                         fontSize: 12.sp,
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: Text('common.cancel'.tr()),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 _saveBackupSettings();
//               },
//               child: Text('common.save'.tr()),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDestinationOptions(StateSetter setState) {
//     final isIOS = Platform.isIOS;
//     final isAndroid = Platform.isAndroid;

//     return Column(
//       children: [
//         if (isAndroid || isIOS)
//           RadioListTile<BackupDestination>(
//             title: const Text('Google Drive'),
//             value: BackupDestination.googleDrive,
//             groupValue: _autoBackupDestination,
//             onChanged: (value) {
//               setState(() {
//                 _autoBackupDestination = value!;
//               });
//             },
//             activeColor: Theme.of(context).primaryColor,
//           ),
//         RadioListTile<BackupDestination>(
//           title: Text('backup.local_storage'.tr()),
//           value: BackupDestination.local,
//           groupValue: _autoBackupDestination,
//           onChanged: (value) {
//             setState(() {
//               _autoBackupDestination = value!;
//             });
//           },
//           activeColor: Theme.of(context).primaryColor,
//         ),
//       ],
//     );
//   }
// }
