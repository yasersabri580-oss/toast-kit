import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

import 'builder_models.dart';

// =============================================================================
// Variant Builder Tab
//
// Manages toast variant assignments in the Toast Builder UI. Users can register
// custom variant names, assign built-in or custom variants per channel, and
// browse a visual gallery of all built-in variants.
// =============================================================================

/// A tab widget for managing toast variant registrations and per-channel
/// variant assignments.
class VariantBuilderTab extends StatefulWidget {
  const VariantBuilderTab({
    super.key,
    required this.channels,
    required this.registeredVariantNames,
    required this.onChanged,
  });

  /// The channels defined by the user.
  final List<ChannelModel> channels;

  /// List of custom variant names the user has registered.
  final List<String> registeredVariantNames;

  /// Called whenever anything changes.
  final VoidCallback onChanged;

  @override
  State<VariantBuilderTab> createState() => _VariantBuilderTabState();
}

class _VariantBuilderTabState extends State<VariantBuilderTab> {
  final TextEditingController _variantNameController = TextEditingController();

  @override
  void dispose() {
    _variantNameController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _addVariantName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (widget.registeredVariantNames.contains(trimmed)) return;
    setState(() {
      widget.registeredVariantNames.add(trimmed);
    });
    _variantNameController.clear();
    widget.onChanged();
  }

  void _removeVariantName(int index) {
    final removed = widget.registeredVariantNames[index];
    setState(() {
      widget.registeredVariantNames.removeAt(index);
    });
    // Clear references in channels that used this name.
    for (final channel in widget.channels) {
      if (channel.customVariantName == removed) {
        channel.customVariantName = null;
      }
    }
    widget.onChanged();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _variantLabel(ToastVariant? variant) {
    if (variant == null) return 'None';
    for (final entry in kBuiltInVariantOptions) {
      if (entry.$1 == variant) return entry.$2;
    }
    return variant.name;
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
        _buildRegisteredVariantsSection(colorScheme, textTheme),
        const SizedBox(height: 24),
        _buildPerChannelSection(colorScheme, textTheme),
        const SizedBox(height: 24),
        _buildVariantGallery(colorScheme, textTheme),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section 1 – Registered Custom Variants
  // ---------------------------------------------------------------------------

  Widget _buildRegisteredVariantsSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
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
            Text(
              'Registered Custom Variants',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Custom variants are defined as Dart classes extending '
              'CustomToastVariantBuilder. Register their names here to '
              'reference them in channels.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            // Add new variant name
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _variantNameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter custom variant name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: _addVariantName,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () =>
                      _addVariantName(_variantNameController.text),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Example chips
            Text(
              'Examples:',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: kExampleCustomVariants.map((name) {
                return ActionChip(
                  label: Text(name),
                  onPressed: () => _addVariantName(name),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Current registered list
            if (widget.registeredVariantNames.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No custom variants registered yet.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Column(
                children: List<Widget>.generate(
                  widget.registeredVariantNames.length,
                  (index) {
                    final name = widget.registeredVariantNames[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.extension,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      title: Text(name),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: colorScheme.error,
                          size: 20,
                        ),
                        tooltip: 'Remove variant',
                        onPressed: () => _removeVariantName(index),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 2 – Per-Channel Variant Assignment
  // ---------------------------------------------------------------------------

  Widget _buildPerChannelSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Per-Channel Variant Assignment',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message:
                  'Custom variant name takes precedence over built-in variant',
              child: Icon(
                Icons.info_outline,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.channels.isEmpty)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No channels defined yet. Add channels in the Channels '
                  'tab first.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        else
          ...widget.channels
              .map((channel) =>
                  _buildChannelVariantCard(channel, colorScheme, textTheme))
              .toList(),
      ],
    );
  }

  Widget _buildChannelVariantCard(
    ChannelModel channel,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // Build built-in variant dropdown items.
    final builtInItems = <DropdownMenuItem<ToastVariant?>>[
      const DropdownMenuItem<ToastVariant?>(
        value: null,
        child: Text('None'),
      ),
      ...kBuiltInVariantOptions.map((entry) {
        return DropdownMenuItem<ToastVariant?>(
          value: entry.$1,
          child: Text(entry.$2),
        );
      }),
    ];

    // Build custom variant dropdown items.
    final customItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('None'),
      ),
      ...widget.registeredVariantNames.map((name) {
        return DropdownMenuItem<String?>(
          value: name,
          child: Text(name),
        );
      }),
    ];

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
              Text(
                '${channel.label}  (${channel.id})',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              // Built-in variant dropdown
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ToastVariant?>(
                      value: channel.defaultVariant,
                      decoration: const InputDecoration(
                        labelText: 'Built-in Variant',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: builtInItems,
                      onChanged: (value) {
                        setState(() {
                          channel.defaultVariant = value;
                        });
                        widget.onChanged();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Custom variant name dropdown
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: widget.registeredVariantNames
                              .contains(channel.customVariantName)
                          ? channel.customVariantName
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Custom Variant Name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: customItems,
                      onChanged: (value) {
                        setState(() {
                          channel.customVariantName = value;
                        });
                        widget.onChanged();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 3 – Built-in Variant Gallery
  // ---------------------------------------------------------------------------

  Widget _buildVariantGallery(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Built-in Variant Gallery',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: kBuiltInVariantOptions.length,
          itemBuilder: (context, index) {
            final entry = kBuiltInVariantOptions[index];
            final variant = entry.$1;
            final label = entry.$2;
            final icon = entry.$3;

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 28,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: textTheme.labelMedium,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      variant.name,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
