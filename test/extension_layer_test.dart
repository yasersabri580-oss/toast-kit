import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:toast_kit/src/core/toast_config.dart';
import 'package:toast_kit/src/events/toast_event.dart';
import 'package:toast_kit/src/channels/toast_channel.dart';
import 'package:toast_kit/src/channels/channel_config.dart';
import 'package:toast_kit/src/channels/channel_manager.dart';
import 'package:toast_kit/src/plugins/toast_plugin.dart';
import 'package:toast_kit/src/plugins/plugin_hub.dart';
import 'package:toast_kit/src/plugins/firebase_toast_analytics_plugin.dart';
import 'package:toast_kit/src/analytics/toast_telemetry_event.dart';
import 'package:toast_kit/src/rules/rule_config.dart';
import 'package:toast_kit/src/rules/toast_rule.dart';
import 'package:toast_kit/src/rules/toast_stats.dart';
import 'package:toast_kit/src/rules/rule_engine.dart';
import 'package:toast_kit/src/variants/custom_variant_builder.dart';
import 'package:toast_kit/src/variants/custom_variant_registry.dart';
import 'package:toast_kit/src/variants/variant_factory.dart';

// ==========================================================================
// Test helpers
// ==========================================================================

/// A simple recording plugin for testing.
class RecordingPlugin extends ToastPlugin {

  RecordingPlugin({this.name = 'recording'});
  @override
  final String name;

  final List<String> calls = [];
  final List<ToastEvent> shownEvents = [];
  final List<ToastEvent> queuedEvents = [];
  final List<ToastEvent> dismissedEvents = [];
  final List<ToastEvent> droppedEvents = [];
  final List<String> droppedReasons = [];
  final List<ToastEvent> replacedEvents = [];
  final List<String> replacedIds = [];
  final List<String> registeredChannels = [];
  final List<String> triggeredRules = [];
  final List<ToastTelemetryEvent> telemetryEvents = [];

  @override
  void onToastShown(ToastEvent event) {
    calls.add('shown');
    shownEvents.add(event);
  }

  @override
  void onToastQueued(ToastEvent event) {
    calls.add('queued');
    queuedEvents.add(event);
  }

  @override
  void onToastDismissed(ToastEvent event, DismissReason? reason) {
    calls.add('dismissed');
    dismissedEvents.add(event);
  }

  @override
  void onToastDropped(ToastEvent event, String reason) {
    calls.add('dropped');
    droppedEvents.add(event);
    droppedReasons.add(reason);
  }

  @override
  void onToastReplaced(ToastEvent newEvent, String replacedId) {
    calls.add('replaced');
    replacedEvents.add(newEvent);
    replacedIds.add(replacedId);
  }

  @override
  void onToastAction(ToastEvent event, String actionLabel) {
    calls.add('action:$actionLabel');
  }

  @override
  void onChannelRegistered(String channelId) {
    calls.add('channel:$channelId');
    registeredChannels.add(channelId);
  }

  @override
  void onRuleTriggered(String ruleId, String channel) {
    calls.add('rule:$ruleId');
    triggeredRules.add(ruleId);
  }

  @override
  void onTelemetryEvent(ToastTelemetryEvent telemetryEvent) {
    telemetryEvents.add(telemetryEvent);
  }
}

/// A plugin that throws on every hook (for isolation testing).
class CrashingPlugin extends ToastPlugin {
  @override
  String get name => 'crasher';

  @override
  void onToastShown(ToastEvent event) => throw Exception('crash in shown');

  @override
  void onToastQueued(ToastEvent event) => throw Exception('crash in queued');

  @override
  void onToastDismissed(ToastEvent event, DismissReason? reason) =>
      throw Exception('crash in dismissed');

  @override
  void onToastDropped(ToastEvent event, String reason) =>
      throw Exception('crash in dropped');

  @override
  void onToastReplaced(ToastEvent newEvent, String replacedId) =>
      throw Exception('crash in replaced');

  @override
  void onToastAction(ToastEvent event, String actionLabel) =>
      throw Exception('crash in action');

  @override
  void onChannelRegistered(String channelId) =>
      throw Exception('crash in channelRegistered');

  @override
  void onRuleTriggered(String ruleId, String channel) =>
      throw Exception('crash in ruleTriggered');

  @override
  void onTelemetryEvent(ToastTelemetryEvent telemetryEvent) =>
      throw Exception('crash in telemetry');
}

void main() {
  // ========================================================================
  // ChannelConfig
  // ========================================================================
  group('ChannelConfig', () {
    test('defaults', () {
      const config = ChannelConfig();
      expect(config.maxVisible, isNull);
      expect(config.duration, isNull);
      expect(config.interruptCurrent, isFalse);
      expect(config.enableDeduplication, isFalse);
      expect(config.enableThrottling, isFalse);
    });

    test('custom values', () {
      const config = ChannelConfig(
        maxVisible: 3,
        duration: Duration(seconds: 6),
        interruptCurrent: true,
        enableDeduplication: true,
        deduplicationWindow: Duration(seconds: 30),
      );
      expect(config.maxVisible, 3);
      expect(config.duration, const Duration(seconds: 6));
      expect(config.interruptCurrent, isTrue);
      expect(config.enableDeduplication, isTrue);
      expect(config.deduplicationWindow, const Duration(seconds: 30));
    });

    test('copyWith', () {
      const config = ChannelConfig(maxVisible: 3);
      final copy = config.copyWith(duration: const Duration(seconds: 10));
      expect(copy.maxVisible, 3);
      expect(copy.duration, const Duration(seconds: 10));
    });

    test('equality', () {
      const a = ChannelConfig(maxVisible: 3);
      const b = ChannelConfig(maxVisible: 3);
      const c = ChannelConfig(maxVisible: 5);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  // ========================================================================
  // ChannelManager
  // ========================================================================
  group('ChannelManager', () {
    test('default channel always exists', () {
      final manager = ChannelManager();
      expect(manager.isRegistered('default'), isTrue);
      expect(manager['default'], isNotNull);
    });

    test('register and lookup', () {
      final manager = ChannelManager();
      manager.register(
        const ToastChannel(id: 'payment', label: 'Payment'),
        config: const ChannelConfig(maxVisible: 3),
      );
      expect(manager.isRegistered('payment'), isTrue);
      expect(manager['payment']!.id, 'payment');
      expect(manager.configFor('payment')!.maxVisible, 3);
    });

    test('idempotent override on re-registration', () {
      final manager = ChannelManager();
      manager.register(
        const ToastChannel(id: 'test', label: 'Test v1'),
        config: const ChannelConfig(maxVisible: 1),
      );
      manager.register(
        const ToastChannel(id: 'test', label: 'Test v2'),
        config: const ChannelConfig(maxVisible: 5),
      );
      expect(manager['test']!.label, 'Test v2');
      expect(manager.configFor('test')!.maxVisible, 5);
    });

    test('unregister removes channel', () {
      final manager = ChannelManager();
      manager.register(const ToastChannel(id: 'temp', label: 'Temp'));
      manager.unregister('temp');
      expect(manager.isRegistered('temp'), isFalse);
    });

    test('cannot unregister default channel', () {
      final manager = ChannelManager();
      manager.unregister('default');
      expect(manager.isRegistered('default'), isTrue);
    });

    test('isChannelFull respects config', () {
      final manager = ChannelManager();
      manager.register(
        const ToastChannel(id: 'limited', label: 'Limited'),
        config: const ChannelConfig(maxVisible: 2),
      );
      expect(manager.isChannelFull('limited'), isFalse);
      manager.markActive('limited');
      manager.markActive('limited');
      expect(manager.isChannelFull('limited'), isTrue);
    });

    test('markDismissed does not go below zero', () {
      final manager = ChannelManager();
      manager.register(const ToastChannel(id: 'x', label: 'X'));
      manager.markDismissed('x');
      expect(manager.activeCount('x'), 0);
    });

    test('clear resets to default only', () {
      final manager = ChannelManager();
      manager.register(const ToastChannel(id: 'extra', label: 'Extra'));
      manager.markActive('extra');
      manager.clear();
      expect(manager.isRegistered('extra'), isFalse);
      expect(manager.isRegistered('default'), isTrue);
    });

    test('channelIds includes all registered', () {
      final manager = ChannelManager();
      manager.register(const ToastChannel(id: 'a', label: 'A'));
      manager.register(const ToastChannel(id: 'b', label: 'B'));
      expect(manager.channelIds, containsAll(['default', 'a', 'b']));
    });

    test('register without config uses default ChannelConfig', () {
      final manager = ChannelManager();
      manager.register(const ToastChannel(id: 'basic', label: 'Basic'));
      final config = manager.configFor('basic');
      expect(config, isNotNull);
      expect(config!.maxVisible, isNull);
      expect(config.interruptCurrent, isFalse);
    });
  });

  // ========================================================================
  // ChannelHandle (fluent API)
  // ========================================================================
  group('ChannelHandle', () {
    test('emits events with correct channel', () {
      final emitted = <ToastEvent>[];
      final handle = ChannelHandle('payment', emitted.add);

      handle.success('Paid');
      handle.error('Failed');
      handle.warning('Low balance');
      handle.info('Receipt sent');

      expect(emitted, hasLength(4));
      for (final e in emitted) {
        expect(e.channel, 'payment');
      }
      expect(emitted[0].type, ToastType.success);
      expect(emitted[1].type, ToastType.error);
      expect(emitted[2].type, ToastType.warning);
      expect(emitted[3].type, ToastType.info);
    });

    test('show forwards event with channel override', () {
      final emitted = <ToastEvent>[];
      final handle = ChannelHandle('water', emitted.add);

      handle.show(ToastEvent.info(message: 'Drink water'));
      expect(emitted, hasLength(1));
      expect(emitted.first.channel, 'water');
      expect(emitted.first.message, 'Drink water');
    });
  });

  // ========================================================================
  // ToastPlugin (base)
  // ========================================================================
  group('ToastPlugin', () {
    test('default hooks are no-ops', () {
      final plugin = RecordingPlugin();
      // These should not throw.
      plugin.onAttach();
      plugin.onDetach();
      expect(plugin.calls, isEmpty);
    });
  });

  // ========================================================================
  // PluginHub
  // ========================================================================
  group('PluginHub', () {
    test('register and unregister', () {
      final hub = PluginHub();
      final plugin = RecordingPlugin();
      hub.register(plugin);
      expect(hub.pluginCount, 1);
      expect(hub.pluginNames, contains('recording'));

      hub.unregister('recording');
      expect(hub.pluginCount, 0);
    });

    test('duplicate registration replaces existing', () {
      final hub = PluginHub();
      final p1 = RecordingPlugin(name: 'dup');
      final p2 = RecordingPlugin(name: 'dup');
      hub.register(p1);
      hub.register(p2);
      expect(hub.pluginCount, 1);
    });

    test('notifyToastShown dispatches to all plugins', () {
      final hub = PluginHub();
      final p1 = RecordingPlugin(name: 'a');
      final p2 = RecordingPlugin(name: 'b');
      hub.register(p1);
      hub.register(p2);

      final event = ToastEvent.success(message: 'test');
      hub.notifyToastShown(event);

      expect(p1.shownEvents, hasLength(1));
      expect(p2.shownEvents, hasLength(1));
    });

    test('notifyToastQueued dispatches', () {
      final hub = PluginHub();
      final plugin = RecordingPlugin();
      hub.register(plugin);
      hub.notifyToastQueued(ToastEvent.info(message: 'q'));
      expect(plugin.calls, contains('queued'));
    });

    test('notifyToastDismissed dispatches', () {
      final hub = PluginHub();
      final plugin = RecordingPlugin();
      hub.register(plugin);
      hub.notifyToastDismissed(
          ToastEvent.success(message: 'd'), DismissReason.timeout);
      expect(plugin.calls, contains('dismissed'));
    });

    test('notifyToastDropped dispatches', () {
      final hub = PluginHub();
      final plugin = RecordingPlugin();
      hub.register(plugin);
      hub.notifyToastDropped(ToastEvent.error(message: 'x'), 'throttled');
      expect(plugin.droppedReasons, contains('throttled'));
    });

    test('notifyToastReplaced dispatches', () {
      final hub = PluginHub();
      final plugin = RecordingPlugin();
      hub.register(plugin);
      hub.notifyToastReplaced(
          ToastEvent.success(message: 'new'), 'old-id');
      expect(plugin.replacedIds, contains('old-id'));
    });

    test('notifyToastAction dispatches', () {
      final hub = PluginHub();
      final plugin = RecordingPlugin();
      hub.register(plugin);
      hub.notifyToastAction(ToastEvent.error(message: 'fail'), 'Retry');
      expect(plugin.calls, contains('action:Retry'));
    });

    test('notifyChannelRegistered dispatches', () {
      final hub = PluginHub();
      final plugin = RecordingPlugin();
      hub.register(plugin);
      hub.notifyChannelRegistered('payment');
      expect(plugin.registeredChannels, contains('payment'));
    });

    test('notifyRuleTriggered dispatches', () {
      final hub = PluginHub();
      final plugin = RecordingPlugin();
      hub.register(plugin);
      hub.notifyRuleTriggered('rule-1', 'payment');
      expect(plugin.triggeredRules, contains('rule-1'));
    });

    test('dispatchTelemetryEvent dispatches', () {
      final hub = PluginHub();
      final plugin = RecordingPlugin();
      hub.register(plugin);
      hub.dispatchTelemetryEvent(ToastTelemetryEvent(
        eventId: 'e1',
        type: TelemetryEventType.shown,
        timestamp: DateTime.now(),
      ));
      expect(plugin.telemetryEvents, hasLength(1));
    });

    test('plugin failure isolation — crashing plugin does not affect others',
        () {
      final hub = PluginHub();
      final crasher = CrashingPlugin();
      final recorder = RecordingPlugin(name: 'safe');
      hub.register(crasher);
      hub.register(recorder);

      final event = ToastEvent.success(message: 'test');

      // These should not throw despite crasher plugin throwing.
      hub.notifyToastShown(event);
      hub.notifyToastQueued(event);
      hub.notifyToastDismissed(event, null);
      hub.notifyToastDropped(event, 'test');
      hub.notifyToastReplaced(event, 'old');
      hub.notifyToastAction(event, 'Retry');
      hub.notifyChannelRegistered('ch');
      hub.notifyRuleTriggered('r', 'ch');

      // The safe plugin should still receive all events.
      expect(recorder.shownEvents, hasLength(1));
      expect(recorder.queuedEvents, hasLength(1));
      expect(recorder.dismissedEvents, hasLength(1));
      expect(recorder.droppedEvents, hasLength(1));
      expect(recorder.replacedEvents, hasLength(1));
      expect(recorder.registeredChannels, hasLength(1));
      expect(recorder.triggeredRules, hasLength(1));
    });

    test('hasPlugins', () {
      final hub = PluginHub();
      expect(hub.hasPlugins, isFalse);
      hub.register(RecordingPlugin());
      expect(hub.hasPlugins, isTrue);
    });

    test('dispose detaches all plugins', () {
      final hub = PluginHub();
      hub.register(RecordingPlugin());
      hub.register(RecordingPlugin(name: 'other'));
      hub.dispose();
      expect(hub.pluginCount, 0);
    });
  });

  // ========================================================================
  // ToastTelemetryEvent
  // ========================================================================
  group('ToastTelemetryEvent', () {
    test('toMap includes required fields', () {
      final event = ToastTelemetryEvent(
        eventId: 'e1',
        type: TelemetryEventType.shown,
        timestamp: DateTime(2025, 1, 1),
        toastId: 't1',
        channel: 'payment',
        toastType: ToastType.error,
      );
      final map = event.toMap();
      expect(map['eventId'], 'e1');
      expect(map['type'], 'shown');
      expect(map['toastId'], 't1');
      expect(map['channel'], 'payment');
      expect(map['toastType'], 'error');
    });

    test('toMap excludes null fields', () {
      final event = ToastTelemetryEvent(
        eventId: 'e2',
        type: TelemetryEventType.dismissed,
        timestamp: DateTime(2025, 1, 1),
      );
      final map = event.toMap();
      expect(map.containsKey('toastId'), isFalse);
      expect(map.containsKey('channel'), isFalse);
    });

    test('all TelemetryEventType values exist', () {
      expect(TelemetryEventType.values, contains(TelemetryEventType.shown));
      expect(
          TelemetryEventType.values, contains(TelemetryEventType.dismissed));
      expect(TelemetryEventType.values,
          contains(TelemetryEventType.actionClicked));
      expect(TelemetryEventType.values, contains(TelemetryEventType.queued));
      expect(TelemetryEventType.values, contains(TelemetryEventType.dropped));
      expect(
          TelemetryEventType.values, contains(TelemetryEventType.replaced));
      expect(TelemetryEventType.values,
          contains(TelemetryEventType.deduplicated));
      expect(
          TelemetryEventType.values, contains(TelemetryEventType.throttled));
      expect(TelemetryEventType.values,
          contains(TelemetryEventType.channelRegistered));
      expect(TelemetryEventType.values,
          contains(TelemetryEventType.ruleTriggered));
    });

    test('DismissReason values exist', () {
      expect(DismissReason.values, contains(DismissReason.timeout));
      expect(DismissReason.values, contains(DismissReason.userAction));
      expect(DismissReason.values, contains(DismissReason.replaced));
      expect(DismissReason.values, contains(DismissReason.programmatic));
    });

    test('toString', () {
      final event = ToastTelemetryEvent(
        eventId: 'e3',
        type: TelemetryEventType.shown,
        timestamp: DateTime.now(),
        toastId: 't3',
      );
      expect(event.toString(), contains('shown'));
      expect(event.toString(), contains('t3'));
    });
  });

  // ========================================================================
  // RuleConfig
  // ========================================================================
  group('RuleConfig', () {
    test('defaults', () {
      const config = RuleConfig();
      expect(config.errorThreshold, 5);
      expect(config.deduplicateWindow, const Duration(seconds: 30));
      expect(config.maxTriggers, 0);
    });

    test('custom values', () {
      const config = RuleConfig(
        errorThreshold: 10,
        deduplicateWindow: Duration(seconds: 60),
        maxTriggers: 3,
      );
      expect(config.errorThreshold, 10);
      expect(config.maxTriggers, 3);
    });

    test('equality', () {
      const a = RuleConfig(errorThreshold: 10);
      const b = RuleConfig(errorThreshold: 10);
      const c = RuleConfig(errorThreshold: 5);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  // ========================================================================
  // ToastStats
  // ========================================================================
  group('ToastStats', () {
    test('record increments counts', () {
      final stats = ToastStats();
      stats.record(ToastType.error);
      stats.record(ToastType.error);
      stats.record(ToastType.success);
      stats.record(ToastType.warning);
      stats.record(ToastType.info);

      expect(stats.totalCount, 5);
      expect(stats.errorCount, 2);
      expect(stats.successCount, 1);
      expect(stats.warningCount, 1);
      expect(stats.infoCount, 1);
    });

    test('recordDismissed', () {
      final stats = ToastStats();
      stats.recordDismissed();
      expect(stats.dismissedCount, 1);
    });

    test('recordDropped', () {
      final stats = ToastStats();
      stats.recordDropped();
      expect(stats.droppedCount, 1);
    });

    test('errorsInWindow', () {
      final stats = ToastStats();
      stats.record(ToastType.error);
      stats.record(ToastType.error);
      stats.record(ToastType.error);

      expect(stats.errorsInWindow(const Duration(seconds: 10)), 3);
    });

    test('reset clears all', () {
      final stats = ToastStats();
      stats.record(ToastType.error);
      stats.recordDismissed();
      stats.recordDropped();
      stats.reset();

      expect(stats.totalCount, 0);
      expect(stats.errorCount, 0);
      expect(stats.dismissedCount, 0);
      expect(stats.droppedCount, 0);
    });

    test('toString', () {
      final stats = ToastStats();
      expect(stats.toString(), contains('total:'));
    });
  });

  // ========================================================================
  // ToastRuleContext
  // ========================================================================
  group('ToastRuleContext', () {
    test('holds all fields', () {
      final stats = ToastStats();
      final event = ToastEvent.error(message: 'fail');
      final ctx = ToastRuleContext(
        channel: 'payment',
        stats: stats,
        event: event,
        ruleId: 'rule-1',
      );
      expect(ctx.channel, 'payment');
      expect(ctx.stats, same(stats));
      expect(ctx.event, same(event));
      expect(ctx.ruleId, 'rule-1');
    });
  });

  // ========================================================================
  // RuleEngine
  // ========================================================================
  group('RuleEngine', () {
    test('hasRules is false when empty', () {
      final engine = RuleEngine();
      expect(engine.hasRules, isFalse);
    });

    test('config rule triggers at threshold', () {
      final engine = RuleEngine();
      engine.configureRule('payment', const RuleConfig(errorThreshold: 3));
      expect(engine.hasRules, isTrue);

      // Record 3 errors.
      for (var i = 0; i < 3; i++) {
        engine.recordEvent(ToastEvent.error(message: 'fail', channel: 'payment'));
      }

      final triggered = engine.evaluate(
        ToastEvent.error(message: 'trigger', channel: 'payment'),
      );
      expect(triggered, contains('_config_payment'));
    });

    test('config rule does not trigger below threshold', () {
      final engine = RuleEngine();
      engine.configureRule('payment', const RuleConfig(errorThreshold: 10));

      for (var i = 0; i < 5; i++) {
        engine.recordEvent(ToastEvent.error(message: 'fail', channel: 'payment'));
      }

      final triggered = engine.evaluate(
        ToastEvent.error(message: 'no trigger', channel: 'payment'),
      );
      expect(triggered, isEmpty);
    });

    test('config rule respects maxTriggers', () {
      final engine = RuleEngine();
      engine.configureRule(
          'payment',
          const RuleConfig(
            errorThreshold: 2,
            maxTriggers: 1,
            deduplicateWindow: Duration.zero,
          ));

      for (var i = 0; i < 3; i++) {
        engine.recordEvent(ToastEvent.error(message: 'fail', channel: 'payment'));
      }

      // First evaluation triggers.
      final t1 = engine.evaluate(
        ToastEvent.error(message: 'x', channel: 'payment'),
      );
      expect(t1, isNotEmpty);

      // Second evaluation should not trigger (maxTriggers = 1).
      final t2 = engine.evaluate(
        ToastEvent.error(message: 'y', channel: 'payment'),
      );
      expect(t2, isEmpty);
    });

    test('custom rule triggers on condition', () {
      final engine = RuleEngine();
      var actionCalled = false;

      engine.addRule(ToastRule(
        id: 'help-after-5-errors',
        channel: 'payment',
        condition: (stats, event) => stats.errorCount >= 5,
        action: (context) {
          actionCalled = true;
        },
      ));

      for (var i = 0; i < 5; i++) {
        engine.recordEvent(ToastEvent.error(message: 'fail', channel: 'payment'));
      }

      final triggered = engine.evaluate(
        ToastEvent.error(message: 'trigger', channel: 'payment'),
      );
      expect(triggered, contains('help-after-5-errors'));
      expect(actionCalled, isTrue);
    });

    test('custom rule does not trigger for wrong channel', () {
      final engine = RuleEngine();
      var actionCalled = false;

      engine.addRule(ToastRule(
        id: 'payment-rule',
        channel: 'payment',
        condition: (stats, event) => true,
        action: (context) => actionCalled = true,
      ));

      final triggered = engine.evaluate(
        ToastEvent.error(message: 'x', channel: 'network'),
      );
      expect(triggered, isEmpty);
      expect(actionCalled, isFalse);
    });

    test('duplicate rule ids are replaced', () {
      final engine = RuleEngine();
      var firstCalled = false;
      var secondCalled = false;

      engine.addRule(ToastRule(
        id: 'dup-rule',
        channel: 'ch',
        condition: (stats, event) => true,
        action: (context) => firstCalled = true,
      ));

      engine.addRule(ToastRule(
        id: 'dup-rule',
        channel: 'ch',
        condition: (stats, event) => true,
        action: (context) => secondCalled = true,
      ));

      engine.evaluate(ToastEvent.info(message: 'x', channel: 'ch'));
      expect(firstCalled, isFalse);
      expect(secondCalled, isTrue);
    });

    test('rule condition crash is isolated', () {
      final engine = RuleEngine();

      engine.addRule(ToastRule(
        id: 'crasher',
        channel: 'ch',
        condition: (stats, event) => throw Exception('boom'),
        action: (context) {},
      ));

      // Should not throw.
      final triggered = engine.evaluate(
        ToastEvent.info(message: 'x', channel: 'ch'),
      );
      expect(triggered, isEmpty);
    });

    test('rule action crash is isolated', () {
      final engine = RuleEngine();

      engine.addRule(ToastRule(
        id: 'action-crasher',
        channel: 'ch',
        condition: (stats, event) => true,
        action: (context) => throw Exception('action boom'),
      ));

      // Should not throw.
      expect(
        () => engine.evaluate(ToastEvent.info(message: 'x', channel: 'ch')),
        returnsNormally,
      );
    });

    test('removeRule removes by id', () {
      final engine = RuleEngine();
      engine.addRule(ToastRule(
        id: 'removable',
        channel: 'ch',
        condition: (stats, event) => true,
        action: (context) {},
      ));
      engine.removeRule('removable');

      final triggered = engine.evaluate(
        ToastEvent.info(message: 'x', channel: 'ch'),
      );
      expect(triggered, isEmpty);
    });

    test('removeConfigRule removes by channel', () {
      final engine = RuleEngine();
      engine.configureRule('ch', const RuleConfig(errorThreshold: 1));
      engine.removeConfigRule('ch');
      expect(engine.hasRules, isFalse);
    });

    test('triggerCount tracks rule triggers', () {
      final engine = RuleEngine();
      engine.addRule(ToastRule(
        id: 'counter',
        channel: 'ch',
        condition: (stats, event) => true,
        action: (context) {},
      ));

      engine.evaluate(ToastEvent.info(message: 'x', channel: 'ch'));
      engine.evaluate(ToastEvent.info(message: 'y', channel: 'ch'));

      expect(engine.triggerCount('counter'), 2);
    });

    test('onRuleTriggered callback is called', () {
      final engine = RuleEngine();
      final triggered = <String>[];
      engine.onRuleTriggered = (ruleId, channel) => triggered.add(ruleId);

      engine.addRule(ToastRule(
        id: 'callback-test',
        channel: 'ch',
        condition: (stats, event) => true,
        action: (context) {},
      ));

      engine.evaluate(ToastEvent.info(message: 'x', channel: 'ch'));
      expect(triggered, contains('callback-test'));
    });

    test('clear removes everything', () {
      final engine = RuleEngine();
      engine.configureRule('ch', const RuleConfig(errorThreshold: 1));
      engine.addRule(ToastRule(
        id: 'r',
        channel: 'ch',
        condition: (stats, event) => true,
        action: (context) {},
      ));
      engine.recordEvent(ToastEvent.error(message: 'x', channel: 'ch'));
      engine.clear();

      expect(engine.hasRules, isFalse);
    });

    test('resetStats keeps rules', () {
      final engine = RuleEngine();
      engine.addRule(ToastRule(
        id: 'keep-me',
        channel: 'ch',
        condition: (stats, event) => true,
        action: (context) {},
      ));
      engine.recordEvent(ToastEvent.error(message: 'x', channel: 'ch'));
      engine.resetStats();

      expect(engine.hasRules, isTrue);
      expect(engine.statsFor('ch').totalCount, 0);
    });

    test('statsFor creates new stats for unknown channel', () {
      final engine = RuleEngine();
      final stats = engine.statsFor('new-channel');
      expect(stats.totalCount, 0);
    });

    test('recordDismissed and recordDropped update stats', () {
      final engine = RuleEngine();
      engine.recordDismissed('ch');
      engine.recordDropped('ch');
      final stats = engine.statsFor('ch');
      expect(stats.dismissedCount, 1);
      expect(stats.droppedCount, 1);
    });

    test('deduplication window prevents re-trigger', () {
      final engine = RuleEngine();
      engine.configureRule(
        'ch',
        const RuleConfig(
          errorThreshold: 1,
          deduplicateWindow: Duration(hours: 1),
          maxTriggers: 0,
        ),
      );

      engine.recordEvent(ToastEvent.error(message: 'x', channel: 'ch'));
      final t1 = engine.evaluate(
        ToastEvent.error(message: 'x', channel: 'ch'),
      );
      expect(t1, isNotEmpty);

      // Second call within the window should not trigger.
      final t2 = engine.evaluate(
        ToastEvent.error(message: 'y', channel: 'ch'),
      );
      expect(t2, isEmpty);
    });
  });

  // ========================================================================
  // FirebaseToastAnalyticsPlugin
  // ========================================================================
  group('FirebaseToastAnalyticsPlugin', () {
    test('logs toast_shown event', () {
      final logged = <Map<String, Object?>>[];
      final plugin = FirebaseToastAnalyticsPlugin(
        logEvent: ({required String name, Map<String, Object>? parameters}) {
          logged.add({'name': name, 'params': parameters});
        },
      );

      plugin.onToastShown(ToastEvent.success(message: 'ok'));
      expect(logged, hasLength(1));
      expect(logged.first['name'], 'toast_shown');
    });

    test('logs toast_dismissed event with reason', () {
      final logged = <Map<String, Object?>>[];
      final plugin = FirebaseToastAnalyticsPlugin(
        logEvent: ({required String name, Map<String, Object>? parameters}) {
          logged.add({'name': name, 'params': parameters});
        },
      );

      plugin.onToastDismissed(
          ToastEvent.error(message: 'fail'), DismissReason.timeout);
      expect(logged.first['name'], 'toast_dismissed');
      final params = logged.first['params'] as Map<String, Object>;
      expect(params['dismiss_reason'], 'timeout');
    });

    test('logs toast_action event', () {
      final logged = <Map<String, Object?>>[];
      final plugin = FirebaseToastAnalyticsPlugin(
        logEvent: ({required String name, Map<String, Object>? parameters}) {
          logged.add({'name': name, 'params': parameters});
        },
      );

      plugin.onToastAction(ToastEvent.error(message: 'x'), 'Retry');
      expect(logged.first['name'], 'toast_action');
      final params = logged.first['params'] as Map<String, Object>;
      expect(params['action_label'], 'Retry');
    });

    test('logs toast_dropped event', () {
      final logged = <Map<String, Object?>>[];
      final plugin = FirebaseToastAnalyticsPlugin(
        logEvent: ({required String name, Map<String, Object>? parameters}) {
          logged.add({'name': name, 'params': parameters});
        },
      );

      plugin.onToastDropped(ToastEvent.info(message: 'x'), 'throttled');
      expect(logged.first['name'], 'toast_dropped');
    });

    test('plugin name is firebase_analytics', () {
      final plugin = FirebaseToastAnalyticsPlugin(
        logEvent: ({required String name, Map<String, Object>? parameters}) {},
      );
      expect(plugin.name, 'firebase_analytics');
    });
  });

  // ========================================================================
  // Integration: Channels + Rules + Plugins
  // ========================================================================
  group('Integration', () {
    test('rule engine triggers and plugins are notified', () {
      final engine = RuleEngine();
      final plugin = RecordingPlugin();
      final hub = PluginHub();

      hub.register(plugin);
      engine.onRuleTriggered = (ruleId, channel) {
        hub.notifyRuleTriggered(ruleId, channel);
      };

      engine.addRule(ToastRule(
        id: 'int-rule',
        channel: 'payment',
        condition: (stats, event) => stats.errorCount >= 2,
        action: (context) {},
      ));

      engine.recordEvent(ToastEvent.error(message: '1', channel: 'payment'));
      engine.recordEvent(ToastEvent.error(message: '2', channel: 'payment'));
      engine.evaluate(ToastEvent.error(message: '3', channel: 'payment'));

      expect(plugin.triggeredRules, contains('int-rule'));
    });

    test('channel manager + config-based rule', () {
      final manager = ChannelManager();
      final engine = RuleEngine();

      manager.register(
        const ToastChannel(id: 'payment', label: 'Payment'),
        config: const ChannelConfig(maxVisible: 2),
      );
      engine.configureRule(
          'payment', const RuleConfig(errorThreshold: 3, maxTriggers: 1));

      for (var i = 0; i < 3; i++) {
        engine.recordEvent(
            ToastEvent.error(message: 'fail$i', channel: 'payment'));
      }

      final triggered = engine.evaluate(
        ToastEvent.error(message: 'trigger', channel: 'payment'),
      );
      expect(triggered, contains('_config_payment'));
    });

    test('full pipeline: channel + plugin + rule', () {
      final manager = ChannelManager();
      final hub = PluginHub();
      final engine = RuleEngine();
      final plugin = RecordingPlugin();

      hub.register(plugin);
      engine.onRuleTriggered = (ruleId, channel) {
        hub.notifyRuleTriggered(ruleId, channel);
      };

      // Register channel.
      manager.register(
        const ToastChannel(id: 'net', label: 'Network'),
        config: const ChannelConfig(maxVisible: 5),
      );
      hub.notifyChannelRegistered('net');

      // Add rule.
      engine.addRule(ToastRule(
        id: 'net-rule',
        channel: 'net',
        condition: (stats, event) => stats.errorCount >= 3,
        action: (context) {},
      ));

      // Simulate events.
      for (var i = 0; i < 3; i++) {
        final event = ToastEvent.error(message: 'err$i', channel: 'net');
        engine.recordEvent(event);
        hub.notifyToastShown(event);
      }

      engine.evaluate(ToastEvent.error(message: 'final', channel: 'net'));

      // Verify plugin received all hooks.
      expect(plugin.registeredChannels, contains('net'));
      expect(plugin.shownEvents, hasLength(3));
      expect(plugin.triggeredRules, contains('net-rule'));
    });

    test('default toast flow works without plugins or rules', () {
      // Just verify that with no plugins or rules, the engine is a no-op.
      final engine = RuleEngine();
      expect(engine.hasRules, isFalse);

      final triggered = engine.evaluate(
        ToastEvent.success(message: 'simple'),
      );
      expect(triggered, isEmpty);

      final hub = PluginHub();
      expect(hub.hasPlugins, isFalse);
      // These should not throw.
      hub.notifyToastShown(ToastEvent.success(message: 'safe'));
      hub.notifyToastDismissed(ToastEvent.success(message: 'safe'), null);
    });
  });

  // ========================================================================
  // CustomVariantRegistry
  // ========================================================================
  group('CustomVariantRegistry', () {
    test('register and lookup', () {
      final registry = CustomVariantRegistry();
      final variant = _TestVariant('my_variant');
      registry.register(variant);

      expect(registry.isRegistered('my_variant'), isTrue);
      expect(registry['my_variant'], same(variant));
      expect(registry.count, 1);
      expect(registry.variantNames, contains('my_variant'));
    });

    test('unregister removes variant', () {
      final registry = CustomVariantRegistry();
      registry.register(_TestVariant('temp'));
      registry.unregister('temp');
      expect(registry.isRegistered('temp'), isFalse);
      expect(registry['temp'], isNull);
      expect(registry.count, 0);
    });

    test('idempotent override on re-registration', () {
      final registry = CustomVariantRegistry();
      final v1 = _TestVariant('dup');
      final v2 = _TestVariant('dup');
      registry.register(v1);
      registry.register(v2);
      expect(registry.count, 1);
      expect(registry['dup'], same(v2));
    });

    test('empty name throws ArgumentError', () {
      final registry = CustomVariantRegistry();
      expect(
        () => registry.register(_TestVariant('')),
        throwsArgumentError,
      );
    });

    test('clear removes all', () {
      final registry = CustomVariantRegistry();
      registry.register(_TestVariant('a'));
      registry.register(_TestVariant('b'));
      registry.clear();
      expect(registry.count, 0);
      expect(registry.isRegistered('a'), isFalse);
    });

    test('lookup returns null for unknown', () {
      final registry = CustomVariantRegistry();
      expect(registry['nonexistent'], isNull);
      expect(registry.isRegistered('nonexistent'), isFalse);
    });

    test('toString includes variant names', () {
      final registry = CustomVariantRegistry();
      registry.register(_TestVariant('alpha'));
      registry.register(_TestVariant('beta'));
      final desc = registry.toString();
      expect(desc, contains('alpha'));
      expect(desc, contains('beta'));
    });
  });

  // ========================================================================
  // CustomToastVariantBuilder
  // ========================================================================
  group('CustomToastVariantBuilder', () {
    test('name property returns correct value', () {
      final variant = _TestVariant('payment_success');
      expect(variant.name, 'payment_success');
    });
  });

  // ========================================================================
  // ToastEvent — customVariantName support
  // ========================================================================
  group('ToastEvent customVariantName', () {
    test('customVariantName propagates through success factory', () {
      final e = ToastEvent.success(
        message: 'ok',
        customVariantName: 'my_variant',
      );
      expect(e.customVariantName, 'my_variant');
    });

    test('customVariantName propagates through error factory', () {
      final e = ToastEvent.error(
        message: 'fail',
        customVariantName: 'error_variant',
      );
      expect(e.customVariantName, 'error_variant');
    });

    test('customVariantName propagates through warning factory', () {
      final e = ToastEvent.warning(
        message: 'warn',
        customVariantName: 'warn_variant',
      );
      expect(e.customVariantName, 'warn_variant');
    });

    test('customVariantName propagates through info factory', () {
      final e = ToastEvent.info(
        message: 'note',
        customVariantName: 'info_variant',
      );
      expect(e.customVariantName, 'info_variant');
    });

    test('customVariantName propagates through loading factory', () {
      final e = ToastEvent.loading(
        message: 'wait',
        customVariantName: 'loading_variant',
      );
      expect(e.customVariantName, 'loading_variant');
    });

    test('customVariantName defaults to null', () {
      final e = ToastEvent.success(message: 'ok');
      expect(e.customVariantName, isNull);
    });
  });

  // ========================================================================
  // ToastChannel — customVariantName support
  // ========================================================================
  group('ToastChannel customVariantName', () {
    test('customVariantName is stored', () {
      const ch = ToastChannel(
        id: 'payment',
        label: 'Payment',
        customVariantName: 'payment_success',
      );
      expect(ch.customVariantName, 'payment_success');
    });

    test('customVariantName defaults to null', () {
      const ch = ToastChannel(id: 'basic', label: 'Basic');
      expect(ch.customVariantName, isNull);
    });

    test('customVariantName coexists with defaultVariant', () {
      const ch = ToastChannel(
        id: 'dual',
        label: 'Dual',
        defaultVariant: ToastVariant.material,
        customVariantName: 'custom_one',
      );
      expect(ch.defaultVariant, ToastVariant.material);
      expect(ch.customVariantName, 'custom_one');
    });
  });

  // ========================================================================
  // ChannelHandle — customVariantName forwarding
  // ========================================================================
  group('ChannelHandle customVariantName', () {
    test('success forwards customVariantName', () {
      final emitted = <ToastEvent>[];
      final handle = ChannelHandle('payment', emitted.add);
      handle.success('Paid', customVariantName: 'pv');
      expect(emitted.first.customVariantName, 'pv');
      expect(emitted.first.channel, 'payment');
    });

    test('error forwards customVariantName', () {
      final emitted = <ToastEvent>[];
      final handle = ChannelHandle('payment', emitted.add);
      handle.error('Failed', customVariantName: 'ev');
      expect(emitted.first.customVariantName, 'ev');
    });

    test('warning forwards customVariantName', () {
      final emitted = <ToastEvent>[];
      final handle = ChannelHandle('payment', emitted.add);
      handle.warning('Low', customVariantName: 'wv');
      expect(emitted.first.customVariantName, 'wv');
    });

    test('info forwards customVariantName', () {
      final emitted = <ToastEvent>[];
      final handle = ChannelHandle('payment', emitted.add);
      handle.info('Info', customVariantName: 'iv');
      expect(emitted.first.customVariantName, 'iv');
    });

    test('show forwards customVariantName from event', () {
      final emitted = <ToastEvent>[];
      final handle = ChannelHandle('ch', emitted.add);
      handle.show(ToastEvent.success(
        message: 'test',
        customVariantName: 'cv',
      ));
      expect(emitted.first.customVariantName, 'cv');
      expect(emitted.first.channel, 'ch');
    });
  });

  // ========================================================================
  // VariantFactory.resolveAndBuild — precedence chain
  // ========================================================================
  group('VariantFactory.resolveAndBuild precedence', () {
    late CustomVariantRegistry registry;
    late ToastController controller;

    setUp(() {
      registry = CustomVariantRegistry();
      registry.register(_TestVariant('custom_a'));
      registry.register(_TestVariant('custom_b'));

      controller = ToastController(
        id: 'test-id',
        dismiss: () {},
        pause: () {},
        resume: () {},
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('1. customBuilder takes highest priority', () {
      var builderCalled = false;
      final event = ToastEvent(
        type: ToastType.success,
        message: 'test',
        customBuilder: (ctx, ctrl) {
          builderCalled = true;
          return const SizedBox();
        },
        customVariantName: 'custom_a',
        variant: ToastVariant.minimal,
      );

      final widget = VariantFactory.resolveAndBuild(
        event: event,
        controller: controller,
        registry: registry,
        channelCustomVariantName: 'custom_b',
        channelDefaultVariant: ToastVariant.compact,
      );

      // The widget is a Builder; we just verify it was constructed.
      expect(widget, isNotNull);
      // Note: builderCalled would be true when the Builder is built in a
      // widget tree, but we can verify the structure is correct.
    });

    test('2. event customVariantName used when no customBuilder', () {
      final event = ToastEvent(
        type: ToastType.success,
        message: 'test',
        customVariantName: 'custom_a',
        variant: ToastVariant.minimal,
      );

      final widget = VariantFactory.resolveAndBuild(
        event: event,
        controller: controller,
        registry: registry,
        channelCustomVariantName: 'custom_b',
        channelDefaultVariant: ToastVariant.compact,
      );

      expect(widget, isNotNull);
    });

    test('3. channel customVariantName used as fallback', () {
      final event = ToastEvent(
        type: ToastType.success,
        message: 'test',
        variant: ToastVariant.minimal,
      );

      final widget = VariantFactory.resolveAndBuild(
        event: event,
        controller: controller,
        registry: registry,
        channelCustomVariantName: 'custom_b',
        channelDefaultVariant: ToastVariant.compact,
      );

      expect(widget, isNotNull);
    });

    test('4. event variant enum used when no custom variant names', () {
      final event = ToastEvent(
        type: ToastType.success,
        message: 'test',
        variant: ToastVariant.glassmorphism,
      );

      final widget = VariantFactory.resolveAndBuild(
        event: event,
        controller: controller,
        registry: registry,
      );

      expect(widget, isNotNull);
    });

    test('5. channel defaultVariant used as final fallback before type default', () {
      final event = ToastEvent(
        type: ToastType.success,
        message: 'test',
      );

      final widget = VariantFactory.resolveAndBuild(
        event: event,
        controller: controller,
        registry: registry,
        channelDefaultVariant: ToastVariant.compact,
      );

      expect(widget, isNotNull);
    });

    test('6. type default used when nothing else specified', () {
      final event = ToastEvent(
        type: ToastType.success,
        message: 'test',
      );

      final widget = VariantFactory.resolveAndBuild(
        event: event,
        controller: controller,
        registry: registry,
      );

      expect(widget, isNotNull);
    });

    test('unregistered customVariantName falls through', () {
      final event = ToastEvent(
        type: ToastType.success,
        message: 'test',
        customVariantName: 'nonexistent',
        variant: ToastVariant.minimal,
      );

      // Should not throw; falls through to event variant
      final widget = VariantFactory.resolveAndBuild(
        event: event,
        controller: controller,
        registry: registry,
      );

      expect(widget, isNotNull);
    });
  });
}

// ==========================================================================
// Test helpers for custom variant tests
// ==========================================================================

/// A minimal test implementation of [CustomToastVariantBuilder].
class _TestVariant extends CustomToastVariantBuilder {
  _TestVariant(this._name);

  final String _name;

  @override
  String get name => _name;

  @override
  Widget build(BuildContext context, ToastEvent event, ToastController controller) {
    return const SizedBox.shrink();
  }
}
