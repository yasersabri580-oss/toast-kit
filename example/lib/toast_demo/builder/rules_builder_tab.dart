import 'package:flutter/material.dart';

import 'builder_models.dart';

// =============================================================================
// Rules Builder Tab
//
// Manages toast rules in the Toast Builder UI. Users can create, edit, and
// delete config-based rules (RuleConfig) and custom rules (ToastRule) through
// an intuitive card-based interface.
// =============================================================================

/// A tab widget for managing config-based and custom toast rules.
class RulesBuilderTab extends StatefulWidget {
  const RulesBuilderTab({
    super.key,
    required this.channels,
    required this.ruleConfigs,
    required this.customRules,
    required this.onChanged,
  });

  /// The channels defined by the user (used for channel dropdowns).
  final List<ChannelModel> channels;

  /// Config-based rules.
  final List<RuleConfigModel> ruleConfigs;

  /// Custom rules.
  final List<CustomRuleModel> customRules;

  /// Called whenever anything changes.
  final VoidCallback onChanged;

  @override
  State<RulesBuilderTab> createState() => _RulesBuilderTabState();
}

class _RulesBuilderTabState extends State<RulesBuilderTab> {
  // ---------------------------------------------------------------------------
  // Config-Based Rule Actions
  // ---------------------------------------------------------------------------

  void _addRuleConfig() {
    if (widget.channels.isEmpty) return;
    setState(() {
      widget.ruleConfigs.add(
        RuleConfigModel(channelId: widget.channels.first.id),
      );
    });
    widget.onChanged();
  }

  void _removeRuleConfig(int index) {
    setState(() {
      widget.ruleConfigs.removeAt(index);
    });
    widget.onChanged();
  }

  // ---------------------------------------------------------------------------
  // Custom Rule Actions
  // ---------------------------------------------------------------------------

  void _addCustomRule() {
    if (widget.channels.isEmpty) return;
    setState(() {
      widget.customRules.add(
        CustomRuleModel(channelId: widget.channels.first.id),
      );
    });
    widget.onChanged();
  }

  void _removeCustomRule(int index) {
    setState(() {
      widget.customRules.removeAt(index);
    });
    widget.onChanged();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns the label for a channel, falling back to its id.
  // ignore: unused_element
  String _channelLabel(String channelId) {
    for (final channel in widget.channels) {
      if (channel.id == channelId) return channel.label;
    }
    return channelId;
  }

  /// Returns the max-triggers display text.
  String _maxTriggersLabel(int value) {
    if (value == 0) return '0 (unlimited)';
    return value.toString();
  }

  /// Ensures the channel id is valid; returns first channel id if not.
  String _validChannelId(String channelId) {
    for (final channel in widget.channels) {
      if (channel.id == channelId) return channelId;
    }
    if (widget.channels.isNotEmpty) return widget.channels.first.id;
    return channelId;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (widget.channels.isEmpty) {
      return _buildEmptyState(colorScheme, textTheme);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildConfigRulesSection(colorScheme, textTheme),
        const SizedBox(height: 24),
        _buildCustomRulesSection(colorScheme, textTheme),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Empty State
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Channels Defined',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add channels in the Channels tab first before configuring '
              'rules.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 1 – Config-Based Rules
  // ---------------------------------------------------------------------------

  Widget _buildConfigRulesSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tune, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Config-Based Rules',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Define rules that trigger toasts based on error thresholds and '
          'deduplication settings.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.ruleConfigs.isEmpty)
          _buildEmptyListPlaceholder(
            colorScheme,
            textTheme,
            'No config-based rules defined.',
          ),
        ...List<Widget>.generate(
          widget.ruleConfigs.length,
          (index) => _buildRuleConfigCard(index, colorScheme, textTheme),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: _addRuleConfig,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Config Rule'),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleConfigCard(
    int index,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final rule = widget.ruleConfigs[index];
    // Ensure channel id is valid after channels may have been removed.
    rule.channelId = _validChannelId(rule.channelId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Config Rule ${index + 1}',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    tooltip: 'Delete rule',
                    onPressed: () => _removeRuleConfig(index),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Channel dropdown
              DropdownButtonFormField<String>(
                value: rule.channelId,
                decoration: const InputDecoration(
                  labelText: 'Channel',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: widget.channels.map((channel) {
                  return DropdownMenuItem<String>(
                    value: channel.id,
                    child: Text(channel.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    rule.channelId = value;
                  });
                  widget.onChanged();
                },
              ),
              const SizedBox(height: 16),

              // Error Threshold slider
              _buildSliderRow(
                label: 'Error Threshold',
                value: rule.errorThreshold.toDouble(),
                min: 1,
                max: 20,
                divisions: 19,
                displayValue: rule.errorThreshold.toString(),
                onChanged: (value) {
                  setState(() {
                    rule.errorThreshold = value.round();
                  });
                  widget.onChanged();
                },
              ),
              const SizedBox(height: 8),

              // Deduplication Window slider
              _buildSliderRow(
                label: 'Deduplication Window',
                value: rule.deduplicateWindowSec.toDouble(),
                min: 5,
                max: 120,
                divisions: 23,
                displayValue: '${rule.deduplicateWindowSec}s',
                onChanged: (value) {
                  setState(() {
                    rule.deduplicateWindowSec = value.round();
                  });
                  widget.onChanged();
                },
              ),
              const SizedBox(height: 8),

              // Max Triggers slider
              _buildSliderRow(
                label: 'Max Triggers',
                value: rule.maxTriggers.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                displayValue: _maxTriggersLabel(rule.maxTriggers),
                tooltip: '0 means unlimited triggers',
                onChanged: (value) {
                  setState(() {
                    rule.maxTriggers = value.round();
                  });
                  widget.onChanged();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 2 – Custom Rules
  // ---------------------------------------------------------------------------

  Widget _buildCustomRulesSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.rule, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Custom Rules',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Define fully customizable rules with conditions and actions.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.customRules.isEmpty)
          _buildEmptyListPlaceholder(
            colorScheme,
            textTheme,
            'No custom rules defined.',
          ),
        ...List<Widget>.generate(
          widget.customRules.length,
          (index) => _buildCustomRuleCard(index, colorScheme, textTheme),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: _addCustomRule,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Custom Rule'),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomRuleCard(
    int index,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final rule = widget.customRules[index];
    rule.channelId = _validChannelId(rule.channelId);
    final hasDedupWindow = rule.deduplicateWindowSec != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Custom Rule ${index + 1}',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    tooltip: 'Delete rule',
                    onPressed: () => _removeCustomRule(index),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Rule ID
              TextFormField(
                initialValue: rule.id,
                decoration: const InputDecoration(
                  labelText: 'Rule ID',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  rule.id = value;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: 12),

              // Channel dropdown
              DropdownButtonFormField<String>(
                value: rule.channelId,
                decoration: const InputDecoration(
                  labelText: 'Channel',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: widget.channels.map((channel) {
                  return DropdownMenuItem<String>(
                    value: channel.id,
                    child: Text(channel.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    rule.channelId = value;
                  });
                  widget.onChanged();
                },
              ),
              const SizedBox(height: 16),

              // Max Triggers slider
              _buildSliderRow(
                label: 'Max Triggers',
                value: rule.maxTriggers.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                displayValue: _maxTriggersLabel(rule.maxTriggers),
                tooltip: '0 means unlimited triggers',
                onChanged: (value) {
                  setState(() {
                    rule.maxTriggers = value.round();
                  });
                  widget.onChanged();
                },
              ),
              const SizedBox(height: 12),

              // Deduplication Window (optional)
              Row(
                children: [
                  Checkbox(
                    value: hasDedupWindow,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          rule.deduplicateWindowSec = 30;
                        } else {
                          rule.deduplicateWindowSec = null;
                        }
                      });
                      widget.onChanged();
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Enable Deduplication Window',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              if (hasDedupWindow) ...[
                _buildSliderRow(
                  label: 'Deduplication Window',
                  value: rule.deduplicateWindowSec!.toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 23,
                  displayValue: '${rule.deduplicateWindowSec}s',
                  onChanged: (value) {
                    setState(() {
                      rule.deduplicateWindowSec = value.round();
                    });
                    widget.onChanged();
                  },
                ),
                const SizedBox(height: 8),
              ],

              const Divider(height: 24),

              // Condition section header
              Text(
                'Condition',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),

              // Condition Type dropdown
              DropdownButtonFormField<RuleConditionType>(
                value: rule.conditionType,
                decoration: const InputDecoration(
                  labelText: 'Condition Type',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: RuleConditionType.values.map((type) {
                  return DropdownMenuItem<RuleConditionType>(
                    value: type,
                    child: Text(type.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    rule.conditionType = value;
                  });
                  widget.onChanged();
                },
              ),
              const SizedBox(height: 12),

              // Condition Threshold slider
              _buildSliderRow(
                label: 'Condition Threshold',
                value: rule.conditionThreshold.toDouble(),
                min: 1,
                max: 20,
                divisions: 19,
                displayValue: rule.conditionThreshold.toString(),
                onChanged: (value) {
                  setState(() {
                    rule.conditionThreshold = value.round();
                  });
                  widget.onChanged();
                },
              ),

              const Divider(height: 24),

              // Action section header
              Text(
                'Action',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),

              // Action Type dropdown
              DropdownButtonFormField<RuleActionType>(
                value: rule.actionType,
                decoration: const InputDecoration(
                  labelText: 'Action Type',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: RuleActionType.values.map((type) {
                  return DropdownMenuItem<RuleActionType>(
                    value: type,
                    child: Text(type.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    rule.actionType = value;
                  });
                  widget.onChanged();
                },
              ),
              const SizedBox(height: 12),

              // Action Message
              TextFormField(
                initialValue: rule.actionMessage,
                decoration: const InputDecoration(
                  labelText: 'Action Message',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  rule.actionMessage = value;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: 12),

              // Action Title (optional)
              TextFormField(
                initialValue: rule.actionTitle ?? '',
                decoration: const InputDecoration(
                  labelText: 'Action Title (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  rule.actionTitle = value.isEmpty ? null : value;
                  widget.onChanged();
                },
              ),
              const SizedBox(height: 12),

              // Persistent switch
              SwitchListTile(
                title: const Text('Persistent'),
                subtitle: const Text(
                  'Toast stays visible until dismissed',
                ),
                value: rule.persistent,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() {
                    rule.persistent = value;
                  });
                  widget.onChanged();
                },
              ),

              // Dismissible switch
              SwitchListTile(
                title: const Text('Dismissible'),
                subtitle: const Text(
                  'User can swipe or tap to dismiss',
                ),
                value: rule.dismissible,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() {
                    rule.dismissible = value;
                  });
                  widget.onChanged();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared Widgets
  // ---------------------------------------------------------------------------

  /// Builds a labeled slider row with an optional tooltip.
  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
    String? tooltip,
  }) {
    final labelWidget = Row(
      children: [
        Text(label),
        if (tooltip != null) ...[
          const SizedBox(width: 4),
          Tooltip(
            message: tooltip,
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const Spacer(),
        Text(
          displayValue,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        labelWidget,
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: displayValue,
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Builds a placeholder widget for empty lists.
  Widget _buildEmptyListPlaceholder(
    ColorScheme colorScheme,
    TextTheme textTheme,
    String message,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
