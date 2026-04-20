import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

// =============================================================================
// Builder Data Models
//
// These models hold the user's configuration state for the Toast Builder UI.
// They are used to generate the final Dart code and to drive the preview.
// =============================================================================

/// Represents a user-configured toast channel in the builder.
class ChannelModel {
  ChannelModel({
    String? id,
    this.label = 'New Channel',
    this.maxVisible,
    this.defaultPriority,
    this.defaultPosition,
    this.defaultDuration,
    this.defaultAnimation,
    this.defaultVariant,
    this.customVariantName,
    List<String>? assignedVariantIds,
    this.enabled = true,
  })  : id = id ?? 'channel_${DateTime.now().millisecondsSinceEpoch}',
        assignedVariantIds = assignedVariantIds ?? [];

  String id;
  String label;
  int? maxVisible;
  ToastPriority? defaultPriority;
  ToastPosition? defaultPosition;
  Duration? defaultDuration;
  ToastAnimationType? defaultAnimation;
  ToastVariant? defaultVariant;
  String? customVariantName;

  /// List of saved variant IDs assigned to this channel.
  /// Channels can now have multiple variants assigned.
  List<String> assignedVariantIds;

  bool enabled;

  ChannelModel copyWith({
    String? id,
    String? label,
    int? maxVisible,
    bool clearMaxVisible = false,
    ToastPriority? defaultPriority,
    bool clearPriority = false,
    ToastPosition? defaultPosition,
    bool clearPosition = false,
    Duration? defaultDuration,
    bool clearDuration = false,
    ToastAnimationType? defaultAnimation,
    bool clearAnimation = false,
    ToastVariant? defaultVariant,
    bool clearVariant = false,
    String? customVariantName,
    bool clearCustomVariantName = false,
    List<String>? assignedVariantIds,
    bool? enabled,
  }) {
    return ChannelModel(
      id: id ?? this.id,
      label: label ?? this.label,
      maxVisible: clearMaxVisible ? null : (maxVisible ?? this.maxVisible),
      defaultPriority:
          clearPriority ? null : (defaultPriority ?? this.defaultPriority),
      defaultPosition:
          clearPosition ? null : (defaultPosition ?? this.defaultPosition),
      defaultDuration:
          clearDuration ? null : (defaultDuration ?? this.defaultDuration),
      defaultAnimation:
          clearAnimation ? null : (defaultAnimation ?? this.defaultAnimation),
      defaultVariant:
          clearVariant ? null : (defaultVariant ?? this.defaultVariant),
      customVariantName: clearCustomVariantName
          ? null
          : (customVariantName ?? this.customVariantName),
      assignedVariantIds: assignedVariantIds ?? this.assignedVariantIds,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// Represents a per-channel configuration (ChannelConfig) in the builder.
class ChannelConfigModel {
  ChannelConfigModel({
    this.maxVisible,
    this.duration,
    this.interruptCurrent = false,
    this.enableDeduplication = false,
    this.deduplicationWindowSec = 2,
    this.enableThrottling = false,
    this.throttleIntervalMs = 500,
  });

  int? maxVisible;
  Duration? duration;
  bool interruptCurrent;
  bool enableDeduplication;
  int deduplicationWindowSec;
  bool enableThrottling;
  int throttleIntervalMs;
}

/// Represents a config-based rule in the builder.
class RuleConfigModel {
  RuleConfigModel({
    required this.channelId,
    this.errorThreshold = 5,
    this.deduplicateWindowSec = 30,
    this.maxTriggers = 0,
  });

  String channelId;
  int errorThreshold;
  int deduplicateWindowSec;
  int maxTriggers;
}

/// Represents a custom rule in the builder.
class CustomRuleModel {
  CustomRuleModel({
    String? id,
    required this.channelId,
    this.maxTriggers = 0,
    this.deduplicateWindowSec,
    this.conditionType = RuleConditionType.errorCountGte,
    this.conditionThreshold = 3,
    this.actionType = RuleActionType.showInfoToast,
    this.actionMessage = 'Rule triggered!',
    this.actionTitle,
    this.persistent = false,
    this.dismissible = true,
  }) : id = id ?? 'rule_${DateTime.now().millisecondsSinceEpoch}';

  String id;
  String channelId;
  int maxTriggers;
  int? deduplicateWindowSec;
  RuleConditionType conditionType;
  int conditionThreshold;
  RuleActionType actionType;
  String actionMessage;
  String? actionTitle;
  bool persistent;
  bool dismissible;
}

/// Pre-defined condition types for the builder UI.
enum RuleConditionType {
  errorCountGte('Error count ≥ threshold'),
  totalCountGte('Total count ≥ threshold'),
  errorsInWindowGte('Errors in 30s window ≥ threshold'),
  warningCountGte('Warning count ≥ threshold');

  const RuleConditionType(this.label);
  final String label;
}

/// Pre-defined action types for the builder UI.
enum RuleActionType {
  showInfoToast('Show info toast'),
  showWarningToast('Show warning toast'),
  showErrorToast('Show error toast'),
  showActionToast('Show toast with action button');

  const RuleActionType(this.label);
  final String label;
}

/// Represents a variant assignment in the builder.
class VariantAssignment {
  VariantAssignment({
    required this.channelId,
    this.builtInVariant,
    this.customVariantName,
  });

  String channelId;
  ToastVariant? builtInVariant;
  String? customVariantName;
}

/// Represents a saved toast design variant that can be reused across channels.
///
/// A variant encapsulates the complete UI design of a toast including colors,
/// sizes, styles, and behavior. Variants can be saved, loaded, edited, and
/// assigned to multiple channels.
class VariantModel {
  VariantModel({
    String? id,
    required this.name,
    this.description,
    required this.toastType,
    this.icon,
    this.iconCodePoint,
    this.backgroundColor,
    this.textColor,
    this.accentColor,
    this.borderColor,
    this.borderWidth = 0.0,
    this.cornerRadius = 12.0,
    this.padding = 16.0,
    this.shadowBlur = 8.0,
    this.opacity = 1.0,
    this.fontSize = 14.0,
    this.iconSize = 24.0,
    this.titleFontWeight,
    this.messageFontWeight,
    this.messageMaxLines = 3,
    this.useGradient = false,
    this.gradientStartColor,
    this.gradientEndColor,
    this.variant,
    this.position,
    this.animation,
    this.durationMs = 3000,
    this.persistent = false,
    this.dismissible = true,
    this.showProgressBar = false,
    this.enableHapticFeedback = false,
    List<String>? assignedChannels,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? 'variant_${DateTime.now().millisecondsSinceEpoch}',
        assignedChannels = assignedChannels ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Unique identifier for this variant.
  String id;

  /// Display name for this variant.
  String name;

  /// Optional description explaining what this variant is for.
  String? description;

  /// The toast type (success, error, warning, info, custom).
  ToastType toastType;

  /// Icon to display (nullable).
  IconData? icon;

  /// Icon code point for serialization (since IconData is not directly serializable).
  int? iconCodePoint;

  // ── Visual Properties ──
  Color? backgroundColor;
  Color? textColor;
  Color? accentColor;
  Color? borderColor;
  double borderWidth;
  double cornerRadius;
  double padding;
  double shadowBlur;
  double opacity;
  double fontSize;
  double iconSize;

  // ── Text Styling ──
  FontWeight? titleFontWeight;
  FontWeight? messageFontWeight;
  int messageMaxLines;

  // ── Gradient ──
  bool useGradient;
  Color? gradientStartColor;
  Color? gradientEndColor;

  // ── Behavior ──
  ToastVariant? variant;
  ToastPosition? position;
  ToastAnimationType? animation;
  int durationMs;
  bool persistent;
  bool dismissible;
  bool showProgressBar;
  bool enableHapticFeedback;

  /// List of channel IDs this variant is assigned to.
  List<String> assignedChannels;

  /// When this variant was created.
  DateTime createdAt;

  /// When this variant was last modified.
  DateTime updatedAt;

  /// Create a copy of this variant with optional field overrides.
  VariantModel copyWith({
    String? id,
    String? name,
    String? description,
    bool clearDescription = false,
    ToastType? toastType,
    IconData? icon,
    bool clearIcon = false,
    int? iconCodePoint,
    bool clearIconCodePoint = false,
    Color? backgroundColor,
    bool clearBackgroundColor = false,
    Color? textColor,
    bool clearTextColor = false,
    Color? accentColor,
    bool clearAccentColor = false,
    Color? borderColor,
    bool clearBorderColor = false,
    double? borderWidth,
    double? cornerRadius,
    double? padding,
    double? shadowBlur,
    double? opacity,
    double? fontSize,
    double? iconSize,
    FontWeight? titleFontWeight,
    bool clearTitleFontWeight = false,
    FontWeight? messageFontWeight,
    bool clearMessageFontWeight = false,
    int? messageMaxLines,
    bool? useGradient,
    Color? gradientStartColor,
    bool clearGradientStartColor = false,
    Color? gradientEndColor,
    bool clearGradientEndColor = false,
    ToastVariant? variant,
    bool clearVariant = false,
    ToastPosition? position,
    bool clearPosition = false,
    ToastAnimationType? animation,
    bool clearAnimation = false,
    int? durationMs,
    bool? persistent,
    bool? dismissible,
    bool? showProgressBar,
    bool? enableHapticFeedback,
    List<String>? assignedChannels,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VariantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      toastType: toastType ?? this.toastType,
      icon: clearIcon ? null : (icon ?? this.icon),
      iconCodePoint:
          clearIconCodePoint ? null : (iconCodePoint ?? this.iconCodePoint),
      backgroundColor: clearBackgroundColor
          ? null
          : (backgroundColor ?? this.backgroundColor),
      textColor: clearTextColor ? null : (textColor ?? this.textColor),
      accentColor: clearAccentColor ? null : (accentColor ?? this.accentColor),
      borderColor: clearBorderColor ? null : (borderColor ?? this.borderColor),
      borderWidth: borderWidth ?? this.borderWidth,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      padding: padding ?? this.padding,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      opacity: opacity ?? this.opacity,
      fontSize: fontSize ?? this.fontSize,
      iconSize: iconSize ?? this.iconSize,
      titleFontWeight: clearTitleFontWeight
          ? null
          : (titleFontWeight ?? this.titleFontWeight),
      messageFontWeight: clearMessageFontWeight
          ? null
          : (messageFontWeight ?? this.messageFontWeight),
      messageMaxLines: messageMaxLines ?? this.messageMaxLines,
      useGradient: useGradient ?? this.useGradient,
      gradientStartColor: clearGradientStartColor
          ? null
          : (gradientStartColor ?? this.gradientStartColor),
      gradientEndColor: clearGradientEndColor
          ? null
          : (gradientEndColor ?? this.gradientEndColor),
      variant: clearVariant ? null : (variant ?? this.variant),
      position: clearPosition ? null : (position ?? this.position),
      animation: clearAnimation ? null : (animation ?? this.animation),
      durationMs: durationMs ?? this.durationMs,
      persistent: persistent ?? this.persistent,
      dismissible: dismissible ?? this.dismissible,
      showProgressBar: showProgressBar ?? this.showProgressBar,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      assignedChannels: assignedChannels ?? this.assignedChannels,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON for persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'toastType': toastType.name,
      'iconCodePoint': iconCodePoint,
      'backgroundColor': backgroundColor?.value,
      'textColor': textColor?.value,
      'accentColor': accentColor?.value,
      'borderColor': borderColor?.value,
      'borderWidth': borderWidth,
      'cornerRadius': cornerRadius,
      'padding': padding,
      'shadowBlur': shadowBlur,
      'opacity': opacity,
      'fontSize': fontSize,
      'iconSize': iconSize,
      'titleFontWeight': titleFontWeight?.index,
      'messageFontWeight': messageFontWeight?.index,
      'messageMaxLines': messageMaxLines,
      'useGradient': useGradient,
      'gradientStartColor': gradientStartColor?.value,
      'gradientEndColor': gradientEndColor?.value,
      'variant': variant?.name,
      'position': position?.name,
      'animation': animation?.name,
      'durationMs': durationMs,
      'persistent': persistent,
      'dismissible': dismissible,
      'showProgressBar': showProgressBar,
      'enableHapticFeedback': enableHapticFeedback,
      'assignedChannels': assignedChannels,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON.
  static VariantModel fromJson(Map<String, dynamic> json) {
    // Helper to parse FontWeight from index
    FontWeight? parseFontWeight(int? index) {
      if (index == null) return null;
      final weights = [
        FontWeight.w100,
        FontWeight.w200,
        FontWeight.w300,
        FontWeight.w400,
        FontWeight.w500,
        FontWeight.w600,
        FontWeight.w700,
        FontWeight.w800,
        FontWeight.w900,
      ];
      return index >= 0 && index < weights.length ? weights[index] : null;
    }

    return VariantModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      toastType: ToastType.values.byName(json['toastType'] as String),
      iconCodePoint: json['iconCodePoint'] as int?,
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'] as int)
          : null,
      textColor:
          json['textColor'] != null ? Color(json['textColor'] as int) : null,
      accentColor: json['accentColor'] != null
          ? Color(json['accentColor'] as int)
          : null,
      borderColor: json['borderColor'] != null
          ? Color(json['borderColor'] as int)
          : null,
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 0.0,
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 12.0,
      padding: (json['padding'] as num?)?.toDouble() ?? 16.0,
      shadowBlur: (json['shadowBlur'] as num?)?.toDouble() ?? 8.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      iconSize: (json['iconSize'] as num?)?.toDouble() ?? 24.0,
      titleFontWeight: parseFontWeight(json['titleFontWeight'] as int?),
      messageFontWeight: parseFontWeight(json['messageFontWeight'] as int?),
      messageMaxLines: json['messageMaxLines'] as int? ?? 3,
      useGradient: json['useGradient'] as bool? ?? false,
      gradientStartColor: json['gradientStartColor'] != null
          ? Color(json['gradientStartColor'] as int)
          : null,
      gradientEndColor: json['gradientEndColor'] != null
          ? Color(json['gradientEndColor'] as int)
          : null,
      variant: json['variant'] != null
          ? ToastVariant.values.byName(json['variant'] as String)
          : null,
      position: json['position'] != null
          ? ToastPosition.values.byName(json['position'] as String)
          : null,
      animation: json['animation'] != null
          ? ToastAnimationType.values.byName(json['animation'] as String)
          : null,
      durationMs: json['durationMs'] as int? ?? 3000,
      persistent: json['persistent'] as bool? ?? false,
      dismissible: json['dismissible'] as bool? ?? true,
      showProgressBar: json['showProgressBar'] as bool? ?? false,
      enableHapticFeedback: json['enableHapticFeedback'] as bool? ?? false,
      assignedChannels:
          (json['assignedChannels'] as List?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Holds the complete builder configuration state.
class BuilderConfiguration {
  BuilderConfiguration({
    List<ChannelModel>? channels,
    Map<String, ChannelConfigModel>? channelConfigs,
    List<RuleConfigModel>? ruleConfigs,
    List<CustomRuleModel>? customRules,
    List<String>? registeredVariantNames,
    List<VariantModel>? savedVariants,
  })  : channels = channels ?? [],
        channelConfigs = channelConfigs ?? {},
        ruleConfigs = ruleConfigs ?? [],
        customRules = customRules ?? [],
        registeredVariantNames = registeredVariantNames ?? [],
        savedVariants = savedVariants ?? [];

  final List<ChannelModel> channels;
  final Map<String, ChannelConfigModel> channelConfigs;
  final List<RuleConfigModel> ruleConfigs;
  final List<CustomRuleModel> customRules;
  final List<String> registeredVariantNames;

  /// Saved toast design variants that can be loaded and reused.
  final List<VariantModel> savedVariants;

  /// Export configuration as a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'channels': channels
          .map((c) => {
                'id': c.id,
                'label': c.label,
                'maxVisible': c.maxVisible,
                'defaultPriority': c.defaultPriority?.name,
                'defaultPosition': c.defaultPosition?.name,
                'defaultDurationMs': c.defaultDuration?.inMilliseconds,
                'defaultAnimation': c.defaultAnimation?.name,
                'defaultVariant': c.defaultVariant?.name,
                'customVariantName': c.customVariantName,
                'assignedVariantIds': c.assignedVariantIds,
                'enabled': c.enabled,
              })
          .toList(),
      'channelConfigs': channelConfigs.map((k, v) => MapEntry(k, {
            'maxVisible': v.maxVisible,
            'durationMs': v.duration?.inMilliseconds,
            'interruptCurrent': v.interruptCurrent,
            'enableDeduplication': v.enableDeduplication,
            'deduplicationWindowSec': v.deduplicationWindowSec,
            'enableThrottling': v.enableThrottling,
            'throttleIntervalMs': v.throttleIntervalMs,
          })),
      'ruleConfigs': ruleConfigs
          .map((r) => {
                'channelId': r.channelId,
                'errorThreshold': r.errorThreshold,
                'deduplicateWindowSec': r.deduplicateWindowSec,
                'maxTriggers': r.maxTriggers,
              })
          .toList(),
      'customRules': customRules
          .map((r) => {
                'id': r.id,
                'channelId': r.channelId,
                'maxTriggers': r.maxTriggers,
                'deduplicateWindowSec': r.deduplicateWindowSec,
                'conditionType': r.conditionType.name,
                'conditionThreshold': r.conditionThreshold,
                'actionType': r.actionType.name,
                'actionMessage': r.actionMessage,
                'actionTitle': r.actionTitle,
                'persistent': r.persistent,
                'dismissible': r.dismissible,
              })
          .toList(),
      'registeredVariantNames': registeredVariantNames,
      'savedVariants': savedVariants.map((v) => v.toJson()).toList(),
    };
  }

  /// Import configuration from a JSON-compatible map.
  static BuilderConfiguration fromJson(Map<String, dynamic> json) {
    final channels = (json['channels'] as List?)
            ?.map((c) => ChannelModel(
                  id: c['id'] as String,
                  label: c['label'] as String,
                  maxVisible: c['maxVisible'] as int?,
                  defaultPriority: c['defaultPriority'] != null
                      ? ToastPriority.values
                          .byName(c['defaultPriority'] as String)
                      : null,
                  defaultPosition: c['defaultPosition'] != null
                      ? ToastPosition.values
                          .byName(c['defaultPosition'] as String)
                      : null,
                  defaultDuration: c['defaultDurationMs'] != null
                      ? Duration(milliseconds: c['defaultDurationMs'] as int)
                      : null,
                  defaultAnimation: c['defaultAnimation'] != null
                      ? ToastAnimationType.values
                          .byName(c['defaultAnimation'] as String)
                      : null,
                  defaultVariant: c['defaultVariant'] != null
                      ? ToastVariant.values
                          .byName(c['defaultVariant'] as String)
                      : null,
                  customVariantName: c['customVariantName'] as String?,
                  assignedVariantIds:
                      (c['assignedVariantIds'] as List?)?.cast<String>() ?? [],
                  enabled: c['enabled'] as bool? ?? true,
                ))
            .toList() ??
        [];

    final channelConfigs = <String, ChannelConfigModel>{};
    if (json['channelConfigs'] is Map) {
      (json['channelConfigs'] as Map).forEach((k, v) {
        channelConfigs[k as String] = ChannelConfigModel(
          maxVisible: v['maxVisible'] as int?,
          duration: v['durationMs'] != null
              ? Duration(milliseconds: v['durationMs'] as int)
              : null,
          interruptCurrent: v['interruptCurrent'] as bool? ?? false,
          enableDeduplication: v['enableDeduplication'] as bool? ?? false,
          deduplicationWindowSec: v['deduplicationWindowSec'] as int? ?? 2,
          enableThrottling: v['enableThrottling'] as bool? ?? false,
          throttleIntervalMs: v['throttleIntervalMs'] as int? ?? 500,
        );
      });
    }

    final ruleConfigs = (json['ruleConfigs'] as List?)
            ?.map((r) => RuleConfigModel(
                  channelId: r['channelId'] as String,
                  errorThreshold: r['errorThreshold'] as int? ?? 5,
                  deduplicateWindowSec:
                      r['deduplicateWindowSec'] as int? ?? 30,
                  maxTriggers: r['maxTriggers'] as int? ?? 0,
                ))
            .toList() ??
        [];

    final customRules = (json['customRules'] as List?)
            ?.map((r) => CustomRuleModel(
                  id: r['id'] as String,
                  channelId: r['channelId'] as String,
                  maxTriggers: r['maxTriggers'] as int? ?? 0,
                  deduplicateWindowSec: r['deduplicateWindowSec'] as int?,
                  conditionType: RuleConditionType.values
                      .byName(r['conditionType'] as String),
                  conditionThreshold:
                      r['conditionThreshold'] as int? ?? 3,
                  actionType:
                      RuleActionType.values.byName(r['actionType'] as String),
                  actionMessage: r['actionMessage'] as String,
                  actionTitle: r['actionTitle'] as String?,
                  persistent: r['persistent'] as bool? ?? false,
                  dismissible: r['dismissible'] as bool? ?? true,
                ))
            .toList() ??
        [];

    final savedVariants = (json['savedVariants'] as List?)
            ?.map((v) => VariantModel.fromJson(v as Map<String, dynamic>))
            .toList() ??
        [];

    return BuilderConfiguration(
      channels: channels,
      channelConfigs: channelConfigs,
      ruleConfigs: ruleConfigs,
      customRules: customRules,
      registeredVariantNames:
          (json['registeredVariantNames'] as List?)?.cast<String>() ?? [],
      savedVariants: savedVariants,
    );
  }
}

/// All available built-in variant display names for the builder.
const kBuiltInVariantOptions = <(ToastVariant, String, IconData)>[
  (ToastVariant.minimal, 'Minimal', Icons.minimize),
  (ToastVariant.material, 'Material', Icons.widgets),
  (ToastVariant.ios, 'iOS', Icons.phone_iphone),
  (ToastVariant.glassmorphism, 'Glassmorphism', Icons.blur_on),
  (ToastVariant.gradient, 'Gradient', Icons.gradient),
  (ToastVariant.floatingCard, 'Floating Card', Icons.crop_square),
  (ToastVariant.compact, 'Compact', Icons.compress),
  (ToastVariant.fullWidth, 'Full Width', Icons.width_full),
  (ToastVariant.loading, 'Loading', Icons.hourglass_empty),
  (ToastVariant.progress, 'Progress', Icons.linear_scale),
  (ToastVariant.action, 'Action', Icons.touch_app),
  (ToastVariant.debug, 'Debug', Icons.bug_report),
];

/// Well-known custom variant names used in examples.
const kExampleCustomVariants = <String>[
  'payment_success',
  'system_error',
  'notification_banner',
];
