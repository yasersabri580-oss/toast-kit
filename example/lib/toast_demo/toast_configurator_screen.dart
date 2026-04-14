import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toast_kit/toast_kit.dart';

import '../widgets/code_viewer_modal.dart';

// =============================================================================
// Toast Configurator — A Modern, Fully Interactive Toast Builder
// =============================================================================

/// An advanced interactive screen where users can design, preview, and export
/// any conceivable toast notification. Every parameter — type, variant,
/// animation, position, priority, colors, layout, actions, and more — is
/// exposed through a sleek, tabbed interface with preset templates and a
/// real-time live preview.
class ToastConfiguratorScreen extends StatefulWidget {
  const ToastConfiguratorScreen({super.key});

  @override
  State<ToastConfiguratorScreen> createState() =>
      _ToastConfiguratorScreenState();
}

class _ToastConfiguratorScreenState extends State<ToastConfiguratorScreen>
    with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Tab controller
  // ---------------------------------------------------------------------------
  late final TabController _tabController;

  // ---------------------------------------------------------------------------
  // Content
  // ---------------------------------------------------------------------------
  final _titleCtrl = TextEditingController(text: 'Custom Toast');
  final _messageCtrl =
      TextEditingController(text: 'This is a fully customizable toast.');

  // ---------------------------------------------------------------------------
  // Toast type
  // ---------------------------------------------------------------------------
  ToastType _toastType = ToastType.custom;

  // ---------------------------------------------------------------------------
  // Icon
  // ---------------------------------------------------------------------------
  int _selectedIconIdx = 0;
  static const _iconOptions = <(IconData, String, String)>[
    (Icons.check_circle, 'Check', 'check_circle'),
    (Icons.error_outline, 'Error', 'error_outline'),
    (Icons.warning_amber_rounded, 'Warning', 'warning_amber_rounded'),
    (Icons.info_outline, 'Info', 'info_outline'),
    (Icons.rocket_launch, 'Rocket', 'rocket_launch'),
    (Icons.auto_awesome, 'Sparkle', 'auto_awesome'),
    (Icons.favorite, 'Heart', 'favorite'),
    (Icons.star, 'Star', 'star'),
    (Icons.notifications_active, 'Bell', 'notifications_active'),
    (Icons.bolt, 'Bolt', 'bolt'),
    (Icons.celebration, 'Party', 'celebration'),
    (Icons.shield, 'Shield', 'shield'),
  ];

  // ---------------------------------------------------------------------------
  // Style
  // ---------------------------------------------------------------------------
  Color _bgColor = const Color(0xFF1E293B);
  Color _accentColor = const Color(0xFF6366F1);
  double _cornerRadius = 16.0;
  double _padding = 16.0;
  double _shadowBlur = 12.0;
  double _fontSize = 14.0;
  double _iconSize = 24.0;
  double _opacity = 1.0;
  double _borderWidth = 0.0;
  Color _borderColor = const Color(0xFF6366F1);
  bool _useGradientBg = false;
  Color _gradientEndColor = const Color(0xFF3B82F6);

  // ---------------------------------------------------------------------------
  // Animation
  // ---------------------------------------------------------------------------
  ToastAnimationType _animationType = ToastAnimationType.slideFromTop;
  static const _animationOptions = <(ToastAnimationType, String, IconData)>[
    (ToastAnimationType.fade, 'Fade', Icons.blur_on),
    (ToastAnimationType.slideFromTop, 'Slide Top', Icons.arrow_downward),
    (ToastAnimationType.slideFromBottom, 'Slide Bottom', Icons.arrow_upward),
    (ToastAnimationType.slideFromLeft, 'Slide Left', Icons.arrow_forward),
    (ToastAnimationType.slideFromRight, 'Slide Right', Icons.arrow_back),
    (ToastAnimationType.scale, 'Scale', Icons.zoom_out_map),
    (ToastAnimationType.bounce, 'Bounce', Icons.sports_basketball),
    (ToastAnimationType.elastic, 'Elastic', Icons.waves),
    (ToastAnimationType.spring, 'Spring', Icons.height),
    (ToastAnimationType.shake, 'Shake', Icons.vibration),
    (ToastAnimationType.blur, 'Blur', Icons.lens_blur),
    (ToastAnimationType.glow, 'Glow', Icons.light_mode),
  ];

  // ---------------------------------------------------------------------------
  // Position
  // ---------------------------------------------------------------------------
  ToastPosition _position = ToastPosition.top;
  static const _positionOptions = <(ToastPosition, String, IconData)>[
    (ToastPosition.top, 'Top', Icons.vertical_align_top),
    (ToastPosition.topLeft, 'Top Left', Icons.north_west),
    (ToastPosition.topRight, 'Top Right', Icons.north_east),
    (ToastPosition.center, 'Center', Icons.center_focus_strong),
    (ToastPosition.bottom, 'Bottom', Icons.vertical_align_bottom),
    (ToastPosition.bottomLeft, 'Bottom Left', Icons.south_west),
    (ToastPosition.bottomRight, 'Bottom Right', Icons.south_east),
  ];

  // ---------------------------------------------------------------------------
  // Behavior
  // ---------------------------------------------------------------------------
  double _duration = 4.0;
  bool _showProgress = false;
  bool _dismissible = true;
  bool _persistent = false;
  ToastPriority _priority = ToastPriority.normal;

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------
  bool _showActions = false;
  String _actionLabel = 'Undo';
  bool _showSecondAction = false;
  String _secondActionLabel = 'Details';

  // ---------------------------------------------------------------------------
  // Preset templates
  // ---------------------------------------------------------------------------
  static const _presets = <_PresetTemplate>[
    _PresetTemplate(
      name: 'Success',
      icon: Icons.check_circle,
      bgColor: Color(0xFF065F46),
      accentColor: Color(0xFF34D399),
      title: 'Success!',
      message: 'Operation completed successfully.',
      iconIdx: 0,
      animType: ToastAnimationType.slideFromTop,
      position: ToastPosition.top,
    ),
    _PresetTemplate(
      name: 'Error',
      icon: Icons.error,
      bgColor: Color(0xFF7F1D1D),
      accentColor: Color(0xFFF87171),
      title: 'Error',
      message: 'Something went wrong. Please try again.',
      iconIdx: 1,
      animType: ToastAnimationType.shake,
      position: ToastPosition.top,
    ),
    _PresetTemplate(
      name: 'Warning',
      icon: Icons.warning,
      bgColor: Color(0xFF78350F),
      accentColor: Color(0xFFFBBF24),
      title: 'Warning',
      message: 'Please check your input before continuing.',
      iconIdx: 2,
      animType: ToastAnimationType.bounce,
      position: ToastPosition.top,
    ),
    _PresetTemplate(
      name: 'Glassmorphic',
      icon: Icons.blur_on,
      bgColor: Color(0xCC1E293B),
      accentColor: Color(0xFF818CF8),
      title: 'Glass Toast',
      message: 'Beautiful frosted glass style notification.',
      iconIdx: 5,
      animType: ToastAnimationType.scale,
      position: ToastPosition.center,
      cornerRadius: 20,
      shadowBlur: 24,
    ),
    _PresetTemplate(
      name: 'Gradient',
      icon: Icons.gradient,
      bgColor: Color(0xFF6366F1),
      accentColor: Color(0xFFFFFFFF),
      title: 'Gradient Toast',
      message: 'Eye-catching gradient background.',
      iconIdx: 5,
      animType: ToastAnimationType.elastic,
      position: ToastPosition.bottom,
      useGradient: true,
      gradientEnd: Color(0xFFEC4899),
    ),
    _PresetTemplate(
      name: 'Minimal',
      icon: Icons.minimize,
      bgColor: Color(0xFFFFFFFF),
      accentColor: Color(0xFF1E293B),
      title: 'Minimal',
      message: 'Clean and simple.',
      iconIdx: 3,
      animType: ToastAnimationType.fade,
      position: ToastPosition.bottom,
      cornerRadius: 8,
      padding: 12,
      shadowBlur: 4,
    ),
    _PresetTemplate(
      name: 'Neon',
      icon: Icons.light_mode,
      bgColor: Color(0xFF0A0A0A),
      accentColor: Color(0xFF00FF88),
      title: 'Neon Glow',
      message: 'A vibrant, eye-catching neon style.',
      iconIdx: 9,
      animType: ToastAnimationType.glow,
      position: ToastPosition.top,
      borderWidth: 1.5,
      borderColor: Color(0xFF00FF88),
      shadowBlur: 20,
    ),
    _PresetTemplate(
      name: 'Urgent',
      icon: Icons.priority_high,
      bgColor: Color(0xFFDC2626),
      accentColor: Color(0xFFFFFFFF),
      title: 'Critical Alert',
      message: 'Immediate attention required!',
      iconIdx: 1,
      animType: ToastAnimationType.shake,
      position: ToastPosition.center,
      persistent: true,
      showActions: true,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Apply preset
  // ---------------------------------------------------------------------------
  void _applyPreset(_PresetTemplate preset) {
    setState(() {
      _titleCtrl.text = preset.title;
      _messageCtrl.text = preset.message;
      _bgColor = preset.bgColor;
      _accentColor = preset.accentColor;
      _selectedIconIdx = preset.iconIdx;
      _animationType = preset.animType;
      _position = preset.position;
      _cornerRadius = preset.cornerRadius;
      _padding = preset.padding;
      _shadowBlur = preset.shadowBlur;
      _useGradientBg = preset.useGradient;
      if (preset.useGradient) _gradientEndColor = preset.gradientEnd;
      _borderWidth = preset.borderWidth;
      _borderColor = preset.borderColor;
      _persistent = preset.persistent;
      _showActions = preset.showActions;
      _opacity = 1.0;
      _fontSize = 14.0;
      _iconSize = 24.0;
    });
    HapticFeedback.lightImpact();
  }

  // ---------------------------------------------------------------------------
  // Randomize
  // ---------------------------------------------------------------------------
  void _randomize() {
    final rng = Random();
    const colors = <Color>[
      Color(0xFF1E293B),
      Color(0xFF0F172A),
      Color(0xFF7F1D1D),
      Color(0xFF065F46),
      Color(0xFF78350F),
      Color(0xFF1E1B4B),
      Color(0xFF0C4A6E),
      Color(0xFF4A044E),
      Color(0xFF0A0A0A),
      Color(0xFFFFFFFF),
    ];
    const accents = <Color>[
      Color(0xFF6366F1),
      Color(0xFF10B981),
      Color(0xFFEF4444),
      Color(0xFFF59E0B),
      Color(0xFF3B82F6),
      Color(0xFFEC4899),
      Color(0xFF8B5CF6),
      Color(0xFF14B8A6),
      Color(0xFF00FF88),
      Color(0xFFF97316),
    ];
    setState(() {
      _bgColor = colors[rng.nextInt(colors.length)];
      _accentColor = accents[rng.nextInt(accents.length)];
      _selectedIconIdx = rng.nextInt(_iconOptions.length);
      _animationType =
          _animationOptions[rng.nextInt(_animationOptions.length)].$1;
      _position = _positionOptions[rng.nextInt(_positionOptions.length)].$1;
      _cornerRadius = (rng.nextInt(25) + 4).toDouble();
      _padding = (rng.nextInt(20) + 8).toDouble();
      _shadowBlur = (rng.nextInt(24) + 2).toDouble();
      _useGradientBg = rng.nextBool();
      if (_useGradientBg) {
        _gradientEndColor = accents[rng.nextInt(accents.length)];
      }
      _borderWidth = rng.nextBool() ? (rng.nextInt(3) + 1).toDouble() : 0;
      if (_borderWidth > 0) _borderColor = _accentColor;
    });
    HapticFeedback.mediumImpact();
  }

  // ---------------------------------------------------------------------------
  // Show preview
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
    final useGrad = _useGradientBg;
    final gradEnd = _gradientEndColor;
    final bw = _borderWidth;
    final bc = _borderColor;
    final fs = _fontSize;
    final iSize = _iconSize;
    final opac = _opacity;
    final hasActions = _showActions;
    final actionLbl = _actionLabel;
    final hasSecond = _showSecondAction;
    final secondLbl = _secondActionLabel;

    ToastKit.show(ToastEvent.custom(
      duration: _persistent ? null : Duration(milliseconds: durationMs),
      position: _position,
      animation: _animationType,
      dismissible: _dismissible,
      persistent: _persistent,
      priority: _priority,
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
          useGradient: useGrad,
          gradientEndColor: gradEnd,
          borderWidth: bw,
          borderColor: bc,
          fontSize: fs,
          iconSize: iSize,
          opacity: opac,
          showActions: hasActions,
          actionLabel: actionLbl,
          showSecondAction: hasSecond,
          secondActionLabel: secondLbl,
        );
      },
    ));
  }

  // ---------------------------------------------------------------------------
  // Reset
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
      _fontSize = 14.0;
      _iconSize = 24.0;
      _opacity = 1.0;
      _borderWidth = 0.0;
      _borderColor = const Color(0xFF6366F1);
      _useGradientBg = false;
      _gradientEndColor = const Color(0xFF3B82F6);
      _duration = 4.0;
      _selectedIconIdx = 0;
      _position = ToastPosition.top;
      _animationType = ToastAnimationType.slideFromTop;
      _showProgress = false;
      _dismissible = true;
      _persistent = false;
      _priority = ToastPriority.normal;
      _toastType = ToastType.custom;
      _showActions = false;
      _actionLabel = 'Undo';
      _showSecondAction = false;
      _secondActionLabel = 'Details';
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            leading: const BackButton(),
            actions: [
              IconButton(
                icon: const Icon(Icons.casino_outlined),
                tooltip: 'Randomize',
                onPressed: _randomize,
              ),
              IconButton(
                icon: const Icon(Icons.restart_alt),
                tooltip: 'Reset defaults',
                onPressed: _resetDefaults,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cs.primaryContainer,
                      cs.tertiaryContainer,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(60, 16, 16, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.build_circle,
                                size: 28, color: cs.primary),
                            const SizedBox(width: 10),
                            Text(
                              'Toast Builder',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Design any toast you can imagine — customize every '
                          'pixel, preview live, and export production-ready code.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onPrimaryContainer.withAlpha(180),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(icon: Icon(Icons.edit_note, size: 18), text: 'Content'),
                Tab(icon: Icon(Icons.palette, size: 18), text: 'Style'),
                Tab(
                    icon: Icon(Icons.animation, size: 18),
                    text: 'Animation'),
                Tab(icon: Icon(Icons.tune, size: 18), text: 'Behavior'),
                Tab(icon: Icon(Icons.preview, size: 18), text: 'Preview'),
              ],
            ),
          ),
        ],
        body: Column(
          children: [
            // Preset gallery
            _buildPresetGallery(theme),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildContentTab(theme),
                  _buildStyleTab(theme),
                  _buildAnimationTab(theme),
                  _buildBehaviorTab(theme),
                  _buildPreviewTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPreview,
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Preview Toast'),
      ),
    );
  }

  // ===========================================================================
  // Preset gallery
  // ===========================================================================

  Widget _buildPresetGallery(ThemeData theme) {
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withAlpha(60)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.auto_fix_high, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Text(
                  'Quick Templates',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _presets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final preset = _presets[i];
                return ActionChip(
                  avatar: Icon(preset.icon, size: 16),
                  label: Text(preset.name),
                  onPressed: () => _applyPreset(preset),
                  side: BorderSide(color: cs.outlineVariant.withAlpha(80)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Tab 1: Content
  // ===========================================================================

  Widget _buildContentTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        const _SectionHeader(
            icon: Icons.category, title: 'Toast Type', color: Colors.indigo),
        const SizedBox(height: 8),
        _buildToastTypeChips(),
        const SizedBox(height: 20),
        const _SectionHeader(
            icon: Icons.text_fields,
            title: 'Text Content',
            color: Colors.blue),
        const SizedBox(height: 8),
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Title',
            prefixIcon: Icon(Icons.title),
            hintText: 'Enter toast title\u2026',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _messageCtrl,
          decoration: const InputDecoration(
            labelText: 'Message',
            prefixIcon: Icon(Icons.message),
            hintText: 'Enter toast message\u2026',
          ),
          maxLines: 3,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        const _SectionHeader(
            icon: Icons.emoji_symbols, title: 'Icon', color: Colors.purple),
        const SizedBox(height: 8),
        _buildIconGrid(theme),
        const SizedBox(height: 12),
        _ModernSliderRow(
          label: 'Icon Size',
          value: _iconSize,
          min: 16,
          max: 40,
          divisions: 24,
          suffix: 'px',
          accentColor: _accentColor,
          onChanged: (v) => setState(() => _iconSize = v),
        ),
        const SizedBox(height: 20),
        const _SectionHeader(
          icon: Icons.touch_app,
          title: 'Action Buttons',
          color: Colors.deepOrange,
        ),
        const SizedBox(height: 8),
        _buildActionsConfig(theme),
      ],
    );
  }

  Widget _buildToastTypeChips() {
    const types = <(ToastType, String, IconData, Color)>[
      (ToastType.custom, 'Custom', Icons.build, Color(0xFF6366F1)),
      (ToastType.success, 'Success', Icons.check_circle, Color(0xFF10B981)),
      (ToastType.error, 'Error', Icons.error, Color(0xFFEF4444)),
      (ToastType.warning, 'Warning', Icons.warning, Color(0xFFF59E0B)),
      (ToastType.info, 'Info', Icons.info, Color(0xFF3B82F6)),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((t) {
        final (type, label, icon, color) = t;
        final selected = _toastType == type;
        return ChoiceChip(
          avatar: Icon(icon, size: 16, color: selected ? Colors.white : color),
          label: Text(label),
          selected: selected,
          selectedColor: color,
          labelStyle: selected ? const TextStyle(color: Colors.white) : null,
          onSelected: (_) => setState(() => _toastType = type),
        );
      }).toList(),
    );
  }

  Widget _buildIconGrid(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_iconOptions.length, (i) {
        final (icon, label, _) = _iconOptions[i];
        final selected = i == _selectedIconIdx;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _selectedIconIdx = i),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? _accentColor.withAlpha(30)
                    : theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? _accentColor : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 18, color: selected ? _accentColor : null),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? _accentColor : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildActionsConfig(ThemeData theme) {
    return _ModernCard(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Show action button'),
            subtitle: const Text('Add interactive buttons to your toast'),
            value: _showActions,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _showActions = v),
          ),
          if (_showActions) ...[
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Primary action label',
                prefixIcon: Icon(Icons.label),
                isDense: true,
              ),
              controller: TextEditingController(text: _actionLabel),
              onChanged: (v) => _actionLabel = v,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Second action'),
              value: _showSecondAction,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _showSecondAction = v),
            ),
            if (_showSecondAction) ...[
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Second action label',
                  prefixIcon: Icon(Icons.label_outline),
                  isDense: true,
                ),
                controller: TextEditingController(text: _secondActionLabel),
                onChanged: (v) => _secondActionLabel = v,
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // Tab 2: Style
  // ===========================================================================

  Widget _buildStyleTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        const _SectionHeader(
            icon: Icons.color_lens, title: 'Colors', color: Colors.orange),
        const SizedBox(height: 8),
        _buildColorPickers(theme),
        const SizedBox(height: 20),
        const _SectionHeader(
            icon: Icons.gradient,
            title: 'Gradient Background',
            color: Colors.pink),
        const SizedBox(height: 8),
        _buildGradientConfig(theme),
        const SizedBox(height: 20),
        const _SectionHeader(
            icon: Icons.rounded_corner,
            title: 'Layout & Shape',
            color: Colors.teal),
        const SizedBox(height: 8),
        _buildLayoutSliders(),
        const SizedBox(height: 20),
        const _SectionHeader(
            icon: Icons.border_style,
            title: 'Border',
            color: Colors.blueGrey),
        const SizedBox(height: 8),
        _buildBorderConfig(),
        const SizedBox(height: 20),
        const _SectionHeader(
            icon: Icons.text_format,
            title: 'Typography',
            color: Colors.deepPurple),
        const SizedBox(height: 8),
        _ModernSliderRow(
          label: 'Font Size',
          value: _fontSize,
          min: 10,
          max: 22,
          divisions: 24,
          suffix: 'px',
          accentColor: _accentColor,
          onChanged: (v) => setState(() => _fontSize = v),
        ),
        const SizedBox(height: 8),
        _ModernSliderRow(
          label: 'Opacity',
          value: _opacity,
          min: 0.3,
          max: 1.0,
          divisions: 14,
          accentColor: _accentColor,
          onChanged: (v) => setState(() => _opacity = v),
        ),
      ],
    );
  }

  Widget _buildColorPickers(ThemeData theme) {
    return _ModernCard(
      child: Column(
        children: [
          _ModernColorRow(
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
              Color(0xFF0A0A0A),
              Color(0xFF1E1B4B),
            ],
          ),
          const Divider(height: 20),
          _ModernColorRow(
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
              Color(0xFF8B5CF6),
              Color(0xFF14B8A6),
              Color(0xFF00FF88),
              Color(0xFFF97316),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradientConfig(ThemeData theme) {
    return _ModernCard(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Enable gradient background'),
            subtitle: const Text('Two-color gradient fill'),
            value: _useGradientBg,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _useGradientBg = v),
          ),
          if (_useGradientBg) ...[
            const SizedBox(height: 8),
            // Preview
            Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_bgColor, _gradientEndColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            _ModernColorRow(
              label: 'Gradient End',
              color: _gradientEndColor,
              onChanged: (c) => setState(() => _gradientEndColor = c),
              presets: const [
                Color(0xFF3B82F6),
                Color(0xFFEC4899),
                Color(0xFF8B5CF6),
                Color(0xFF10B981),
                Color(0xFFF59E0B),
                Color(0xFF14B8A6),
                Color(0xFFEF4444),
                Color(0xFF6366F1),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLayoutSliders() {
    return _ModernCard(
      child: Column(
        children: [
          _ModernSliderRow(
            label: 'Corner Radius',
            value: _cornerRadius,
            min: 0,
            max: 32,
            divisions: 32,
            suffix: 'px',
            accentColor: _accentColor,
            onChanged: (v) => setState(() => _cornerRadius = v),
          ),
          const SizedBox(height: 4),
          _ModernSliderRow(
            label: 'Padding',
            value: _padding,
            min: 4,
            max: 32,
            divisions: 28,
            suffix: 'px',
            accentColor: _accentColor,
            onChanged: (v) => setState(() => _padding = v),
          ),
          const SizedBox(height: 4),
          _ModernSliderRow(
            label: 'Shadow Blur',
            value: _shadowBlur,
            min: 0,
            max: 30,
            divisions: 30,
            suffix: 'px',
            accentColor: _accentColor,
            onChanged: (v) => setState(() => _shadowBlur = v),
          ),
        ],
      ),
    );
  }

  Widget _buildBorderConfig() {
    return _ModernCard(
      child: Column(
        children: [
          _ModernSliderRow(
            label: 'Border Width',
            value: _borderWidth,
            min: 0,
            max: 4,
            divisions: 8,
            suffix: 'px',
            accentColor: _accentColor,
            onChanged: (v) => setState(() => _borderWidth = v),
          ),
          if (_borderWidth > 0) ...[
            const SizedBox(height: 8),
            _ModernColorRow(
              label: 'Border Color',
              color: _borderColor,
              onChanged: (c) => setState(() => _borderColor = c),
              presets: [
                _accentColor,
                const Color(0xFFFFFFFF),
                const Color(0xFF000000),
                const Color(0xFF6366F1),
                const Color(0xFF10B981),
                const Color(0xFFEF4444),
                const Color(0xFF00FF88),
                const Color(0xFFF59E0B),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // Tab 3: Animation
  // ===========================================================================

  Widget _buildAnimationTab(ThemeData theme) {
    final cs = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        const _SectionHeader(
            icon: Icons.animation,
            title: 'Enter Animation',
            color: Colors.deepPurple),
        const SizedBox(height: 8),
        _buildAnimationGrid(theme),
        const SizedBox(height: 20),
        const _SectionHeader(
            icon: Icons.open_with,
            title: 'Screen Position',
            color: Colors.indigo),
        const SizedBox(height: 8),
        _buildPositionPicker(theme),
        const SizedBox(height: 20),
        // Quick test
        _ModernCard(
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.play_circle_filled, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quick Animation Test',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tap an animation above then hit Preview to see it in action '
                'with your current configuration.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _showPreview,
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: Text(
                      'Test ${_animationOptions.firstWhere((a) => a.$1 == _animationType).$2} Animation'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimationGrid(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _animationOptions.map((opt) {
        final (type, label, icon) = opt;
        final selected = _animationType == type;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _animationType = type),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary.withAlpha(20)
                    : theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon,
                      size: 20,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? theme.colorScheme.primary : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPositionPicker(ThemeData theme) {
    final cs = theme.colorScheme;
    // Visual grid layout for positions
    return _ModernCard(
      child: Column(
        children: [
          // 3x3 grid representation
          AspectRatio(
            aspectRatio: 1.5,
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withAlpha(60),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant.withAlpha(80)),
              ),
              child: Stack(
                children: [
                  // Screen mockup label
                  Center(
                    child: Text(
                      'SCREEN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: cs.outlineVariant,
                      ),
                    ),
                  ),
                  // Position dots
                  ..._positionOptions.map((opt) {
                    final (pos, label, icon) = opt;
                    final selected = _position == pos;
                    final alignment = _positionToAlignment(pos);
                    return Align(
                      alignment: alignment,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => setState(() => _position = pos),
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: selected
                                    ? cs.primary
                                    : cs.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: cs.primary.withAlpha(60),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon,
                                      size: 12,
                                      color: selected
                                          ? cs.onPrimary
                                          : cs.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: selected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: selected
                                          ? cs.onPrimary
                                          : cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Alignment _positionToAlignment(ToastPosition pos) {
    switch (pos) {
      case ToastPosition.top:
        return Alignment.topCenter;
      case ToastPosition.topLeft:
        return Alignment.topLeft;
      case ToastPosition.topRight:
        return Alignment.topRight;
      case ToastPosition.center:
        return Alignment.center;
      case ToastPosition.centerLeft:
        return Alignment.centerLeft;
      case ToastPosition.centerRight:
        return Alignment.centerRight;
      case ToastPosition.bottom:
        return Alignment.bottomCenter;
      case ToastPosition.bottomLeft:
        return Alignment.bottomLeft;
      case ToastPosition.bottomRight:
        return Alignment.bottomRight;
    }
  }

  // ===========================================================================
  // Tab 4: Behavior
  // ===========================================================================

  Widget _buildBehaviorTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        const _SectionHeader(
            icon: Icons.timer,
            title: 'Duration & Timing',
            color: Colors.amber),
        const SizedBox(height: 8),
        _ModernCard(
          child: Column(
            children: [
              _ModernSliderRow(
                label: 'Duration',
                value: _duration,
                min: 1,
                max: 15,
                divisions: 28,
                suffix: 's',
                accentColor: _accentColor,
                onChanged: (v) => setState(() => _duration = v),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                title: const Text('Persistent'),
                subtitle:
                    const Text('Toast stays until manually dismissed'),
                value: _persistent,
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _persistent = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _SectionHeader(
            icon: Icons.linear_scale,
            title: 'Progress Bar',
            color: Colors.green),
        const SizedBox(height: 8),
        _ModernCard(
          child: SwitchListTile(
            title: const Text('Show progress bar'),
            subtitle: const Text('Countdown indicator at the bottom'),
            value: _showProgress,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _showProgress = v),
          ),
        ),
        const SizedBox(height: 20),
        const _SectionHeader(
            icon: Icons.swipe,
            title: 'Dismiss Behavior',
            color: Colors.red),
        const SizedBox(height: 8),
        _ModernCard(
          child: SwitchListTile(
            title: const Text('Swipe to dismiss'),
            subtitle: const Text('Allow swiping the toast away'),
            value: _dismissible,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _dismissible = v),
          ),
        ),
        const SizedBox(height: 20),
        const _SectionHeader(
            icon: Icons.low_priority,
            title: 'Priority',
            color: Colors.deepOrange),
        const SizedBox(height: 8),
        _buildPriorityChips(),
      ],
    );
  }

  Widget _buildPriorityChips() {
    const priorities = <(ToastPriority, String, IconData, Color)>[
      (ToastPriority.low, 'Low', Icons.arrow_downward, Color(0xFF94A3B8)),
      (ToastPriority.normal, 'Normal', Icons.remove, Color(0xFF3B82F6)),
      (ToastPriority.high, 'High', Icons.arrow_upward, Color(0xFFF59E0B)),
      (
        ToastPriority.urgent,
        'Urgent',
        Icons.priority_high,
        Color(0xFFEF4444)
      ),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: priorities.map((p) {
        final (priority, label, icon, color) = p;
        final selected = _priority == priority;
        return ChoiceChip(
          avatar: Icon(icon, size: 16, color: selected ? Colors.white : color),
          label: Text(label),
          selected: selected,
          selectedColor: color,
          labelStyle: selected ? const TextStyle(color: Colors.white) : null,
          onSelected: (_) => setState(() => _priority = priority),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // Tab 5: Preview & Export
  // ===========================================================================

  Widget _buildPreviewTab(ThemeData theme) {
    final cs = theme.colorScheme;
    final title = _titleCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    final icon = _iconOptions[_selectedIconIdx].$1;
    final textColor =
        _bgColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _SectionHeader(
            icon: Icons.preview,
            title: 'Live Preview',
            color: _accentColor),
        const SizedBox(height: 8),
        // Live preview card
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withAlpha(40),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withAlpha(60)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Mock toast
              Opacity(
                opacity: _opacity,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(_padding),
                  decoration: BoxDecoration(
                    color: _useGradientBg ? null : _bgColor,
                    gradient: _useGradientBg
                        ? LinearGradient(
                            colors: [_bgColor, _gradientEndColor],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(_cornerRadius),
                    border: _borderWidth > 0
                        ? Border.all(
                            color: _borderColor, width: _borderWidth)
                        : null,
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
                          Icon(icon, color: _accentColor, size: _iconSize),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title.isEmpty ? 'Custom Toast' : title,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: _fontSize,
                                  ),
                                ),
                                if (message.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    message,
                                    style: TextStyle(
                                      color: textColor.withAlpha(180),
                                      fontSize: _fontSize - 1,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(Icons.close,
                              size: 18, color: textColor.withAlpha(120)),
                        ],
                      ),
                      if (_showActions) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: _accentColor,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(_actionLabel,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                            if (_showSecondAction) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      textColor.withAlpha(180),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(_secondActionLabel),
                              ),
                            ],
                          ],
                        ),
                      ],
                      if (_showProgress) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(_cornerRadius / 2),
                          child: LinearProgressIndicator(
                            value: 0.65,
                            minHeight: 4,
                            backgroundColor: _accentColor.withAlpha(40),
                            valueColor:
                                AlwaysStoppedAnimation(_accentColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _showPreview,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Show This Toast'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Config summary
        const _SectionHeader(
            icon: Icons.summarize,
            title: 'Configuration Summary',
            color: Colors.blueGrey),
        const SizedBox(height: 8),
        _buildConfigSummary(theme),
        const SizedBox(height: 20),
        // Export code
        _SectionHeader(
            icon: Icons.code, title: 'Generated Code', color: cs.primary),
        const SizedBox(height: 8),
        _buildCodeExport(theme),
      ],
    );
  }

  Widget _buildConfigSummary(ThemeData theme) {
    final cs = theme.colorScheme;
    final animName = _animationOptions
        .firstWhere((a) => a.$1 == _animationType)
        .$2;
    final posName = _positionOptions
        .firstWhere((p) => p.$1 == _position)
        .$2;

    final items = <(String, String, IconData)>[
      ('Position', posName, Icons.open_with),
      ('Animation', animName, Icons.animation),
      (
        'Duration',
        _persistent
            ? 'Persistent'
            : '${_duration.toStringAsFixed(1)}s',
        Icons.timer,
      ),
      ('Radius', '${_cornerRadius.round()}px', Icons.rounded_corner),
      ('Padding', '${_padding.round()}px', Icons.padding),
      ('Shadow', '${_shadowBlur.round()}px', Icons.blur_on),
      ('Font', '${_fontSize.round()}px', Icons.text_format),
      ('Opacity', '${(_opacity * 100).round()}%', Icons.opacity),
      ('Progress', _showProgress ? 'Yes' : 'No', Icons.linear_scale),
      ('Dismiss', _dismissible ? 'Swipe' : 'Locked', Icons.swipe),
      ('Gradient', _useGradientBg ? 'Yes' : 'No', Icons.gradient),
      (
        'Border',
        _borderWidth > 0
            ? '${_borderWidth.toStringAsFixed(1)}px'
            : 'None',
        Icons.border_style,
      ),
      ('Actions', _showActions ? _actionLabel : 'None', Icons.touch_app),
      (
        'Priority',
        _priority.name[0].toUpperCase() + _priority.name.substring(1),
        Icons.low_priority,
      ),
    ];

    return _ModernCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          final (label, value, icon) = item;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withAlpha(80),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: cs.primary),
                const SizedBox(width: 6),
                Text('$label: ',
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCodeExport(ThemeData theme) {
    final cs = theme.colorScheme;
    final code = _generateCode();
    return _ModernCard(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Color(0xFFCDD6F4),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Code copied to clipboard!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy Code'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => CodeViewerModal.show(
                    context: context,
                    title: 'Generated Toast Code',
                    description:
                        'Copy this code to recreate your custom toast.',
                    code: code,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fullscreen, size: 18, color: cs.primary),
                      const SizedBox(width: 6),
                      Text('Full View',
                          style: TextStyle(color: cs.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Code generation
  // ---------------------------------------------------------------------------

  String _generateCode() {
    final iconName = _iconOptions[_selectedIconIdx].$3;
    final bgHex =
        _bgColor.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    final accentHex =
        _accentColor.value.toRadixString(16).padLeft(8, '0').toUpperCase();

    final buf = StringBuffer();
    buf.writeln('ToastKit.show(ToastEvent.custom(');
    if (_persistent) {
      buf.writeln('  persistent: true,');
    } else {
      buf.writeln(
          '  duration: Duration(milliseconds: ${(_duration * 1000).round()}),');
    }
    buf.writeln('  position: ToastPosition.${_position.name},');
    buf.writeln('  animation: ToastAnimationType.${_animationType.name},');
    buf.writeln('  dismissible: $_dismissible,');
    buf.writeln('  builder: (context, controller) {');
    buf.writeln('    return Opacity(');
    buf.writeln('      opacity: ${_opacity.toStringAsFixed(2)},');
    buf.writeln('      child: Container(');
    buf.writeln(
        '        margin: const EdgeInsets.symmetric(horizontal: 16),');
    buf.writeln('        padding: EdgeInsets.all(${_padding.round()}),');
    buf.writeln('        decoration: BoxDecoration(');

    if (_useGradientBg) {
      final gradHex = _gradientEndColor.value
          .toRadixString(16)
          .padLeft(8, '0')
          .toUpperCase();
      buf.writeln('          gradient: LinearGradient(');
      buf.writeln(
          '            colors: [Color(0x$bgHex), Color(0x$gradHex)],');
      buf.writeln('          ),');
    } else {
      buf.writeln('          color: Color(0x$bgHex),');
    }

    buf.writeln(
        '          borderRadius: BorderRadius.circular(${_cornerRadius.round()}),');

    if (_borderWidth > 0) {
      final borderHex = _borderColor.value
          .toRadixString(16)
          .padLeft(8, '0')
          .toUpperCase();
      buf.writeln('          border: Border.all(');
      buf.writeln('            color: Color(0x$borderHex),');
      buf.writeln(
          '            width: ${_borderWidth.toStringAsFixed(1)},');
      buf.writeln('          ),');
    }

    buf.writeln('          boxShadow: [');
    buf.writeln('            BoxShadow(');
    buf.writeln('              color: Colors.black.withAlpha(30),');
    buf.writeln('              blurRadius: ${_shadowBlur.round()},');
    buf.writeln('            ),');
    buf.writeln('          ],');
    buf.writeln('        ),');
    buf.writeln('        child: Row(children: [');
    buf.writeln(
        '          Icon(Icons.$iconName, color: Color(0x$accentHex), size: ${_iconSize.round()}),');
    buf.writeln('          SizedBox(width: 12),');
    buf.writeln('          Expanded(');
    buf.writeln('            child: Column(');
    buf.writeln(
        '              crossAxisAlignment: CrossAxisAlignment.start,');
    buf.writeln('              mainAxisSize: MainAxisSize.min,');
    buf.writeln('              children: [');
    buf.writeln(
        "                Text('${_titleCtrl.text}', style: TextStyle(fontSize: ${_fontSize.round()})),");
    buf.writeln(
        "                Text('${_messageCtrl.text}', style: TextStyle(fontSize: ${(_fontSize - 1).round()})),");
    buf.writeln('              ],');
    buf.writeln('            ),');
    buf.writeln('          ),');
    buf.writeln('        ]),');
    buf.writeln('      ),');
    buf.writeln('    );');
    buf.writeln('  },');
    buf.writeln('));');
    return buf.toString().trimRight();
  }
}

// =============================================================================
// Preset template data class
// =============================================================================

class _PresetTemplate {
  const _PresetTemplate({
    required this.name,
    required this.icon,
    required this.bgColor,
    required this.accentColor,
    required this.title,
    required this.message,
    required this.iconIdx,
    required this.animType,
    required this.position,
    this.cornerRadius = 16,
    this.padding = 16,
    this.shadowBlur = 12,
    this.useGradient = false,
    this.gradientEnd = const Color(0xFF3B82F6),
    this.borderWidth = 0,
    this.borderColor = const Color(0xFF6366F1),
    this.persistent = false,
    this.showActions = false,
  });

  final String name;
  final IconData icon;
  final Color bgColor;
  final Color accentColor;
  final String title;
  final String message;
  final int iconIdx;
  final ToastAnimationType animType;
  final ToastPosition position;
  final double cornerRadius;
  final double padding;
  final double shadowBlur;
  final bool useGradient;
  final Color gradientEnd;
  final double borderWidth;
  final Color borderColor;
  final bool persistent;
  final bool showActions;
}

// =============================================================================
// Modern reusable widgets
// =============================================================================

/// A section header with icon, title, and accent color.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
        ),
      ],
    );
  }
}

/// A subtle card container for grouped controls.
class _ModernCard extends StatelessWidget {
  const _ModernCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(40),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withAlpha(50)),
      ),
      child: child,
    );
  }
}

/// A modern slider row with label, value, and accent color.
class _ModernSliderRow extends StatelessWidget {
  const _ModernSliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.suffix = '',
    this.accentColor,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String suffix;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style:
                  TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accentColor ?? cs.primary,
              thumbColor: accentColor ?? cs.primary,
              overlayColor: (accentColor ?? cs.primary).withAlpha(30),
              inactiveTrackColor:
                  (accentColor ?? cs.primary).withAlpha(40),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        Container(
          width: 50,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withAlpha(80),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}$suffix',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// A modern color picker row.
class _ModernColorRow extends StatelessWidget {
  const _ModernColorRow({
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
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: cs.outlineVariant, width: 1),
              ),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                )),
            const Spacer(),
            Text(
              '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((c) {
            final selected = c.value == color.value;
            return GestureDetector(
              onTap: () => onChanged(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? cs.onSurface
                        : cs.outlineVariant.withAlpha(60),
                    width: selected ? 2.5 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: c.withAlpha(80),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: selected
                    ? Icon(Icons.check,
                        size: 14,
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
    required this.useGradient,
    required this.gradientEndColor,
    required this.borderWidth,
    required this.borderColor,
    required this.fontSize,
    required this.iconSize,
    required this.opacity,
    required this.showActions,
    required this.actionLabel,
    required this.showSecondAction,
    required this.secondActionLabel,
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
  final bool useGradient;
  final Color gradientEndColor;
  final double borderWidth;
  final Color borderColor;
  final double fontSize;
  final double iconSize;
  final double opacity;
  final bool showActions;
  final String actionLabel;
  final bool showSecondAction;
  final String secondActionLabel;

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

    return Opacity(
      opacity: widget.opacity,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: widget.useGradient ? null : widget.bgColor,
          gradient: widget.useGradient
              ? LinearGradient(
                  colors: [widget.bgColor, widget.gradientEndColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          borderRadius: BorderRadius.circular(widget.cornerRadius),
          border: widget.borderWidth > 0
              ? Border.all(
                  color: widget.borderColor, width: widget.borderWidth)
              : null,
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(widget.icon,
                          color: widget.accentColor, size: widget.iconSize),
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
                                fontSize: widget.fontSize,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.message,
                              style: TextStyle(
                                color: textColor.withAlpha(180),
                                fontSize: widget.fontSize - 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.controller.dismiss,
                        child: Icon(Icons.close,
                            size: 18, color: textColor.withAlpha(120)),
                      ),
                    ],
                  ),
                  if (widget.showActions) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ActionChip(
                          label: widget.actionLabel,
                          color: widget.accentColor,
                          onTap: widget.controller.dismiss,
                        ),
                        if (widget.showSecondAction) ...[
                          const SizedBox(width: 8),
                          _ActionChip(
                            label: widget.secondActionLabel,
                            color: textColor.withAlpha(180),
                            onTap: widget.controller.dismiss,
                          ),
                        ],
                      ],
                    ),
                  ],
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
                      valueColor:
                          AlwaysStoppedAnimation(widget.accentColor),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Small helper widgets
// =============================================================================

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
