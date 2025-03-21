import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../common/app_bar.dart';
import '../common/dialogs.dart';

class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ContactSupportScreen> createState() =>
      _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  String _selectedSubject = 'Report a Problem';
  bool _includeDeviceInfo = true;
  bool _isSending = false;

  List<String> _attachmentPaths = [];
  final List<String> _subjectOptions = [
    'Report a Problem',
    'Feature Request',
    'Billing Question',
    'General Inquiry',
    'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryContainer = colorScheme.primaryContainer;

    return Scaffold(
      appBar: CustomAppBar(
        title: Text(
          "support.help_contact".tr(),
          style: GoogleFonts.lilitaOne(
            fontSize: 25.sp,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(7.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel("support.name".tr()),
                      SizedBox(height: 8.h),
                      _buildTextField(
                        controller: _nameController,
                        hintText: "support.your_name".tr(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "support.name_required".tr();
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      _buildFieldLabel("support.email".tr()),
                      SizedBox(height: 8.h),
                      _buildTextField(
                        controller: _emailController,
                        hintText: "support.your_email".tr(),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "support.email_required".tr();
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return "support.valid_email_required".tr();
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      _buildFieldLabel("support.subject".tr()),
                      SizedBox(height: 8.h),
                      _buildDropdown(),
                      SizedBox(height: 16.h),
                      _buildFieldLabel("support.message".tr()),
                      SizedBox(height: 8.h),
                      _buildTextField(
                        controller: _messageController,
                        hintText: "support.write_message".tr(),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "support.message_required".tr();
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel("support.attachments".tr()),
                      SizedBox(height: 12.h),
                      _buildAttachmentSection(),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: _buildDiagnosticToggle(),
                ),
              ),
              SizedBox(height: 24.h),
              _buildSendButton(),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.slabo27px(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType ?? TextInputType.text,
      style: GoogleFonts.slabo27px(),
      decoration: InputDecoration(
        hintText: hintText,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        errorStyle: GoogleFonts.slabo27px(
          color: Colors.redAccent,
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            value: _selectedSubject,
            isExpanded: true,
            style: GoogleFonts.slabo27px(),
            items: _subjectOptions.map((String subject) {
              return DropdownMenuItem<String>(
                value: subject,
                child: Text(subject),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedSubject = newValue;
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "support.max_attachments".tr(args: ["3"]),
          style: GoogleFonts.slabo27px(
            fontSize: 12.sp,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 12.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ..._buildAttachmentThumbnails(),
              if (_attachmentPaths.length < 3) _buildAddAttachmentButton(),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAttachmentThumbnails() {
    return _attachmentPaths.map((path) {
      return Container(
        width: 100.w,
        height: 100.w,
        margin: EdgeInsets.only(right: 12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.file(
                File(path),
                width: 100.w,
                height: 100.w,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 4.r,
              right: 4.r,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _attachmentPaths.remove(path);
                  });
                },
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 16.r,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildAddAttachmentButton() {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: _pickImage,
      child: Container(
        width: 100.w,
        height: 100.w,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 32.r,
              color: colorScheme.primary,
            ),
            SizedBox(height: 8.h),
            Text(
              "support.add_image".tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.slabo27px(
                fontSize: 12.sp,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticToggle() {
    return Row(
      children: [
        Expanded(
          child: Text(
            "support.include_diagnostic".tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 14.sp,
            ),
          ),
        ),
        Switch(
          value: _includeDeviceInfo,
          onChanged: (value) {
            setState(() {
              _includeDeviceInfo = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: _isSending ? null : _sendEmail,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: _isSending
            ? SizedBox(
                width: 24.r,
                height: 24.r,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                "support.send_message".tr(),
                style: GoogleFonts.slabo27px(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _attachmentPaths.add(image.path);
        });
      }
    } catch (e) {
      AppDialogs.showSnackBar(
        context,
        message: "support.image_pick_error".tr(),
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      // SMTP configuration for privateemail.com
      String smtpUsername = 'support@billiongroup.net';
      String smtpPassword = 'Aqswde!123';
      final smtpServer = SmtpServer(
        'mail.privateemail.com',
        username: smtpUsername,
        password: smtpPassword,
        port: 587,
        ssl: false, // Using TLS/STARTTLS instead of SSL
        allowInsecure: false,
      );

      // Gather diagnostic information
      String deviceInfo = '';
      if (_includeDeviceInfo) {
        deviceInfo = '\n\n---\n';
        deviceInfo += 'Device Information:\n';
        deviceInfo +=
            'Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}\n';
        deviceInfo +=
            'App Version: 1.0.0\n'; // Replace with your actual app version
        deviceInfo += 'User Name: ${_nameController.text}\n';
        deviceInfo += 'User Email: ${_emailController.text}\n';
      }

      // Prepare the email message
      final message = Message()
        ..from = Address(smtpUsername, _nameController.text)
        ..recipients.add('support@scanpro.app')
        ..subject = _selectedSubject
        ..text = _messageController.text + deviceInfo
        ..attachments =
            _attachmentPaths.map((path) => FileAttachment(File(path))).toList();

      await send(message, smtpServer);

      // Clear the form
      if (mounted) {
        _nameController.clear();
        _emailController.clear();
        _messageController.clear();
        setState(() {
          _attachmentPaths = [];
        });

        AppDialogs.showSnackBar(
          context,
          message: "support.message_sent".tr(),
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        AppDialogs.showSnackBar(
          context,
          message: "${"support.send_error".tr()}: ${e.toString()}",
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
}
