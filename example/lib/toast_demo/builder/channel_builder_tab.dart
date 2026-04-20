import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

import 'builder_models.dart';

// =============================================================================
// Channel Builder Tab
//
// A full-featured channel management tab for the Toast Builder UI. Users can
// add, edit, and delete toast channels, configure per-channel queue policies,
// and fine-tune every ToastChannel property through an intuitive card-based
// interface.
// =============================================================================

/// A tab widget that provides complete CRUD operations for toast channels,
/// including per-channel configuration (queue policies, throttling, dedup).
class ChannelBuilderTab extends StatefulWidget {
  const ChannelBuilderTab({
    super.key,
    required this.channels,
    required this.channelConfigs,
    required this.onChanged,
  });

  /// The current list of user-defined channels.
  final List<ChannelModel> channels;

  /// Per-channel configuration map keyed by channel id.
  final Map<String, ChannelConfigModel> channelConfigs;

  /// Called whenever any channel or config property changes.
  final VoidCallback onChanged;

  @override
  State<ChannelBuilderTab> createState() => _ChannelBuilderTabState();
}

class _ChannelBuilderTabState extends State<ChannelBuilderTab> {
  /// Tracks which channel cards are currently expanded.
  final Set<int> _expandedIndices = {};

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns a human-readable label for a [ToastPriority] value.
  String _priorityLabel(ToastPriority? priority) {
    if (priority == null) return 'None';
    switch (priority) {
      case ToastPriority.low:
        return 'Low';
      case ToastPriority.normal:
        return 'Normal';
      case ToastPriority.high:
        return 'High';
      case ToastPriority.urgent:
        return 'Urgent';
    }
  }

  /// Returns a human-readable label for a [ToastPosition] value.
  String _positionLabel(ToastPosition? position) {
    if (position == null) return 'None';
    switch (position) {
      case ToastPosition.top:
        return 'Top';
      case ToastPosition.topLeft:
        return 'Top Left';
      case ToastPosition.topRight:
        return 'Top Right';
      case ToastPosition.center:
        return 'Center';
      case ToastPosition.centerLeft:
        return 'Center Left';
      case ToastPosition.centerRight:
        return 'Center Right';
      case ToastPosition.bottom:
        return 'Bottom';
      case ToastPosition.bottomLeft:
        return 'Bottom Left';
      case ToastPosition.bottomRight:
        return 'Bottom Right';
    }
  }

  /// Returns a human-readable label for a [ToastAnimationType] value.
  String _animationLabel(ToastAnimationType? animation) {
    if (animation == null) return 'None';
    switch (animation) {
      case ToastAnimationType.fade:
        return 'Fade';
      case ToastAnimationType.slideFromTop:
        return 'Slide from Top';
      case ToastAnimationType.slideFromBottom:
        return 'Slide from Bottom';
      case ToastAnimationType.slideFromLeft:
        return 'Slide from Left';
      case ToastAnimationType.slideFromRight:
        return 'Slide from Right';
      case ToastAnimationType.scale:
        return 'Scale';
      case ToastAnimationType.bounce:
        return 'Bounce';
      case ToastAnimationType.elastic:
        return 'Elastic';
      case ToastAnimationType.spring:
        return 'Spring';
      case ToastAnimationType.shake:
        return 'Shake';
      case ToastAnimationType.blur:
        return 'Blur';
      case ToastAnimationType.glow:
        return 'Glow';
      case ToastAnimationType.custom:
        return 'Custom';
    }
  }

  /// Returns a human-readable label for a [ToastVariant] value.
  String _variantLabel(ToastVariant? variant) {
    if (variant == null) return 'None';
    // Look up in the built-in options first for a friendly name.
    for (final option in kBuiltInVariantOptions) {
      if (option.$1 == variant) return option.$2;
    }
    // Fallback to the enum name.
    return variant.name;
  }

  /// Builds a brief summary string for a channel card subtitle.
  String _channelSummary(ChannelModel channel) {
    final parts = <String>[];
    if (!channel.enabled) parts.add('disabled');
    if (channel.defaultPosition != null) {
      parts.add(_positionLabel(channel.defaultPosition));
    }
    if (channel.defaultPriority != null) {
      parts.add(_priorityLabel(channel.defaultPriority));
    }
    if (channel.maxVisible != null) {
      parts.add('max ${channel.maxVisible}');
    }
    if (parts.isEmpty) return 'Default settings';
    return parts.join(' · ');
  }

  /// Returns the [ChannelConfigModel] for the given channel, creating one if
  /// it does not already exist.
  ChannelConfigModel _configFor(String channelId) {
    return widget.channelConfigs.putIfAbsent(
      channelId,
      () => ChannelConfigModel(),
    );
  }

  /// Validates that the given [id] is unique among all channels except the one
  /// at [currentIndex].
  bool _isIdUnique(String id, int currentIndex) {
    for (int i = 0; i < widget.channels.length; i++) {
      if (i != currentIndex && widget.channels[i].id == id) return false;
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _addChannel() {
    final channel = ChannelModel();
    widget.channels.add(channel);
    widget.channelConfigs[channel.id] = ChannelConfigModel();
    setState(() {
      _expandedIndices.add(widget.channels.length - 1);
    });
    widget.onChanged();
  }

  void _deleteChannel(int index) {
    final channel = widget.channels[index];
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Channel'),
        content: Text(
          'Are you sure you want to delete "${channel.label}" '
          '(${channel.id})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          widget.channelConfigs.remove(channel.id);
          widget.channels.removeAt(index);
          _expandedIndices.remove(index);
          // Shift expanded indices that were above the removed item.
          final shifted = <int>{};
          for (final i in _expandedIndices) {
            if (i > index) {
              shifted.add(i - 1);
            } else {
              shifted.add(i);
            }
          }
          _expandedIndices
            ..clear()
            ..addAll(shifted);
        });
        widget.onChanged();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.layers_outlined, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text('Channels', style: textTheme.titleLarge),
            const Spacer(),
            Text(
              '${widget.channels.length} defined',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Define toast channels and configure their queue policies, '
          'defaults, and display behavior.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Channel list
        if (widget.channels.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No channels yet',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add a channel to get started.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(widget.channels.length, (index) {
            return _buildChannelCard(index);
          }),

        const SizedBox(height: 16),

        // Add channel button
        Center(
          child: FilledButton.tonalIcon(
            onPressed: _addChannel,
            icon: const Icon(Icons.add),
            label: const Text('Add Channel'),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Channel Card
  // ---------------------------------------------------------------------------

  Widget _buildChannelCard(int index) {
    final channel = widget.channels[index];
    final isExpanded = _expandedIndices.contains(index);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Card header — tappable to expand/collapse
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedIndices.remove(index);
                  } else {
                    _expandedIndices.add(index);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Enabled indicator
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: channel.enabled
                            ? colorScheme.primary
                            : colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            channel.label,
                            style: textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${channel.id} · ${_channelSummary(channel)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Delete button
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      tooltip: 'Delete channel',
                      onPressed: () => _deleteChannel(index),
                    ),
                    // Expand/collapse icon
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),

            // Expanded content
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    _buildChannelProperties(index, channel),
                    const SizedBox(height: 16),
                    _buildChannelConfigSection(index, channel),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Channel Properties
  // ---------------------------------------------------------------------------

  Widget _buildChannelProperties(int index, ChannelModel channel) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Text(
          'Channel Properties',
          style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
        ),
        const SizedBox(height: 12),

        // ID field
        TextFormField(
          initialValue: channel.id,
          decoration: InputDecoration(
            labelText: 'Channel ID',
            hintText: 'e.g. auth, network, payments',
            border: const OutlineInputBorder(),
            errorText: channel.id.isEmpty
                ? 'ID is required'
                : !_isIdUnique(channel.id, index)
                    ? 'ID must be unique'
                    : null,
          ),
          onChanged: (value) {
            final oldId = channel.id;
            channel.id = value;

            // Only migrate the config map key when the new id is valid
            // and unique to avoid overwriting another channel's config.
            if (value.isNotEmpty && _isIdUnique(value, index)) {
              final config = widget.channelConfigs.remove(oldId);
              if (config != null) {
                widget.channelConfigs[value] = config;
              }
            }

            setState(() {});
            widget.onChanged();
          },
        ),
        const SizedBox(height: 12),

        // Label field
        TextFormField(
          initialValue: channel.label,
          decoration: const InputDecoration(
            labelText: 'Label',
            hintText: 'Display name for this channel',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            channel.label = value;
            setState(() {});
            widget.onChanged();
          },
        ),
        const SizedBox(height: 12),

        // Enabled switch
        SwitchListTile(
          title: const Text('Enabled'),
          subtitle: const Text('Disabled channels will not show toasts'),
          value: channel.enabled,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            channel.enabled = value;
            setState(() {});
            widget.onChanged();
          },
        ),
        const SizedBox(height: 8),

        // Max visible (nullable int slider with enable checkbox)
        _buildNullableIntSlider(
          label: 'Max Visible',
          tooltip: 'Maximum number of toasts visible at once for this channel',
          value: channel.maxVisible,
          min: 1,
          max: 10,
          onChanged: (val) {
            channel.maxVisible = val;
            setState(() {});
            widget.onChanged();
          },
        ),
        const SizedBox(height: 8),

        // Default priority dropdown
        _buildNullableDropdown<ToastPriority>(
          label: 'Default Priority',
          value: channel.defaultPriority,
          items: ToastPriority.values,
          labelBuilder: _priorityLabel,
          onChanged: (val) {
            channel.defaultPriority = val;
            setState(() {});
            widget.onChanged();
          },
        ),
        const SizedBox(height: 8),

        // Default position dropdown
        _buildNullableDropdown<ToastPosition>(
          label: 'Default Position',
          value: channel.defaultPosition,
          items: ToastPosition.values,
          labelBuilder: _positionLabel,
          onChanged: (val) {
            channel.defaultPosition = val;
            setState(() {});
            widget.onChanged();
          },
        ),
        const SizedBox(height: 8),

        // Default duration (nullable, slider 1–15 seconds)
        _buildNullableDurationSlider(
          label: 'Default Duration',
          tooltip: 'How long the toast is displayed before auto-dismiss',
          value: channel.defaultDuration,
          minSeconds: 1,
          maxSeconds: 15,
          onChanged: (val) {
            channel.defaultDuration = val;
            setState(() {});
            widget.onChanged();
          },
        ),
        const SizedBox(height: 8),

        // Default animation dropdown
        _buildNullableDropdown<ToastAnimationType>(
          label: 'Default Animation',
          value: channel.defaultAnimation,
          items: ToastAnimationType.values,
          labelBuilder: _animationLabel,
          onChanged: (val) {
            channel.defaultAnimation = val;
            setState(() {});
            widget.onChanged();
          },
        ),
        const SizedBox(height: 8),

        // Default variant dropdown
        _buildNullableDropdown<ToastVariant>(
          label: 'Default Variant',
          value: channel.defaultVariant,
          items: ToastVariant.values,
          labelBuilder: _variantLabel,
          onChanged: (val) {
            channel.defaultVariant = val;
            setState(() {});
            widget.onChanged();
          },
        ),
        const SizedBox(height: 12),

        // Custom variant name
        TextFormField(
          initialValue: channel.customVariantName ?? '',
          decoration: InputDecoration(
            labelText: 'Custom Variant Name',
            hintText: 'e.g. payment_success',
            border: const OutlineInputBorder(),
            suffix: Tooltip(
              message: 'If set, this overrides the Default Variant above.\n'
                  'Use a name registered via ToastService.registerVariant().',
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          onChanged: (value) {
            channel.customVariantName = value.isEmpty ? null : value;
            setState(() {});
            widget.onChanged();
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Per-Channel Config Section
  // ---------------------------------------------------------------------------

  Widget _buildChannelConfigSection(int index, ChannelModel channel) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final config = _configFor(channel.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(Icons.tune, size: 18, color: colorScheme.secondary),
            const SizedBox(width: 6),
            Text(
              'Channel Config (Queue Policies)',
              style:
                  textTheme.labelLarge?.copyWith(color: colorScheme.secondary),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Max visible (config-level override)
        _buildNullableIntSlider(
          label: 'Max Visible (Config)',
          tooltip: 'Config-level max visible override for the queue',
          value: config.maxVisible,
          min: 1,
          max: 10,
          onChanged: (val) {
            config.maxVisible = val;
            setState(() {});
            widget.onChanged();
          },
        ),
        const SizedBox(height: 8),

        // Duration (config-level)
        _buildNullableDurationSlider(
          label: 'Duration (Config)',
          tooltip: 'Config-level default duration for toasts in this channel',
          value: config.duration,
          minSeconds: 1,
          maxSeconds: 15,
          onChanged: (val) {
            config.duration = val;
            setState(() {});
            widget.onChanged();
          },
        ),
        const SizedBox(height: 8),

        // Interrupt current
        SwitchListTile(
          title: const Text('Interrupt Current'),
          subtitle: const Text(
            'New toasts immediately replace any currently visible toast',
          ),
          value: config.interruptCurrent,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            config.interruptCurrent = value;
            setState(() {});
            widget.onChanged();
          },
        ),

        // Deduplication
        SwitchListTile(
          title: const Text('Enable Deduplication'),
          subtitle: const Text(
            'Suppress duplicate toasts within a time window',
          ),
          value: config.enableDeduplication,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            config.enableDeduplication = value;
            setState(() {});
            widget.onChanged();
          },
        ),

        // Deduplication window — only visible when dedup is enabled
        if (config.enableDeduplication)
          _buildIntSlider(
            label: 'Deduplication Window',
            suffix: 's',
            value: config.deduplicationWindowSec,
            min: 1,
            max: 30,
            onChanged: (val) {
              config.deduplicationWindowSec = val;
              setState(() {});
              widget.onChanged();
            },
          ),

        // Throttling
        SwitchListTile(
          title: const Text('Enable Throttling'),
          subtitle: const Text(
            'Rate-limit how often toasts can appear',
          ),
          value: config.enableThrottling,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            config.enableThrottling = value;
            setState(() {});
            widget.onChanged();
          },
        ),

        // Throttle interval — only visible when throttling is enabled
        if (config.enableThrottling)
          _buildIntSlider(
            label: 'Throttle Interval',
            suffix: 'ms',
            value: config.throttleIntervalMs,
            min: 100,
            max: 5000,
            divisions: 49,
            onChanged: (val) {
              config.throttleIntervalMs = val;
              setState(() {});
              widget.onChanged();
            },
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable control builders
  // ---------------------------------------------------------------------------

  /// A nullable integer slider with an enable/disable checkbox.
  ///
  /// When unchecked the value is null; when checked the slider is active.
  Widget _buildNullableIntSlider({
    required String label,
    required int? value,
    required int min,
    required int max,
    required ValueChanged<int?> onChanged,
    String? tooltip,
  }) {
    final isEnabled = value != null;
    final displayValue = value ?? min;
    final colorScheme = Theme.of(context).colorScheme;

    Widget content = Row(
      children: [
        Checkbox(
          value: isEnabled,
          onChanged: (checked) {
            onChanged(checked == true ? displayValue : null);
          },
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: ${isEnabled ? displayValue : "—"}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isEnabled
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
              ),
              Slider(
                value: displayValue.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                label: displayValue.toString(),
                onChanged: isEnabled
                    ? (v) => onChanged(v.round())
                    : null,
              ),
            ],
          ),
        ),
      ],
    );

    if (tooltip != null) {
      content = Tooltip(message: tooltip, child: content);
    }

    return content;
  }

  /// A nullable duration slider with an enable/disable checkbox.
  Widget _buildNullableDurationSlider({
    required String label,
    required Duration? value,
    required int minSeconds,
    required int maxSeconds,
    required ValueChanged<Duration?> onChanged,
    String? tooltip,
  }) {
    final isEnabled = value != null;
    final displaySeconds = value?.inSeconds ?? minSeconds;
    final colorScheme = Theme.of(context).colorScheme;

    Widget content = Row(
      children: [
        Checkbox(
          value: isEnabled,
          onChanged: (checked) {
            onChanged(
              checked == true ? Duration(seconds: displaySeconds) : null,
            );
          },
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: ${isEnabled ? "${displaySeconds}s" : "—"}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isEnabled
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
              ),
              Slider(
                value: displaySeconds.toDouble(),
                min: minSeconds.toDouble(),
                max: maxSeconds.toDouble(),
                divisions: maxSeconds - minSeconds,
                label: '${displaySeconds}s',
                onChanged: isEnabled
                    ? (v) => onChanged(Duration(seconds: v.round()))
                    : null,
              ),
            ],
          ),
        ),
      ],
    );

    if (tooltip != null) {
      content = Tooltip(message: tooltip, child: content);
    }

    return content;
  }

  /// A non-nullable integer slider (always active).
  Widget _buildIntSlider({
    required String label,
    required String suffix,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
    int? divisions,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: $value $suffix',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: divisions ?? (max - min),
            label: '$value $suffix',
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }

  /// A dropdown that includes a "None" option for null values.
  Widget _buildNullableDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T?) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    // Build menu items: "None" first, then all enum values.
    final menuItems = <DropdownMenuItem<T?>>[
      const DropdownMenuItem<Null>(
        value: null,
        child: Text('None'),
      ),
      ...items.map(
        (item) => DropdownMenuItem<T?>(
          value: item,
          child: Text(labelBuilder(item)),
        ),
      ),
    ];

    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: DropdownButtonFormField<T?>(
            value: value,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: menuItems,
            onChanged: (val) => onChanged(val),
          ),
        ),
      ],
    );
  }
}
