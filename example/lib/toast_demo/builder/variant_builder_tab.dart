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
    required this.savedVariants,
    required this.onChanged,
  });

  /// The channels defined by the user.
  final List<ChannelModel> channels;

  /// List of custom variant names the user has registered.
  final List<String> registeredVariantNames;

  /// Saved toast design variants.
  final List<VariantModel> savedVariants;

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
        _buildSavedVariantsSection(colorScheme, textTheme),
        const SizedBox(height: 24),
        _buildRegisteredVariantsSection(colorScheme, textTheme),
        const SizedBox(height: 24),
        _buildPerChannelSection(colorScheme, textTheme),
        const SizedBox(height: 24),
        _buildVariantGallery(colorScheme, textTheme),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section 0 – Saved Toast Variants (CRUD)
  // ---------------------------------------------------------------------------

  /// Build the saved variants management section.
  Widget _buildSavedVariantsSection(
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
            Row(
              children: [
                Icon(Icons.bookmark_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Saved Toast Variants',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: 'Create a new toast variant from the builder',
                  child: FilledButton.icon(
                    onPressed: () {
                  
                      _showCreateVariantDialog(context);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Variant'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Save toast designs as reusable variants. Load them into the '
              'builder to edit, or assign them to channels.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.savedVariants.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.bookmark_border_rounded,
                        size: 48,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No saved variants yet',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create a variant to get started',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: widget.savedVariants.map((variant) {
                  return _buildVariantCard(variant, colorScheme, textTheme);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  /// Build a card for a single saved variant with actions and style preview.
  Widget _buildVariantCard(
    VariantModel variant,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    // Build a mini preview of the variant's style
    final hasVisibleStyle = variant.backgroundColor != null ||
        variant.useGradient ||
        variant.borderWidth > 0 ||
        variant.shadowBlur > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Style preview swatch
                  if (hasVisibleStyle)
                    Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: variant.useGradient ? null : variant.backgroundColor,
                        gradient: variant.useGradient &&
                            variant.gradientStartColor != null &&
                            variant.gradientEndColor != null
                            ? LinearGradient(
                                colors: [
                                  variant.gradientStartColor!,
                                  variant.gradientEndColor!,
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(
                          variant.cornerRadius.clamp(4.0, 12.0),
                        ),
                        border: variant.borderWidth > 0 && variant.borderColor != null
                            ? Border.all(
                                color: variant.borderColor!,
                                width: variant.borderWidth.clamp(1.0, 3.0),
                              )
                            : null,
                        boxShadow: variant.shadowBlur > 0
                            ? [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: variant.shadowBlur.clamp(2.0, 8.0),
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Icon(
                          variant.icon ?? Icons.notifications,
                          color: variant.accentColor ?? variant.textColor ?? Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  // Variant name and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variant.name,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (variant.description != null &&
                            variant.description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            variant.description!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: 'Load into builder to edit',
                        child: IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          onPressed: () {
                            _showEditVariantDialog(context, variant);
                          },
                        ),
                      ),
                      Tooltip(
                        message: 'Duplicate this variant',
                        child: IconButton(
                          icon: Icon(
                            Icons.content_copy_outlined,
                            size: 20,
                            color: colorScheme.secondary,
                          ),
                          onPressed: () => _duplicateVariant(variant),
                        ),
                      ),
                      Tooltip(
                        message: 'Delete this variant',
                        child: IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: colorScheme.error,
                          ),
                          onPressed: () => _deleteVariant(variant),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Variant metadata with style details
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Chip(
                    label: Text(
                      variant.toastType.name,
                      style: textTheme.labelSmall,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  if (variant.variant != null)
                    Chip(
                      label: Text(
                        _variantLabel(variant.variant),
                        style: textTheme.labelSmall,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (variant.assignedChannels.isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.link, size: 14),
                      label: Text(
                        '${variant.assignedChannels.length} channel(s)',
                        style: textTheme.labelSmall,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  // Style indicators
                  if (variant.shadowBlur > 0)
                    Chip(
                      avatar: Icon(Icons.blur_on, size: 14, color: colorScheme.tertiary),
                      label: Text(
                        'Shadow',
                        style: textTheme.labelSmall,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: colorScheme.tertiaryContainer.withAlpha(100),
                    ),
                  if (variant.useGradient)
                    Chip(
                      avatar: Icon(Icons.gradient, size: 14, color: colorScheme.secondary),
                      label: Text(
                        'Gradient',
                        style: textTheme.labelSmall,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: colorScheme.secondaryContainer.withAlpha(100),
                    ),
                  if (variant.showProgressBar)
                    Chip(
                      avatar: Icon(Icons.linear_scale, size: 14, color: colorScheme.primary),
                      label: Text(
                        'Progress',
                        style: textTheme.labelSmall,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: colorScheme.primaryContainer.withAlpha(100),
                    ),
                  if (variant.borderWidth > 0)
                    Chip(
                      avatar: const Icon(Icons.border_style, size: 14),
                      label: Text(
                        'Border',
                        style: textTheme.labelSmall,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
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
  // Variant CRUD Actions
  // ---------------------------------------------------------------------------

  void _showCreateVariantDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Variant'),
        content: const Text(
          'This feature will allow you to design a new toast variant using '
          'the interactive builder.\n\n'
          'Note: Full builder integration is in progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Create a basic variant as placeholder
              final newVariant = VariantModel(
                name: 'New Variant ${widget.savedVariants.length + 1}',
                toastType: ToastType.custom,
              );
              setState(() {
                widget.savedVariants.add(newVariant);
              });
              widget.onChanged();
            },
            child: const Text('Create Basic'),
          ),
        ],
      ),
    );
  }

  void _showEditVariantDialog(BuildContext context, VariantModel variant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Variant'),
        content: Text(
          'Edit "${variant.name}" in the interactive builder.\n\n'
          'Note: Full builder integration is in progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _duplicateVariant(VariantModel variant) {
    final duplicate = variant.copyWith(
      id: 'variant_${DateTime.now().millisecondsSinceEpoch}',
      name: '${variant.name} (Copy)',
      assignedChannels: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    setState(() {
      widget.savedVariants.add(duplicate);
    });
    widget.onChanged();
  }

  void _deleteVariant(VariantModel variant) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Variant'),
        content: Text(
          'Are you sure you want to delete "${variant.name}"?\n\n'
          'This will also unassign it from ${variant.assignedChannels.length} '
          'channel(s).',
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
          widget.savedVariants.remove(variant);
          // Unassign from all channels
          for (final channel in widget.channels) {
            channel.assignedVariantIds.remove(variant.id);
          }
        });
        widget.onChanged();
      }
    });
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
                  onPressed: () => _addVariantName(_variantNameController.text),
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
              // ignore: unnecessary_to_list_in_spreads
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
              const SizedBox(height: 16),
              // Saved Variants Assignment (Multiple)
              Row(
                children: [
                  Text(
                    'Assigned Saved Variants',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Assign multiple saved variants to this channel',
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (widget.savedVariants.isEmpty)
                Text(
                  'No saved variants available. Create one above.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...widget.savedVariants.map((variant) {
                      final isAssigned =
                          channel.assignedVariantIds.contains(variant.id);
                      return FilterChip(
                        label: Text(variant.name),
                        selected: isAssigned,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              channel.assignedVariantIds.add(variant.id);
                              // Also update variant's assigned channels list
                              if (!variant.assignedChannels
                                  .contains(channel.id)) {
                                variant.assignedChannels.add(channel.id);
                              }
                            } else {
                              channel.assignedVariantIds.remove(variant.id);
                              // Remove from variant's assigned channels
                              variant.assignedChannels.remove(channel.id);
                            }
                          });
                          widget.onChanged();
                        },
                      );
                    }),
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
