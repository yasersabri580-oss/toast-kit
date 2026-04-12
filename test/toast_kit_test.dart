import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/src/core/toast_config.dart';
import '../lib/src/events/toast_event.dart';
import '../lib/src/events/event_bus.dart';
import '../lib/src/queue/queue_manager.dart';
import '../lib/src/router/notification_router.dart';
import '../lib/src/router/router_config.dart';
import '../lib/src/theme/toast_theme.dart';
import '../lib/src/layout/toast_position_calculator.dart';
import '../lib/src/animation/animation_curves.dart';

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
