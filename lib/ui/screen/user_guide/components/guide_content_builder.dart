import 'package:flutter/material.dart';
import 'guide_widgets.dart';

class GuideContentBuilder extends StatelessWidget {
  final int selectedTopicIndex;

  const GuideContentBuilder({super.key, required this.selectedTopicIndex});

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    final guideWidgets = GuideWidgets(
      scrollController: scrollController,
      context: context,
    );

    switch (selectedTopicIndex) {
      case 0:
        return guideWidgets.buildGettingStartedGuide();
      case 1:
        return guideWidgets.buildDocumentScanningGuide();
      case 2:
        return guideWidgets.buildDocumentManagementGuide();
      case 3:
        return guideWidgets.buildOrganizationGuide();
      case 4:
        return guideWidgets.buildEditingGuide();
      case 5:
        return guideWidgets.buildPdfToolsGuide();
      case 6:
        return guideWidgets.buildSecurityGuide();
      case 7:
        return guideWidgets.buildImportExportGuide();
      case 8:
        return guideWidgets.buildSettingsGuide();
      case 9:
        return guideWidgets.buildTroubleshootingGuide();
      default:
        return guideWidgets.buildGettingStartedGuide();
    }
  }
}
