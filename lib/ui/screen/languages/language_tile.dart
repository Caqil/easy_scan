import 'package:easy_scan/models/language.dart';
import 'package:flutter/material.dart';

class LanguageTile extends StatelessWidget {
  final Language language;
  final bool isSelected;
  final VoidCallback onTap;

  LanguageTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'languageTile-${language.languageCode}',
      child: ListTile(
        onTap: () {
          onTap();
        },
        title: Text(language.label),
        trailing: isSelected
            ? Icon(
                Icons.radio_button_on,
                size: 25.0,
                color: Theme.of(context).colorScheme.onPrimary,
              )
            : const Icon(
                Icons.radio_button_off,
                size: 25.0,
              ),
      ),
    );
  }
}
