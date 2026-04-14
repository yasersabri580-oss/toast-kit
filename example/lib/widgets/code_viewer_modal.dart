import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A modal bottom sheet that displays source code with syntax highlighting,
/// a copy-to-clipboard button, and a short description of what the code does.
///
/// Usage:
/// ```dart
/// CodeViewerModal.show(
///   context: context,
///   title: 'Deduplication Rule',
///   description: 'Collapses identical toasts within a 2-second window.',
///   code: '''ToastKit.configureRule(...);''',
/// );
/// ```
class CodeViewerModal {
  CodeViewerModal._();

  /// Show the code viewer as a modal bottom sheet.
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String description,
    required String code,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CodeViewerContent(
        title: title,
        description: description,
        code: code,
      ),
    );
  }
}

class _CodeViewerContent extends StatefulWidget {
  const _CodeViewerContent({
    required this.title,
    required this.description,
    required this.code,
  });

  final String title;
  final String description;
  final String code;

  @override
  State<_CodeViewerContent> createState() => _CodeViewerContentState();
}

class _CodeViewerContentState extends State<_CodeViewerContent> {
  bool _copied = false;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            // ── Drag handle ──
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withAlpha(60),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Icon(Icons.code, color: cs.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Description ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            // ── Code block ──
            Expanded(
              child: Container(
                color: isDark
                    ? const Color(0xFF1E1E2E)
                    : const Color(0xFFF5F5F5),
                child: Stack(
                  children: [
                    ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        _SyntaxHighlightedCode(
                          code: widget.code,
                          isDark: isDark,
                        ),
                      ],
                    ),

                    // ── Copy button ──
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: _copyToClipboard,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _copied
                                  ? Colors.green.withAlpha(30)
                                  : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _copied
                                    ? Colors.green.withAlpha(80)
                                    : cs.outlineVariant.withAlpha(80),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _copied ? Icons.check : Icons.copy,
                                  size: 14,
                                  color: _copied
                                      ? Colors.green
                                      : cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _copied ? 'Copied!' : 'Copy',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _copied
                                        ? Colors.green
                                        : cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Lightweight Dart syntax highlighter
// ---------------------------------------------------------------------------

class _SyntaxHighlightedCode extends StatelessWidget {
  const _SyntaxHighlightedCode({
    required this.code,
    required this.isDark,
  });

  final String code;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
          color: isDark ? const Color(0xFFCDD6F4) : const Color(0xFF1E1E2E),
        ),
        children: _highlightDart(code),
      ),
    );
  }

  List<TextSpan> _highlightDart(String source) {
    final spans = <TextSpan>[];
    final lines = source.split('\n');

    for (var i = 0; i < lines.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: '\n'));
      spans.addAll(_highlightLine(lines[i]));
    }

    return spans;
  }

  List<TextSpan> _highlightLine(String line) {
    final spans = <TextSpan>[];

    // Simple regex-based tokeniser for Dart
    final pattern = RegExp(
      r'''(\/\/.*$)'''                                // line comments
      r'''|(\'[^\']*\')'''                            // single-quoted strings
      r'''|(\"[^\"]*\")'''                            // double-quoted strings
      r'''|(\b(?:import|export|class|extends|implements|with|mixin|enum|typedef|abstract|sealed|final|const|var|late|void|static|return|if|else|switch|case|default|for|while|do|break|continue|throw|try|catch|finally|new|this|super|true|false|null|async|await|Future|Stream|required|override)\b)'''
      r'''|(\b(?:int|double|String|bool|List|Map|Set|Duration|DateTime|Widget|BuildContext|State|Key|Color|Icon|Text|Row|Column|Expanded|Padding|Container|SizedBox|VoidCallback)\b)'''
      r'''|(\b\d+\.?\d*\b)'''                         // numbers
      r'''|(@\w+)''',                                  // annotations
      multiLine: true,
    );

    var lastEnd = 0;

    for (final match in pattern.allMatches(line)) {
      // Plain text before this match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: line.substring(lastEnd, match.start)));
      }

      final text = match.group(0)!;
      Color color;

      if (match.group(1) != null) {
        // Comment
        color = isDark ? const Color(0xFF6C7086) : const Color(0xFF6A9955);
      } else if (match.group(2) != null || match.group(3) != null) {
        // String
        color = isDark ? const Color(0xFFA6E3A1) : const Color(0xFFC41A16);
      } else if (match.group(4) != null) {
        // Keyword
        color = isDark ? const Color(0xFFCBA6F7) : const Color(0xFF0000FF);
      } else if (match.group(5) != null) {
        // Type
        color = isDark ? const Color(0xFF89B4FA) : const Color(0xFF267F99);
      } else if (match.group(6) != null) {
        // Number
        color = isDark ? const Color(0xFFFAB387) : const Color(0xFF098658);
      } else if (match.group(7) != null) {
        // Annotation
        color = isDark ? const Color(0xFFF9E2AF) : const Color(0xFF795E26);
      } else {
        color = isDark
            ? const Color(0xFFCDD6F4)
            : const Color(0xFF1E1E2E);
      }

      spans.add(TextSpan(
        text: text,
        style: TextStyle(color: color),
      ));

      lastEnd = match.end;
    }

    // Remaining plain text
    if (lastEnd < line.length) {
      spans.add(TextSpan(text: line.substring(lastEnd)));
    }

    return spans;
  }
}
