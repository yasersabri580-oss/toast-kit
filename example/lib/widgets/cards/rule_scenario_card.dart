import 'package:flutter/material.dart';

import '../see_code_button.dart';

/// A self-contained card for demonstrating a single ToastKit rule scenario.
///
/// Each card includes:
/// - Scenario title & icon
/// - A short real-life explanation
/// - Interactive controls (passed as [children])
/// - A visible result area (passed as [resultWidget], optional)
/// - The ToastKit rule configuration code (shown via "See Code")
/// - A "Why this matters" note
class RuleScenarioCard extends StatelessWidget {
  const RuleScenarioCard({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor,
    required this.explanation,
    required this.whyItMatters,
    required this.codeTitle,
    required this.codeDescription,
    required this.code,
    required this.children,
    this.resultWidget,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Color? iconColor;
  final String explanation;
  final String whyItMatters;
  final String codeTitle;
  final String codeDescription;
  final String code;
  final List<Widget> children;
  final Widget? resultWidget;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = iconColor ?? cs.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),

            // ── Explanation ──
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 14),
              child: Text(
                explanation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),

            // ── Interactive controls ──
            ...List.generate(
              children.length * 2 - 1,
              (i) =>
                  i.isOdd ? const SizedBox(height: 10) : children[i ~/ 2],
            ),

            // ── Result area ──
            if (resultWidget != null) ...[
              const SizedBox(height: 14),
              resultWidget!,
            ],

            // ── Footer: See Code + Why This Matters ──
            const SizedBox(height: 14),
            Row(
              children: [
                SeeCodeButton(
                  title: codeTitle,
                  description: codeDescription,
                  code: code,
                ),
                const Spacer(),
              ],
            ),

            // "Why this matters" note
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: cs.primary.withAlpha(30),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        whyItMatters,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
