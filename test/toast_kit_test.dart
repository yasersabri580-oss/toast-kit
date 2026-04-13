import 'package:flutter/material.dart' hide RouterConfig;
import 'package:flutter_test/flutter_test.dart';

import 'package:toast_kit/src/core/toast_config.dart';
import 'package:toast_kit/src/events/toast_event.dart';
import 'package:toast_kit/src/events/event_bus.dart';
import 'package:toast_kit/src/queue/queue_manager.dart';
import 'package:toast_kit/src/router/notification_router.dart';
import 'package:toast_kit/src/router/router_config.dart';
import 'package:toast_kit/src/theme/toast_theme.dart';
import 'package:toast_kit/src/layout/toast_position_calculator.dart';
import 'package:toast_kit/src/animation/animation_curves.dart';
import 'package:toast_kit/src/channels/toast_channel.dart';
import 'package:toast_kit/src/persistence/toast_persistence.dart';
import 'package:toast_kit/src/stacking/group_collapser.dart';

void main() {
  // ========================================================================
  // ToastEvent
  // ========================================================================
  group('ToastEvent', () {
    test('success factory sets correct type', () {
      final e = ToastEvent.success(message: 'ok');
      expect(e.type, ToastType.success);
      expect(e.message, 'ok');
      expect(e.id, isNotEmpty);
      expect(e.priority, ToastPriority.normal);
      expect(e.persistent, isFalse);
      expect(e.dismissible, isTrue);
    });

    test('error factory sets correct type', () {
      final e = ToastEvent.error(message: 'fail');
      expect(e.type, ToastType.error);
    });

    test('warning factory sets correct type', () {
      final e = ToastEvent.warning(message: 'warn');
      expect(e.type, ToastType.warning);
    });

    test('info factory sets correct type', () {
      final e = ToastEvent.info(message: 'note');
      expect(e.type, ToastType.info);
    });

    test('loading factory is persistent', () {
      final e = ToastEvent.loading(message: 'wait');
      expect(e.type, ToastType.loading);
      expect(e.persistent, isTrue);
    });

    test('unique IDs', () {
      final ids = List.generate(100, (_) => ToastEvent.success(message: 'x').id);
      expect(ids.toSet().length, 100);
    });

    test('custom properties propagate', () {
      final e = ToastEvent.success(
        message: 'm',
        title: 't',
        duration: const Duration(seconds: 5),
        position: ToastPosition.bottom,
        priority: ToastPriority.high,
        deduplicationKey: 'dk',
        variant: ToastVariant.glassmorphism,
        actions: [ToastAction(label: 'Undo', onPressed: () {})],
      );
      expect(e.title, 't');
      expect(e.duration, const Duration(seconds: 5));
      expect(e.position, ToastPosition.bottom);
      expect(e.priority, ToastPriority.high);
      expect(e.deduplicationKey, 'dk');
      expect(e.variant, ToastVariant.glassmorphism);
      expect(e.actions, hasLength(1));
    });

    test('channel property propagates through factories', () {
      final e1 = ToastEvent.success(message: 'ok', channel: 'auth');
      expect(e1.channel, 'auth');

      final e2 = ToastEvent.error(message: 'fail', channel: 'network');
      expect(e2.channel, 'network');

      final e3 = ToastEvent.warning(message: 'warn', channel: 'sync');
      expect(e3.channel, 'sync');

      final e4 = ToastEvent.info(message: 'note', channel: 'payment');
      expect(e4.channel, 'payment');

      final e5 = ToastEvent.loading(message: 'wait', channel: 'debug');
      expect(e5.channel, 'debug');
    });

    test('channel defaults to null', () {
      final e = ToastEvent.success(message: 'ok');
      expect(e.channel, isNull);
    });
  });

  // ========================================================================
  // EventBus
  // ========================================================================
  group('EventBus', () {
    test('emits to listeners', () async {
      final bus = EventBus();
      final received = <ToastEvent>[];
      bus.stream.listen(received.add);
      bus.emit(ToastEvent.success(message: 'hi'));
      await Future<void>.delayed(Duration.zero);
      expect(received, hasLength(1));
      bus.dispose();
    });

    test('multiple listeners', () async {
      final bus = EventBus();
      final a = <ToastEvent>[];
      final b = <ToastEvent>[];
      bus.stream.listen(a.add);
      bus.stream.listen(b.add);
      bus.emit(ToastEvent.info(message: 'x'));
      await Future<void>.delayed(Duration.zero);
      expect(a, hasLength(1));
      expect(b, hasLength(1));
      bus.dispose();
    });

    test('throws after dispose', () {
      final bus = EventBus();
      bus.dispose();
      expect(() => bus.emit(ToastEvent.info(message: 'x')), throwsStateError);
    });

    test('isDisposed flag', () {
      final bus = EventBus();
      expect(bus.isDisposed, isFalse);
      bus.dispose();
      expect(bus.isDisposed, isTrue);
    });
  });

  // ========================================================================
  // ToastConfig
  // ========================================================================
  group('ToastConfig', () {
    test('defaults', () {
      const c = ToastConfig();
      expect(c.defaultPosition, ToastPosition.top);
      expect(c.maxVisibleToasts, 3);
      expect(c.enableQueue, isTrue);
      expect(c.queueMode, QueueMode.fifo);
      expect(c.density, ToastDensity.comfortable);
    });

    test('copyWith', () {
      const c = ToastConfig(maxVisibleToasts: 5, defaultPosition: ToastPosition.bottom);
      final copy = c.copyWith(maxVisibleToasts: 10);
      expect(copy.maxVisibleToasts, 10);
      expect(copy.defaultPosition, ToastPosition.bottom);
    });
  });

  // ========================================================================
  // ToastState enum
  // ========================================================================
  group('ToastState', () {
    test('has expected values', () {
      expect(ToastState.values, contains(ToastState.idle));
      expect(ToastState.values, contains(ToastState.loading));
      expect(ToastState.values, contains(ToastState.success));
      expect(ToastState.values, contains(ToastState.error));
      expect(ToastState.values, contains(ToastState.warning));
      expect(ToastState.values, contains(ToastState.info));
      expect(ToastState.values, contains(ToastState.custom));
    });
  });

  // ========================================================================
  // ToastController
  // ========================================================================
  group('ToastController', () {
    test('dismiss callback', () {
      var dismissed = false;
      final c = ToastController(id: '1', dismiss: () => dismissed = true, pause: () {}, resume: () {});
      c.dismiss();
      expect(dismissed, isTrue);
      c.dispose();
    });

    test('progress notifier', () {
      final c = ToastController(id: '2', dismiss: () {}, pause: () {}, resume: () {});
      expect(c.progress.value, 0.0);
      c.update(progressValue: 0.5);
      expect(c.progress.value, 0.5);
      c.dispose();
    });

    test('message notifier', () {
      final c = ToastController(
        id: '3', dismiss: () {}, pause: () {}, resume: () {}, initialMessage: 'start');
      expect(c.messageNotifier.value, 'start');
      c.update(message: 'end');
      expect(c.messageNotifier.value, 'end');
      c.dispose();
    });

    test('state notifier defaults to idle', () {
      final c = ToastController(id: '4', dismiss: () {}, pause: () {}, resume: () {});
      expect(c.state, ToastState.idle);
      expect(c.stateNotifier.value, ToastState.idle);
      c.dispose();
    });

    test('state notifier with initial state', () {
      final c = ToastController(
        id: '5',
        dismiss: () {},
        pause: () {},
        resume: () {},
        initialState: ToastState.loading,
      );
      expect(c.state, ToastState.loading);
      c.dispose();
    });

    test('success() transitions state', () {
      final c = ToastController(
        id: '6',
        dismiss: () {},
        pause: () {},
        resume: () {},
        initialState: ToastState.loading,
        initialMessage: 'Saving…',
      );
      expect(c.state, ToastState.loading);
      expect(c.messageNotifier.value, 'Saving…');

      c.success('Saved!');
      expect(c.state, ToastState.success);
      expect(c.messageNotifier.value, 'Saved!');
      expect(c.iconNotifier.value, Icons.check_circle_rounded);
      c.dispose();
    });

    test('error() transitions state', () {
      final c = ToastController(
        id: '7',
        dismiss: () {},
        pause: () {},
        resume: () {},
        initialState: ToastState.loading,
        initialMessage: 'Saving…',
      );
      c.error('Failed');
      expect(c.state, ToastState.error);
      expect(c.messageNotifier.value, 'Failed');
      expect(c.iconNotifier.value, Icons.error_rounded);
      c.dispose();
    });

    test('warning() transitions state', () {
      final c = ToastController(
        id: '8',
        dismiss: () {},
        pause: () {},
        resume: () {},
      );
      c.warning('Low battery');
      expect(c.state, ToastState.warning);
      expect(c.messageNotifier.value, 'Low battery');
      c.dispose();
    });

    test('info() transitions state', () {
      final c = ToastController(
        id: '9',
        dismiss: () {},
        pause: () {},
        resume: () {},
      );
      c.info('Update available');
      expect(c.state, ToastState.info);
      expect(c.messageNotifier.value, 'Update available');
      c.dispose();
    });

    test('update with state parameter', () {
      final c = ToastController(
        id: '10',
        dismiss: () {},
        pause: () {},
        resume: () {},
      );
      c.update(state: ToastState.custom, message: 'Custom state');
      expect(c.state, ToastState.custom);
      expect(c.messageNotifier.value, 'Custom state');
      c.dispose();
    });

    test('icon notifier updates', () {
      final c = ToastController(
        id: '11',
        dismiss: () {},
        pause: () {},
        resume: () {},
        initialIcon: Icons.hourglass_empty,
      );
      expect(c.iconNotifier.value, Icons.hourglass_empty);
      c.update(icon: Icons.check);
      expect(c.iconNotifier.value, Icons.check);
      c.dispose();
    });

    test('isDisposed flag', () {
      final c = ToastController(id: '12', dismiss: () {}, pause: () {}, resume: () {});
      expect(c.isDisposed, isFalse);
      c.dispose();
      expect(c.isDisposed, isTrue);
    });

    test('update is no-op after dispose', () {
      final c = ToastController(id: '13', dismiss: () {}, pause: () {}, resume: () {});
      c.dispose();
      // Should not throw.
      c.update(message: 'too late', progressValue: 0.5);
    });

    test('progress clamped to [0, 1]', () {
      final c = ToastController(id: '14', dismiss: () {}, pause: () {}, resume: () {});
      c.update(progressValue: 1.5);
      expect(c.progress.value, 1.0);
      c.update(progressValue: -0.5);
      expect(c.progress.value, 0.0);
      c.dispose();
    });
  });

  // ========================================================================
  // QueueManager
  // ========================================================================
  group('QueueManager', () {
    test('enqueue + dequeue FIFO', () {
      final shown = <String>[];
      final m = QueueManager(
        config: const ToastConfig(queueMode: QueueMode.fifo, maxVisibleToasts: 1),
        onReadyToShow: (e) => shown.add(e.id),
      );
      final e1 = ToastEvent.success(message: '1');
      final e2 = ToastEvent.success(message: '2');
      m.enqueue(e1);
      expect(m.visibleCount, 1);
      m.enqueue(e2);
      expect(m.queuedEvents, hasLength(1));
      m.markDismissed(e1.id);
      expect(shown, [e1.id, e2.id]);
      m.dispose();
    });

    test('clear', () {
      final m = QueueManager(config: const ToastConfig(maxVisibleToasts: 5), onReadyToShow: (_) {});
      m.enqueue(ToastEvent.success(message: 'a'));
      m.enqueue(ToastEvent.success(message: 'b'));
      m.clear();
      expect(m.visibleCount, 0);
      expect(m.queuedEvents, isEmpty);
      m.dispose();
    });

    test('isFull', () {
      final m = QueueManager(config: const ToastConfig(maxVisibleToasts: 2), onReadyToShow: (_) {});
      m.enqueue(ToastEvent.success(message: '1'));
      expect(m.isFull, isFalse);
      m.enqueue(ToastEvent.success(message: '2'));
      expect(m.isFull, isTrue);
      m.dispose();
    });

    test('stateStream', () async {
      final m = QueueManager(config: const ToastConfig(maxVisibleToasts: 1), onReadyToShow: (_) {});
      final states = <QueueState>[];
      m.stateStream.listen(states.add);
      m.enqueue(ToastEvent.success(message: 'x'));
      await Future<void>.delayed(Duration.zero);
      expect(states, isNotEmpty);
      expect(states.last.visibleCount, 1);
      m.dispose();
    });

    test('visibleEvents getter', () {
      final m = QueueManager(
        config: const ToastConfig(maxVisibleToasts: 3),
        onReadyToShow: (_) {},
      );
      final e1 = ToastEvent.success(message: 'a');
      final e2 = ToastEvent.error(message: 'b');
      m.enqueue(e1);
      m.enqueue(e2);
      expect(m.visibleEvents, hasLength(2));
      expect(m.visibleEvents.map((e) => e.id), contains(e1.id));
      expect(m.visibleEvents.map((e) => e.id), contains(e2.id));
      m.dispose();
    });

    test('LIFO ordering', () {
      final shown = <String>[];
      final m = QueueManager(
        config: const ToastConfig(queueMode: QueueMode.lifo, maxVisibleToasts: 1),
        onReadyToShow: (e) => shown.add(e.message ?? ''),
      );
      final e1 = ToastEvent.success(message: 'first');
      final e2 = ToastEvent.success(message: 'second');
      final e3 = ToastEvent.success(message: 'third');
      m.enqueue(e1);
      m.enqueue(e2);
      m.enqueue(e3);
      // e1 shown immediately, e2 and e3 queued. LIFO: e3 first.
      m.markDismissed(e1.id);
      expect(shown.last, 'third');
      m.dispose();
    });

    test('priority ordering', () {
      final shown = <String>[];
      final m = QueueManager(
        config: const ToastConfig(queueMode: QueueMode.priority, maxVisibleToasts: 1),
        onReadyToShow: (e) => shown.add(e.message ?? ''),
      );
      final e1 = ToastEvent.success(message: 'visible');
      final e2 = ToastEvent.success(message: 'low', priority: ToastPriority.low);
      final e3 = ToastEvent.success(message: 'high', priority: ToastPriority.high);
      m.enqueue(e1);
      m.enqueue(e2);
      m.enqueue(e3);
      // e1 shown immediately. Queue has e3 (high) before e2 (low).
      m.markDismissed(e1.id);
      expect(shown.last, 'high');
      m.dispose();
    });
  });

  // ========================================================================
  // NotificationRouter
  // ========================================================================
  group('NotificationRouter', () {
    late QueueManager qm;
    setUp(() {
      qm = QueueManager(config: const ToastConfig(maxVisibleToasts: 2), onReadyToShow: (_) {});
    });
    tearDown(() => qm.dispose());

    test('show when slots available', () {
      final r = NotificationRouter(queueManager: qm);
      final d = r.route(ToastEvent.success(message: 'hi'));
      expect(d, isA<ShowDecision>());
    });

    test('deduplication', () {
      final e1 = ToastEvent.success(message: 'a', deduplicationKey: 'k');
      qm.enqueue(e1);
      final r = NotificationRouter(queueManager: qm, config: const RouterConfig(enableDeduplication: true));
      // First route records the key; the second is a duplicate.
      r.route(e1);
      final d = r.route(ToastEvent.success(message: 'b', deduplicationKey: 'k'));
      expect(d, isA<DeduplicateDecision>());
    });

    test('deduplication disabled', () {
      qm.enqueue(ToastEvent.success(message: 'x', deduplicationKey: 'k'));
      final r = NotificationRouter(queueManager: qm, config: const RouterConfig(enableDeduplication: false));
      final d = r.route(ToastEvent.success(message: 'y', deduplicationKey: 'k'));
      expect(d, isA<ShowDecision>());
    });

    test('replaceOldest strategy', () {
      final e1 = ToastEvent.success(message: 'a');
      final e2 = ToastEvent.success(message: 'b');
      qm.enqueue(e1);
      qm.enqueue(e2);
      expect(qm.isFull, isTrue);

      final r = NotificationRouter(
        queueManager: qm,
        config: const RouterConfig(
          enableDeduplication: false,
          replacementStrategy: ReplacementStrategy.replaceOldest,
        ),
      );
      final d = r.route(ToastEvent.success(message: 'c'));
      expect(d, isA<ReplaceDecision>());
    });

    test('urgent interrupts lower priority', () {
      final e1 = ToastEvent.success(message: 'a', priority: ToastPriority.low);
      final e2 = ToastEvent.success(message: 'b', priority: ToastPriority.low);
      qm.enqueue(e1);
      qm.enqueue(e2);
      expect(qm.isFull, isTrue);

      final r = NotificationRouter(
        queueManager: qm,
        config: const RouterConfig(
          enableDeduplication: false,
          urgentInterruptsLower: true,
        ),
      );
      final urgentEvent = ToastEvent.success(message: 'urgent', priority: ToastPriority.urgent);
      final d = r.route(urgentEvent);
      expect(d, isA<ReplaceDecision>());
    });
  });

  // ========================================================================
  // RouterConfig
  // ========================================================================
  group('RouterConfig', () {
    test('defaults', () {
      const c = RouterConfig();
      expect(c.enableDeduplication, isTrue);
      expect(c.enableThrottling, isFalse);
      expect(c.urgentInterruptsLower, isTrue);
      expect(c.replacementStrategy, ReplacementStrategy.dropNew);
    });

    test('copyWith', () {
      const c = RouterConfig(enableThrottling: true);
      final copy = c.copyWith(enableDeduplication: false);
      expect(copy.enableThrottling, isTrue);
      expect(copy.enableDeduplication, isFalse);
    });
  });

  // ========================================================================
  // ToastChannel
  // ========================================================================
  group('ToastChannel', () {
    test('pre-defined channels exist', () {
      expect(ToastChannel.auth.id, 'auth');
      expect(ToastChannel.network.id, 'network');
      expect(ToastChannel.sync.id, 'sync');
      expect(ToastChannel.payment.id, 'payment');
      expect(ToastChannel.debug.id, 'debug');
    });

    test('equality by id', () {
      const a = ToastChannel(id: 'test', label: 'Test A');
      const b = ToastChannel(id: 'test', label: 'Test B');
      expect(a, equals(b));
    });

    test('toString', () {
      expect(ToastChannel.auth.toString(), 'ToastChannel(auth)');
    });

    test('payment channel has urgent priority', () {
      expect(ToastChannel.payment.defaultPriority, ToastPriority.urgent);
    });

    test('debug channel has debug variant', () {
      expect(ToastChannel.debug.defaultVariant, ToastVariant.debug);
    });
  });

  // ========================================================================
  // ChannelRegistry
  // ========================================================================
  group('ChannelRegistry', () {
    test('register and lookup', () {
      final registry = ChannelRegistry();
      registry.register(ToastChannel.auth);
      expect(registry['auth'], isNotNull);
      expect(registry['auth']!.id, 'auth');
      expect(registry['unknown'], isNull);
    });

    test('unregister', () {
      final registry = ChannelRegistry();
      registry.register(ToastChannel.auth);
      registry.unregister('auth');
      expect(registry['auth'], isNull);
    });

    test('active count tracking', () {
      final registry = ChannelRegistry();
      registry.register(ToastChannel.auth);
      expect(registry.activeCount('auth'), 0);
      registry.markActive('auth');
      expect(registry.activeCount('auth'), 1);
      registry.markActive('auth');
      expect(registry.activeCount('auth'), 2);
      registry.markDismissed('auth');
      expect(registry.activeCount('auth'), 1);
    });

    test('markDismissed does not go below zero', () {
      final registry = ChannelRegistry();
      registry.register(ToastChannel.auth);
      registry.markDismissed('auth');
      expect(registry.activeCount('auth'), 0);
    });

    test('isChannelFull', () {
      final registry = ChannelRegistry();
      registry.register(ToastChannel.auth); // maxVisible = 1
      expect(registry.isChannelFull('auth'), isFalse);
      registry.markActive('auth');
      expect(registry.isChannelFull('auth'), isTrue);
    });

    test('isChannelFull returns false for no max', () {
      final registry = ChannelRegistry();
      registry.register(ToastChannel.network); // maxVisible = null
      registry.markActive('network');
      registry.markActive('network');
      registry.markActive('network');
      expect(registry.isChannelFull('network'), isFalse);
    });

    test('channelIds', () {
      final registry = ChannelRegistry();
      registry.register(ToastChannel.auth);
      registry.register(ToastChannel.network);
      expect(registry.channelIds, containsAll(['auth', 'network']));
    });

    test('clear removes all', () {
      final registry = ChannelRegistry();
      registry.register(ToastChannel.auth);
      registry.markActive('auth');
      registry.clear();
      expect(registry['auth'], isNull);
      expect(registry.activeCount('auth'), 0);
    });
  });

  // ========================================================================
  // ToastPersistence (InMemory)
  // ========================================================================
  group('InMemoryToastPersistence', () {
    test('save and load', () async {
      final persistence = InMemoryToastPersistence();
      final event = ToastEvent.success(message: 'test');
      await persistence.save(event);
      final loaded = await persistence.loadPending();
      expect(loaded, hasLength(1));
      expect(loaded.first.id, event.id);
    });

    test('remove', () async {
      final persistence = InMemoryToastPersistence();
      final event = ToastEvent.success(message: 'test');
      await persistence.save(event);
      await persistence.remove(event.id);
      final loaded = await persistence.loadPending();
      expect(loaded, isEmpty);
    });

    test('clear', () async {
      final persistence = InMemoryToastPersistence();
      await persistence.save(ToastEvent.success(message: 'a'));
      await persistence.save(ToastEvent.error(message: 'b'));
      await persistence.clear();
      final loaded = await persistence.loadPending();
      expect(loaded, isEmpty);
    });

    test('save deduplicates by id', () async {
      final persistence = InMemoryToastPersistence();
      final event = ToastEvent.success(message: 'test');
      await persistence.save(event);
      await persistence.save(event);
      final loaded = await persistence.loadPending();
      expect(loaded, hasLength(1));
    });

    test('store getter returns unmodifiable view', () async {
      final persistence = InMemoryToastPersistence();
      await persistence.save(ToastEvent.success(message: 'a'));
      final store = persistence.store;
      expect(store, hasLength(1));
      // Verify it's an unmodifiable list.
      expect(() => store.add(ToastEvent.success(message: 'b')), throwsA(isA<UnsupportedError>()));
    });
  });

  // ========================================================================
  // GroupCollapser
  // ========================================================================
  group('GroupCollapser', () {
    test('records and counts', () {
      final collapser = GroupCollapser(
        groupWindow: const Duration(seconds: 5),
        collapseThreshold: 3,
      );
      final e1 = ToastEvent.success(message: 'same');
      final e2 = ToastEvent.success(message: 'same');
      final e3 = ToastEvent.success(message: 'same');

      expect(collapser.recordAndCount(e1), 1);
      expect(collapser.recordAndCount(e2), 2);
      expect(collapser.recordAndCount(e3), 3);
    });

    test('shouldCollapse after threshold', () {
      final collapser = GroupCollapser(
        groupWindow: const Duration(seconds: 5),
        collapseThreshold: 2,
      );
      final e1 = ToastEvent.success(message: 'repeated');
      final e2 = ToastEvent.success(message: 'repeated');

      collapser.recordAndCount(e1);
      expect(collapser.shouldCollapse(e1), isFalse);
      collapser.recordAndCount(e2);
      expect(collapser.shouldCollapse(e2), isTrue);
    });

    test('uses deduplication key for grouping', () {
      final collapser = GroupCollapser();
      final e1 = ToastEvent.success(message: 'a', deduplicationKey: 'key1');
      final e2 = ToastEvent.success(message: 'b', deduplicationKey: 'key1');

      collapser.recordAndCount(e1);
      expect(collapser.recordAndCount(e2), 2);
    });

    test('different messages create separate groups', () {
      final collapser = GroupCollapser();
      final e1 = ToastEvent.success(message: 'msg1');
      final e2 = ToastEvent.success(message: 'msg2');

      collapser.recordAndCount(e1);
      expect(collapser.recordAndCount(e2), 1);
    });

    test('countFor and lastIdFor', () {
      final collapser = GroupCollapser();
      final e1 = ToastEvent.success(message: 'test');
      final e2 = ToastEvent.success(message: 'test');

      collapser.recordAndCount(e1);
      collapser.recordAndCount(e2);

      expect(collapser.countFor('test'), 2);
      expect(collapser.lastIdFor('test'), e2.id);
    });

    test('clear resets tracking', () {
      final collapser = GroupCollapser();
      collapser.recordAndCount(ToastEvent.success(message: 'msg'));
      collapser.clear();
      expect(collapser.countFor('msg'), 0);
    });

    test('groupKeyFor returns deduplication key first', () {
      final collapser = GroupCollapser();
      final e = ToastEvent.success(message: 'msg', deduplicationKey: 'key');
      expect(collapser.groupKeyFor(e), 'key');
    });

    test('groupKeyFor falls back to message', () {
      final collapser = GroupCollapser();
      final e = ToastEvent.success(message: 'msg');
      expect(collapser.groupKeyFor(e), 'msg');
    });
  });

  // ========================================================================
  // ToastThemeData
  // ========================================================================
  group('ToastThemeData', () {
    test('light theme has bright background', () {
      final t = ToastThemeData.light();
      expect(t.backgroundColor.computeLuminance(), greaterThan(0.5));
    });

    test('dark theme has dark background', () {
      final t = ToastThemeData.dark();
      expect(t.backgroundColor.computeLuminance(), lessThan(0.5));
    });

    test('copyWith', () {
      final t = ToastThemeData.light();
      final m = t.copyWith(elevation: 20.0);
      expect(m.elevation, 20.0);
      expect(m.backgroundColor, t.backgroundColor);
    });
  });

  // ========================================================================
  // ToastPositionCalculator
  // ========================================================================
  group('ToastPositionCalculator', () {
    test('toAlignment', () {
      expect(ToastPositionCalculator.toAlignment(ToastPosition.top), Alignment.topCenter);
      expect(ToastPositionCalculator.toAlignment(ToastPosition.bottom), Alignment.bottomCenter);
      expect(ToastPositionCalculator.toAlignment(ToastPosition.center), Alignment.center);
    });

    test('calculateStackOffset', () {
      expect(ToastPositionCalculator.calculateStackOffset(0, 8.0), 0.0);
      expect(ToastPositionCalculator.calculateStackOffset(1, 8.0), 8.0);
      expect(ToastPositionCalculator.calculateStackOffset(3, 10.0), 30.0);
    });

    test('flipForRtl', () {
      expect(ToastPositionCalculator.flipForRtl(ToastPosition.topLeft, true), ToastPosition.topRight);
      expect(ToastPositionCalculator.flipForRtl(ToastPosition.topRight, true), ToastPosition.topLeft);
      expect(ToastPositionCalculator.flipForRtl(ToastPosition.topLeft, false), ToastPosition.topLeft);
    });
  });

  // ========================================================================
  // Animation curves
  // ========================================================================
  group('Animation curves', () {
    test('BounceCurve endpoints', () {
      const c = BounceCurve();
      expect(c.transform(0.0), closeTo(0.0, 0.01));
      expect(c.transform(1.0), closeTo(1.0, 0.01));
    });

    test('ElasticCurve endpoints', () {
      const c = ElasticCurve();
      expect(c.transform(0.0), closeTo(0.0, 0.05));
      expect(c.transform(1.0), closeTo(1.0, 0.05));
    });

    test('OvershootCurve endpoints', () {
      const c = OvershootCurve();
      expect(c.transform(0.0), closeTo(0.0, 0.01));
      expect(c.transform(1.0), closeTo(1.0, 0.01));
    });

    test('SpringCurve endpoints', () {
      const c = SpringCurve();
      expect(c.transform(0.0), closeTo(0.0, 0.01));
      expect(c.transform(1.0), closeTo(1.0, 0.05));
    });
  });

  // ========================================================================
  // ToastVariant enum
  // ========================================================================
  group('ToastVariant', () {
    test('has >= 10 values', () {
      expect(ToastVariant.values.length, greaterThanOrEqualTo(10));
    });

    test('key variants exist', () {
      expect(ToastVariant.values, contains(ToastVariant.minimal));
      expect(ToastVariant.values, contains(ToastVariant.material));
      expect(ToastVariant.values, contains(ToastVariant.glassmorphism));
      expect(ToastVariant.values, contains(ToastVariant.gradient));
      expect(ToastVariant.values, contains(ToastVariant.loading));
      expect(ToastVariant.values, contains(ToastVariant.debug));
    });
  });
}
