import 'dart:io';
import 'package:easy_scan/providers/locale_provider.dart';
import 'package:easy_scan/ui/common/app_bar.dart';
import 'package:easy_scan/ui/screen/languages/language_loading.dart';
import 'package:easy_scan/ui/screen/languages/language_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LanguagesScreen extends ConsumerStatefulWidget {
  const LanguagesScreen({super.key});

  @override
  ConsumerState<LanguagesScreen> createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends ConsumerState<LanguagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localProvider.notifier).initializeLanguages(context);
    });
  }

  void showLoading(BuildContext context,
      {bool? isDismissible, bool? useLogo = false}) {
    showDialog(
      context: context,
      barrierDismissible: isDismissible ?? false,
      builder: (BuildContext context) {
        return LanguageLoadingDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localState = ref.watch(localProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: Text("setting_language".tr()),
      ),
      body: localState.languages.isEmpty
          ? Center(
              child: CircularProgressIndicator.adaptive(),
            )
          : SingleChildScrollView(
              child: CupertinoFormSection.insetGrouped(
                margin: EdgeInsetsDirectional.zero,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                children: [
                  ...List.generate(
                    localState.languages.length,
                    (index) => LanguageTile(
                      language: localState.languages[index],
                      isSelected: context.locale ==
                          Locale(
                            localState.languages[index].languageCode!,
                            localState.languages[index].countryCode,
                          ),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        showLoading(context);
                        Future.delayed(
                          const Duration(seconds: 2),
                          () async {
                            ref.read(localProvider.notifier).setLanguage(
                                  context,
                                  Locale(
                                    localState.languages[index].languageCode,
                                    localState.languages[index].countryCode,
                                  ),
                                );
                            if (Platform.isAndroid || Platform.isIOS) {
                              context.pop();
                            }
                            context.pop();
                          },
                        );
                      },
                    ),
                  ),
                  Platform.isAndroid || Platform.isIOS
                      ? SizedBox()
                      : SizedBox(height: 170.h)
                ],
              ),
            ),
    );
  }
}
