# 🎬 ToastKit Video Tutorial Plan

A structured plan for an 8–12 minute developer tutorial covering the full ToastKit SDK.

---

## Segment 1: Introduction (1–1.5 min)

**Goal:** Hook the viewer by showing the problem and the value proposition.

### Talking Points

- **The problem:** Flutter apps need toast notifications, but most packages are simple wrappers around `OverlayEntry` with no real logic, no deduplication, no rules, and no plugin system.
- **The value:** ToastKit is a production-grade notification engine with rule-based triggering, a plugin architecture, queue management, and 12+ built-in variants — all without requiring `BuildContext`.
- **Quick demo reel:** Show a rapid montage of different toast variants, animations, and the loading → success transition.
- **What you'll learn:** By the end, viewers will know how to initialize ToastKit, show all toast types, configure rules, build plugins, and create custom UI.

---

## Segment 2: Setup (1–1.5 min)

**Goal:** Get the viewer from zero to a running app with ToastKit.

### Content

1. Add the dependency to `pubspec.yaml`:
   ```yaml
   dependencies:
     toast_kit:
       git:
         url: https://github.com/yasersabri580-oss/toast-kit.git
   ```
2. Run `flutter pub get`.
3. Create a `GlobalKey<NavigatorState>` and pass it to `MaterialApp`.
4. Call `ToastKit.init(navigatorKey: key)` inside `addPostFrameCallback`.
5. Show the first toast: `ToastKit.success('Hello, ToastKit!')`.

### Screen Recording

- VS Code / Android Studio with the terminal visible.
- Hot restart to show the app running.

---

## Segment 3: Basic Usage (1.5–2 min)

**Goal:** Cover all convenience methods and the stateful loading pattern.

### Content

1. **Convenience methods:**
   - `ToastKit.success('Done!')`
   - `ToastKit.error('Oops')`
   - `ToastKit.warning('Low battery')`
   - `ToastKit.info('Update available')`
   - `ToastKit.loading('Processing…')`

2. **Stateful loading → success/error:**
   ```dart
   final ctrl = ToastKit.showLoading('Saving…');
   try {
     await saveData();
     ctrl.success('Saved!');
   } catch (_) {
     ctrl.error('Save failed');
   }
   ```

3. **Variants showcase:** Quickly demo 4–5 variants (minimal, glassmorphism, gradient, compact, full-width).

4. **Action toasts:** Show a toast with Retry / Cancel buttons.

### Screen Recording

- Tap each button on the demo app, showing the toast appear and dismiss.
- Highlight the loading → success transition on screen.

---

## Segment 4: Rules Deep Dive (2–2.5 min)

**Goal:** Explain the rule system — channels, config rules, and custom rules.

### Content

1. **What are channels?** Logical groupings for toasts (auth, network, payment).
   - Register channels: `ToastKit.registerChannel(ToastChannel.auth)`
   - Send toast on a channel: `ToastKit.error('Fail', channel: 'auth')`

2. **Config-based rules:**
   ```dart
   ToastKit.configureRule('auth', RuleConfig(
     errorThreshold: 3,
     deduplicateWindow: Duration(seconds: 60),
     maxTriggers: 1,
   ));
   ```
   - Explain each parameter with a diagram or on-screen annotation.

3. **Custom rules:**
   ```dart
   ToastKit.addRule(ToastRule(
     id: 'login-lockout',
     channel: 'auth',
     condition: (stats, event) => stats.errorCount >= 5,
     action: (context) { /* lock form */ },
   ));
   ```

4. **Live demo:** Run the login scenario — show 3 failures triggering a password reset suggestion, then 5 failures triggering lockout.

### Visual Aids

- On-screen flow diagram: `ToastEvent → Channel → RuleEngine → Action`.
- Counter overlay showing error count increasing.

---

## Segment 5: Plugins (1.5–2 min)

**Goal:** Show the plugin architecture and build a plugin live.

### Content

1. **Plugin interface overview:** Show the `ToastPlugin` base class and list the available hooks.

2. **Build a LoggerPlugin live:**
   ```dart
   class LoggerPlugin extends ToastPlugin {
     @override
     String get name => 'logger';

     @override
     void onToastShown(ToastEvent event) {
       print('[TOAST] ${event.type.name}: ${event.message}');
     }
     
   }
   ```

3. **Register it:**
   ```dart
   ToastKit.init(navigatorKey: key, plugins: [LoggerPlugin()]);
   ```

4. **Show console output** while toasts fire — demonstrate the plugin receiving events.

5. **Mention other plugin ideas:** AnalyticsPlugin (Firebase), HapticsPlugin (vibration), SentryPlugin (error tracking).

### Screen Recording

- Split screen: app on left, debug console on right.
- Show log lines appearing as toasts are shown, queued, and dismissed.

---

## Segment 6: Custom UI (1–1.5 min)

**Goal:** Demonstrate the custom builder API for full toast control.

### Content

1. **Basic custom builder:**
   ```dart
   ToastKit.custom(builder: (context, controller) {
     return Container(
       padding: const EdgeInsets.all(16),
       color: Colors.deepPurple,
       child: Text('Custom!', style: TextStyle(color: Colors.white)),
     );
   });
   ```

2. **Using ToastController:** Show `controller.dismiss()`, `controller.messageNotifier`, `controller.progress`.

3. **Build an upload progress toast live:** A custom toast with a progress bar that fills up and transitions to success.

### Screen Recording

- Code the builder on screen, hot restart, show the result.
- Highlight the progress bar animation.

---

## Segment 7: Real-World Scenarios (1.5–2 min)

**Goal:** Show practical application in a real app context.

### Content

1. **API error handling:**
   - `showLoading` → `try/catch` → `ctrl.success()` or `ctrl.error()`.
   - Channel-based error tracking with deduplication.

2. **Form validation:**
   - Validate fields, show `ToastKit.warning()` per error.
   - Rule triggers help suggestion after repeated validation errors.

3. **Payment flow:**
   - Loading toast during processing.
   - Multiple failure types (declined, insufficient funds, network).
   - Rule offers support chat after 3 failures.

### Screen Recording

- Walk through each scenario in the demo app.
- Show the rule triggering on screen.

---

## Segment 8: Best Practices & Wrap-Up (0.5–1 min)

**Goal:** Leave the viewer with actionable best practices.

### Content

1. **Initialize once** — call `ToastKit.init()` in `addPostFrameCallback`, not in `build()`.
2. **Use channels** — group related toasts for better rule targeting.
3. **Use deduplication keys** — prevent duplicate toasts during rapid events.
4. **Keep plugins lightweight** — plugins should observe, not block. Avoid heavy computation.
5. **Dispose properly** — call `ToastKit.dispose()` when the app shuts down.
6. **Test your rules** — the `RuleEngine` is unit-testable independently.

### Closing

- Link to GitHub repo and README.
- Encourage viewers to star the repo and open issues.
- "Thanks for watching — now go build something great with ToastKit!"

---

## Production Notes

| Item | Details |
|------|---------|
| **Target length** | 8–12 minutes |
| **Recording tool** | Screen recorder + IDE + emulator side-by-side |
| **Code font** | JetBrains Mono or Fira Code, 16pt |
| **Diagrams** | Use Excalidraw or Figma for flow diagrams |
| **Editing** | Cut pauses, add zoom-ins on important code sections |
| **Thumbnail** | ToastKit logo + "Smart Toasts for Flutter" text |
| **Platform** | YouTube, with chapters for each segment |
