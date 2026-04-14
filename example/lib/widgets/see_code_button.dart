import 'package:flutter/material.dart';

import 'code_viewer_modal.dart';

/// A compact button that opens the [CodeViewerModal] when tapped.
///
/// Place this inside any demo section to provide a "See Code" action.
class SeeCodeButton extends StatelessWidget {
  const SeeCodeButton({
    super.key,
    required this.title,
    required this.description,
    required this.code,
  });

  /// Title shown in the modal header.
  final String title;

  /// Short explanation of what the example does.
  final String description;

  /// The exact source code to display.
  final String code;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextButton.icon(
      onPressed: () => CodeViewerModal.show(
        context: context,
        title: title,
        description: description,
        code: code,
      ),
      icon: Icon(Icons.code, size: 16, color: cs.primary),
      label: Text(
        'See Code',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.primary,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
