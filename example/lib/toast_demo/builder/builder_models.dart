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
    this.enabled = true,
  }) : id = id ?? 'channel_${DateTime.now().millisecondsSinceEpoch}';

  String id;
  String label;
  int? maxVisible;
  ToastPriority? defaultPriority;
  ToastPosition? defaultPosition;
  Duration? defaultDuration;
  ToastAnimationType? defaultAnimation;
  ToastVariant? defaultVariant;
  String? customVariantName;
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

/// Holds the complete builder configuration state.
class BuilderConfiguration {
  BuilderConfiguration({
    List<ChannelModel>? channels,
    Map<String, ChannelConfigModel>? channelConfigs,
    List<RuleConfigModel>? ruleConfigs,
    List<CustomRuleModel>? customRules,
    List<String>? registeredVariantNames,
  })  : channels = channels ?? [],
        channelConfigs = channelConfigs ?? {},
        ruleConfigs = ruleConfigs ?? [],
        customRules = customRules ?? [],
        registeredVariantNames = registeredVariantNames ?? [];

  final List<ChannelModel> channels;
  final Map<String, ChannelConfigModel> channelConfigs;
  final List<RuleConfigModel> ruleConfigs;
  final List<CustomRuleModel> customRules;
  final List<String> registeredVariantNames;

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

    return BuilderConfiguration(
      channels: channels,
      channelConfigs: channelConfigs,
      ruleConfigs: ruleConfigs,
      customRules: customRules,
      registeredVariantNames:
          (json['registeredVariantNames'] as List?)?.cast<String>() ?? [],
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
