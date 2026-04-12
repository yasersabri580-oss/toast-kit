import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

void main() {
  runApp(const ToastKitExampleApp());
}

class ToastKitExampleApp extends StatefulWidget {
  const ToastKitExampleApp({super.key});

  @override
  State<ToastKitExampleApp> createState() => _ToastKitExampleAppState();
}

class _ToastKitExampleAppState extends State<ToastKitExampleApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ToastKit.init(
        navigatorKey: _navigatorKey,
        config: const ToastConfig(
          defaultPosition: ToastPosition.top,
          maxVisibleToasts: 3,
        ),
      );
    });
  }

  @override
  void dispose() {
    ToastKit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'ToastKit Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ToastKit SDK Demo'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Basic Toasts'),
          _row([
            _btn('Success', Colors.green, () => ToastKit.success('Operation completed!')),
            _btn('Error', Colors.red, () => ToastKit.error('Something went wrong.')),
          ]),
          const SizedBox(height: 8),
          _row([
            _btn('Warning', Colors.orange, () => ToastKit.warning('Battery low.')),
            _btn('Info', Colors.blue, () => ToastKit.info('New update available.')),
          ]),
          const SizedBox(height: 8),
          _btn('Loading', Colors.purple, () => ToastKit.loading('Processing…')),

          const SizedBox(height: 24),
          _section('Variants'),
          _btn('Minimal', Colors.teal, () {
            ToastKit.show(ToastEvent.success(message: 'Minimal style', variant: ToastVariant.minimal));
          }),
          const SizedBox(height: 8),
          _btn('Glassmorphism', Colors.indigo, () {
            ToastKit.show(ToastEvent.info(message: 'Frosted glass', variant: ToastVariant.glassmorphism));
          }),
          const SizedBox(height: 8),
          _btn('Gradient', Colors.pink, () {
            ToastKit.show(ToastEvent.error(message: 'Gradient background', variant: ToastVariant.gradient));
          }),
          const SizedBox(height: 8),
          _btn('Compact', Colors.cyan, () {
            ToastKit.show(ToastEvent.success(message: 'Compact!', variant: ToastVariant.compact));
          }),
          const SizedBox(height: 8),
          _btn('Full Width', Colors.amber.shade800, () {
            ToastKit.show(ToastEvent.warning(message: 'Full-width banner', variant: ToastVariant.fullWidth));
          }),
          const SizedBox(height: 8),
          _btn('Debug', Colors.grey.shade800, () {
            ToastKit.show(ToastEvent.info(message: 'Debug info', variant: ToastVariant.debug));
          }),

          const SizedBox(height: 24),
          _section('Action Toasts'),
          _btn('With Actions', Colors.deepOrange, () {
            ToastKit.show(ToastEvent.error(
              message: 'Failed to send',
              variant: ToastVariant.action,
              actions: [
                ToastAction(label: 'Retry', onPressed: () {}),
                ToastAction(label: 'Cancel', onPressed: () {}),
              ],
            ));
          }),

          const SizedBox(height: 24),
          _section('Positions'),
          _row([
            _btn('Top', Colors.blueGrey, () {
              ToastKit.show(ToastEvent.info(message: 'Top', position: ToastPosition.top));
            }),
            _btn('Center', Colors.blueGrey, () {
              ToastKit.show(ToastEvent.info(message: 'Center', position: ToastPosition.center));
            }),
            _btn('Bottom', Colors.blueGrey, () {
              ToastKit.show(ToastEvent.info(message: 'Bottom', position: ToastPosition.bottom));
            }),
          ]),

          const SizedBox(height: 24),
          _section('Management'),
          _btn('Dismiss All', Colors.red.shade900, () => ToastKit.dismissAll()),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _row(List<Widget> children) => Row(
        children: children
            .expand((c) => [Expanded(child: c), const SizedBox(width: 8)])
            .toList()
          ..removeLast(),
      );

  Widget _btn(String label, Color color, VoidCallback onTap) => FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(backgroundColor: color),
        child: Text(label),
      );
}
