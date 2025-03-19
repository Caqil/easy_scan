import 'package:scanpro/ui/screen/edit/component/edit_screen_controller.dart';
import 'package:scanpro/ui/screen/edit/widget/edit_screen_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/document.dart';

class EditScreen extends ConsumerStatefulWidget {
  final Document? document;

  const EditScreen({
    super.key,
    this.document,
  });

  @override
  ConsumerState<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends ConsumerState<EditScreen> {
  late final EditScreenController controller;

  @override
  void initState() {
    super.initState();
    controller = EditScreenController(
      ref: ref,
      context: context,
      document: widget.document,
    );
    controller.init();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EditScreenView(controller: controller);
  }
}
