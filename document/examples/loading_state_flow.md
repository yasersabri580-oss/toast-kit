# Example: Loading State Flow

The loading → result pattern is the most powerful feature in ToastKit. This example shows all variations.

## What This Example Demonstrates

- `showLoading` → `ctrl.success()` / `ctrl.error()` flow
- Progress updates during operations
- Multi-step operations with state transitions
- Proper error handling and cleanup

---

## Basic Loading → Result

```dart
Future<void> saveSettings(Map<String, dynamic> settings) async {
  final ctrl = ToastKit.showLoading('Saving settings…');

  try {
    await api.updateSettings(settings);
    ctrl.success('Settings saved!');
  } catch (e) {
    ctrl.error('Failed to save settings');
  }
}
```

## With Progress Updates

```dart
Future<void> syncData() async {
  final ctrl = ToastKit.showLoading('Syncing…');

  try {
    final items = await api.fetchPendingSync();

    for (int i = 0; i < items.length; i++) {
      ctrl.update(
        message: 'Syncing ${i + 1}/${items.length}…',
        progressValue: (i + 1) / items.length,
      );
      await api.syncItem(items[i]);
    }

    ctrl.success('${items.length} items synced!');
  } catch (e) {
    ctrl.error('Sync failed');
  }
}
```

## Multi-Step Operation

```dart
Future<void> publishArticle(Article article) async {
  final ctrl = ToastKit.showLoading('Validating…');

  try {
    // Step 1: Validate
    await api.validate(article);
    ctrl.update(message: 'Uploading images…', progressValue: 0.33);

    // Step 2: Upload images
    for (final image in article.images) {
      await api.uploadImage(image);
    }
    ctrl.update(message: 'Publishing…', progressValue: 0.66);

    // Step 3: Publish
    await api.publish(article);
    ctrl.success('Article published!');
  } on ValidationException catch (e) {
    ctrl.error('Validation failed: ${e.message}');
  } on UploadException {
    ctrl.error('Image upload failed');
  } catch (e) {
    ctrl.error('Publish failed');
  }
}
```

## Loading with Channel

```dart
Future<void> checkout() async {
  // Loading toast on the payment channel
  final ctrl = ToastKit.showLoading(
    'Processing payment…',
    channel: 'payment',
  );

  try {
    await paymentService.processPayment();
    ctrl.success('Payment complete!');
  } catch (e) {
    ctrl.error('Payment failed');
    // Record error on the channel for rule evaluation
    ToastKit.error('Payment error', channel: 'payment');
  }
}
```

## Loading Exclusivity

Only one loading toast exists at a time. Creating a new one dismisses the previous:

```dart
// First loading toast
final ctrl1 = ToastKit.showLoading('Step 1…');

// This automatically dismisses ctrl1
final ctrl2 = ToastKit.showLoading('Step 2…');

// ctrl1 is now dismissed — calling ctrl1.success() is a safe no-op
ctrl1.success('This does nothing — already dismissed');

// ctrl2 is the active loading toast
ctrl2.success('Step 2 complete!');
```

## Safe Controller Usage

Controllers handle disposal gracefully:

```dart
final ctrl = ToastKit.showLoading('Working…');

// Safe even after disposal — update() checks isDisposed
ctrl.update(message: 'Still working…');

// Dismiss
ctrl.dismiss();

// All subsequent calls are safe no-ops
ctrl.success('Too late');  // No effect
ctrl.error('Too late');    // No effect
ctrl.update(message: 'x'); // No effect
```

---

[← Custom Toast UI](custom_toast_ui.md) | [Back to Examples Index →](index.md)
