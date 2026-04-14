import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

import '../widgets/buttons/demo_button.dart';
import '../widgets/cards/feature_card.dart';
import '../widgets/see_code_button.dart';

/// An interactive screen where users can design their own toast by tweaking
/// title, message, icon, color, position, duration, corner radius, padding,
/// shadow, progress bar style, and dismiss behavior — then preview it live.
class ToastConfiguratorScreen extends StatefulWidget {
  const ToastConfiguratorScreen({super.key});

  @override
  State<ToastConfiguratorScreen> createState() =>
      _ToastConfiguratorScreenState();
}

class _ToastConfiguratorScreenState extends State<ToastConfiguratorScreen> {
  // ---------------------------------------------------------------------------
  // Configurable fields
  // ---------------------------------------------------------------------------

  final _titleCtrl = TextEditingController(text: 'Custom Toast');
  final _messageCtrl =
      TextEditingController(text: 'This is a fully customizable toast.');

  // Style
  Color _bgColor = const Color(0xFF1E293B);
  Color _accentColor = const Color(0xFF6366F1);
  double _cornerRadius = 16.0;
  double _padding = 16.0;
  double _shadowBlur = 12.0;
  double _duration = 4.0;

  // Icon
  int _selectedIconIdx = 0;
  static const _iconOptions = <(IconData, String)>[
    (Icons.check_circle, 'Check'),
    (Icons.error_outline, 'Error'),
    (Icons.warning_amber_rounded, 'Warning'),
    (Icons.info_outline, 'Info'),
    (Icons.rocket_launch, 'Rocket'),
    (Icons.auto_awesome, 'Sparkle'),
    (Icons.favorite, 'Heart'),
    (Icons.star, 'Star'),
  ];

  // Position
  ToastPosition _position = ToastPosition.top;
  static const _positionOptions = <(ToastPosition, String)>[
    (ToastPosition.top, 'Top'),
    (ToastPosition.topLeft, 'Top Left'),
    (ToastPosition.topRight, 'Top Right'),
    (ToastPosition.center, 'Center'),
    (ToastPosition.bottom, 'Bottom'),
    (ToastPosition.bottomLeft, 'Bottom Left'),
    (ToastPosition.bottomRight, 'Bottom Right'),
  ];

  // Progress bar
  bool _showProgress = false;

  // Dismiss
  bool _dismissible = true;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Preview
  // ---------------------------------------------------------------------------

  void _showPreview() {
    final title = _titleCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    final icon = _iconOptions[_selectedIconIdx].$1;
    final bgColor = _bgColor;
    final accent = _accentColor;
    final radius = _cornerRadius;
    final pad = _padding;
    final shadow = _shadowBlur;
    final showProg = _showProgress;
    final durationMs = (_duration * 1000).round();

    ToastKit.show(ToastEvent.custom(
      duration: Duration(milliseconds: durationMs),
      position: _position,
      dismissible: _dismissible,
      builder: (context, controller) {
        return _CustomPreviewToast(
          title: title.isEmpty ? 'Custom Toast' : title,
          message: message.isEmpty ? 'Your message here' : message,
          icon: icon,
          bgColor: bgColor,
          accentColor: accent,
          cornerRadius: radius,
          padding: pad,
          shadowBlur: shadow,
          showProgress: showProg,
          durationMs: durationMs,
          controller: controller,
        );
      },
    ));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Toast Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset to defaults',
            onPressed: _resetDefaults,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPreview,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Preview Toast'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          Text(
            'Design Your Toast',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Customize every detail and preview it live. '
            'This proves that ToastKit is a fully customizable toast engine.',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          _buildContentSection(),
          const SizedBox(height: 12),
          _buildIconSection(),
          const SizedBox(height: 12),
          _buildColorsSection(),
          const SizedBox(height: 12),
          _buildLayoutSection(),
          const SizedBox(height: 12),
          _buildPositionSection(),
          const SizedBox(height: 12),
          _buildBehaviorSection(),
          const SizedBox(height: 12),
          _buildLivePreviewCard(theme),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section builders
  // ---------------------------------------------------------------------------

  Widget _buildContentSection() {
    return FeatureCard(
      title: 'Content',
      subtitle: 'Title, message, and text',
      icon: Icons.text_fields,
      iconColor: Colors.blue,
      trailing: SeeCodeButton(
        title: 'Custom Toast Content',
        description: 'Pass title, message, and icon to a custom builder.',
        code: _contentCode,
      ),
      children: [
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.title),
          ),
          onChanged: (_) => setState(() {}),
        ),
        TextField(
          controller: _messageCtrl,
          decoration: const InputDecoration(
            labelText: 'Message',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.message),
          ),
          maxLines: 2,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildIconSection() {
    return FeatureCard(
      title: 'Icon',
      subtitle: 'Choose a toast icon',
      icon: Icons.emoji_symbols,
      iconColor: Colors.purple,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_iconOptions.length, (i) {
            final (icon, label) = _iconOptions[i];
            final selected = i == _selectedIconIdx;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 4),
                  Text(label),
                ],
              ),
              selected: selected,
              onSelected: (_) => setState(() => _selectedIconIdx = i),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildColorsSection() {
    return FeatureCard(
      title: 'Color Theme',
      subtitle: 'Background and accent color',
      icon: Icons.color_lens,
      iconColor: Colors.orange,
      children: [
        _ColorRow(
          label: 'Background',
          color: _bgColor,
          onChanged: (c) => setState(() => _bgColor = c),
          presets: const [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
            Color(0xFFFFFFFF),
            Color(0xFFF1F5F9),
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
        ),
        _ColorRow(
          label: 'Accent',
          color: _accentColor,
          onChanged: (c) => setState(() => _accentColor = c),
          presets: const [
            Color(0xFF6366F1),
            Color(0xFF10B981),
            Color(0xFFEF4444),
            Color(0xFFF59E0B),
            Color(0xFF3B82F6),
            Color(0xFFEC4899),
          ],
        ),
      ],
    );
  }

  Widget _buildLayoutSection() {
    return FeatureCard(
      title: 'Layout & Style',
      subtitle: 'Corner radius, padding, and shadow',
      icon: Icons.rounded_corner,
      iconColor: Colors.teal,
      trailing: SeeCodeButton(
        title: 'Layout Customization',
        description:
            'Control corner radius, padding, shadow, and progress bar.',
        code: _layoutCode,
      ),
      children: [
        _SliderRow(
          label: 'Corner Radius',
          value: _cornerRadius,
          min: 0,
          max: 32,
          divisions: 32,
          onChanged: (v) => setState(() => _cornerRadius = v),
        ),
        _SliderRow(
          label: 'Padding',
          value: _padding,
          min: 4,
          max: 32,
          divisions: 28,
          onChanged: (v) => setState(() => _padding = v),
        ),
        _SliderRow(
          label: 'Shadow Blur',
          value: _shadowBlur,
          min: 0,
          max: 30,
          divisions: 30,
          onChanged: (v) => setState(() => _shadowBlur = v),
        ),
      ],
    );
  }

  Widget _buildPositionSection() {
    return FeatureCard(
      title: 'Position',
      subtitle: 'Where the toast appears on screen',
      icon: Icons.open_with,
      iconColor: Colors.indigo,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _positionOptions.map((opt) {
            final (pos, label) = opt;
            return ChoiceChip(
              label: Text(label),
              selected: _position == pos,
              onSelected: (_) => setState(() => _position = pos),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBehaviorSection() {
    return FeatureCard(
      title: 'Behavior',
      subtitle: 'Duration, progress bar, and dismiss',
      icon: Icons.tune,
      iconColor: Colors.amber,
      children: [
        _SliderRow(
          label: 'Duration',
          value: _duration,
          min: 1,
          max: 10,
          divisions: 18,
          suffix: 's',
          onChanged: (v) => setState(() => _duration = v),
        ),
        SwitchListTile(
          title: const Text('Show progress bar'),
          subtitle: const Text('Countdown indicator at the bottom'),
          value: _showProgress,
          dense: true,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _showProgress = v),
        ),
        SwitchListTile(
          title: const Text('Swipe to dismiss'),
          subtitle: const Text('Allow swiping the toast away'),
          value: _dismissible,
          dense: true,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _dismissible = v),
        ),
      ],
    );
  }

  Widget _buildLivePreviewCard(ThemeData theme) {
    final title = _titleCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    final icon = _iconOptions[_selectedIconIdx].$1;
    final textColor =
        _bgColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return FeatureCard(
      title: 'Live Preview',
      subtitle: 'How your toast will look',
      icon: Icons.preview,
      iconColor: _accentColor,
      trailing: SeeCodeButton(
        title: 'Generated Code',
        description: 'Copy this code to recreate your custom toast.',
        code: _generateCode(),
      ),
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(_padding),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(_cornerRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: _shadowBlur,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, color: _accentColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title.isEmpty ? 'Custom Toast' : title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (message.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            message,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: textColor.withAlpha(180),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.close, size: 18, color: textColor.withAlpha(120)),
                ],
              ),
              if (_showProgress) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(_cornerRadius / 2),
                  child: LinearProgressIndicator(
                    value: 0.65,
                    minHeight: 4,
                    backgroundColor: _accentColor.withAlpha(40),
                    valueColor: AlwaysStoppedAnimation(_accentColor),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        DemoButton(
          label: 'Show This Toast',
          icon: Icons.play_arrow,
          color: _accentColor,
          onPressed: _showPreview,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _resetDefaults() {
    setState(() {
      _titleCtrl.text = 'Custom Toast';
      _messageCtrl.text = 'This is a fully customizable toast.';
      _bgColor = const Color(0xFF1E293B);
      _accentColor = const Color(0xFF6366F1);
      _cornerRadius = 16.0;
      _padding = 16.0;
      _shadowBlur = 12.0;
      _duration = 4.0;
      _selectedIconIdx = 0;
      _position = ToastPosition.top;
      _showProgress = false;
      _dismissible = true;
    });
  }

  String _generateCode() {
    final icon = _iconOptions[_selectedIconIdx].$2;
    final pos = _positionOptions
        .firstWhere((o) => o.$1 == _position)
        .$2;
    return '''ToastKit.show(ToastEvent.custom(
  duration: Duration(seconds: ${_duration.toStringAsFixed(1)}),
  position: ToastPosition.${_position.name},
  dismissible: $_dismissible,
  builder: (context, controller) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(${_padding.round()}),
      decoration: BoxDecoration(
        color: Color(0x${_bgColor.value.toRadixString(16).toUpperCase()}),
        borderRadius: BorderRadius.circular(${_cornerRadius.round()}),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: ${_shadowBlur.round()},
          ),
        ],
      ),
      child: Row(children: [
        Icon(Icons.$icon, color: Color(0x${_accentColor.value.toRadixString(16).toUpperCase()})),
        SizedBox(width: 12),
        Column(children: [
          Text('${_titleCtrl.text}'),
          Text('${_messageCtrl.text}'),
        ]),
      ]),
    );
  },
));

// Position: $pos
// Duration: ${_duration.toStringAsFixed(1)}s
// Progress bar: ${_showProgress ? 'yes' : 'no'}
// Dismissible: $_dismissible''';
  }
}

// =============================================================================
// Reusable row widgets
// =============================================================================

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.suffix = '',
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}$suffix',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.color,
    required this.onChanged,
    required this.presets,
  });

  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;
  final List<Color> presets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((c) {
            final selected = c.value == color.value;
            return GestureDetector(
              onTap: () => onChanged(c),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: c.withAlpha(100),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: selected
                    ? Icon(Icons.check, size: 16,
                        color: c.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// =============================================================================
// Custom Preview Toast (used inside the overlay)
// =============================================================================

class _CustomPreviewToast extends StatefulWidget {
  const _CustomPreviewToast({
    required this.title,
    required this.message,
    required this.icon,
    required this.bgColor,
    required this.accentColor,
    required this.cornerRadius,
    required this.padding,
    required this.shadowBlur,
    required this.showProgress,
    required this.durationMs,
    required this.controller,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color bgColor;
  final Color accentColor;
  final double cornerRadius;
  final double padding;
  final double shadowBlur;
  final bool showProgress;
  final int durationMs;
  final ToastController controller;

  @override
  State<_CustomPreviewToast> createState() => _CustomPreviewToastState();
}

class _CustomPreviewToastState extends State<_CustomPreviewToast>
    with SingleTickerProviderStateMixin {
  AnimationController? _progressCtrl;

  @override
  void initState() {
    super.initState();
    if (widget.showProgress) {
      _progressCtrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: widget.durationMs),
      )..forward();
    }
  }

  @override
  void dispose() {
    _progressCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.bgColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: widget.bgColor,
        borderRadius: BorderRadius.circular(widget.cornerRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: widget.shadowBlur,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(widget.padding),
            child: Row(
              children: [
                Icon(widget.icon, color: widget.accentColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.message,
                        style: TextStyle(
                          color: textColor.withAlpha(180),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: widget.controller.dismiss,
                  child: Icon(Icons.close, size: 18,
                      color: textColor.withAlpha(120)),
                ),
              ],
            ),
          ),
          if (widget.showProgress && _progressCtrl != null)
            AnimatedBuilder(
              animation: _progressCtrl!,
              builder: (_, __) {
                return ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(widget.cornerRadius),
                  ),
                  child: LinearProgressIndicator(
                    value: 1.0 - _progressCtrl!.value,
                    minHeight: 4,
                    backgroundColor: widget.accentColor.withAlpha(40),
                    valueColor: AlwaysStoppedAnimation(widget.accentColor),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// Code Strings
// =============================================================================

const _contentCode = '''// Customize title, message, and icon
ToastKit.show(ToastEvent.custom(
  builder: (context, controller) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Icon(Icons.check_circle, color: Color(0xFF6366F1)),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Custom Toast',
              style: TextStyle(color: Colors.white)),
            Text('Your message here',
              style: TextStyle(color: Colors.white70)),
          ],
        ),
      ]),
    );
  },
));''';

const _layoutCode = '''// Control layout properties
Container(
  padding: EdgeInsets.all(16),      // configurable padding
  decoration: BoxDecoration(
    color: bgColor,
    borderRadius: BorderRadius.circular(16), // corner radius
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha(30),
        blurRadius: 12,             // shadow intensity
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Column(children: [
    // Content row...
    if (showProgress)
      LinearProgressIndicator(    // optional progress bar
        value: 1.0 - animCtrl.value,
        minHeight: 4,
        backgroundColor: accent.withAlpha(40),
        valueColor: AlwaysStoppedAnimation(accent),
      ),
  ]),
)''';
