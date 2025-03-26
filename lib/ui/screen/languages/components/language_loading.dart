import 'package:flutter/material.dart';

class LanguageLoadingDialog extends StatelessWidget {
  const LanguageLoadingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator.adaptive(),
    );
  }
}
