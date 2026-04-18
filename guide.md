# ToastKit Guide

---

## 📦 Project Description *(~200 characters)*

> **ToastKit** — A production-grade Flutter SDK for in-app toast notifications. Event-driven, context-free, with queue management, smart rules, 12+ visual variants & a plugin system.

---

## 🚀 What Does This Package Do?

**ToastKit** is a complete, production-ready notification pipeline for Flutter apps. Unlike basic overlay wrappers, it handles the full lifecycle of in-app toasts:

| Capability | Description |
|---|---|
| **No BuildContext needed** | Call `ToastKit.success()` from services, blocs, or repositories — anywhere in your app |
| **Stateful toasts** | `ToastController` enables seamless Loading → Success / Error transitions |
| **Queue management** | FIFO, LIFO, or priority-based ordering with bounded queue sizes |
| **Channel system** | Named channels (e.g. `auth`, `network`, `payment`) with independent policies per channel |
| **Deduplication & throttling** | Prevents the same message from spamming the user |
| **Smart rule engine** | Config-based rules: "after 5 network errors → show help toast" — automatically evaluated |
| **12+ visual variants** | Minimal, Material 3, iOS, Glassmorphism, Gradient, Compact, and more |
| **9 animation presets** | Fade, slide, scale, bounce, elastic, spring, shake, blur, glow |
| **Plugin architecture** | Hook into lifecycle events (shown, dismissed, queued, dropped) for analytics or haptics |
| **Gesture support** | Swipe to dismiss, tap callbacks, pause-on-hover |
| **Accessibility** | Semantic labels and screen reader support built-in |
| **Zero external dependencies** | Only depends on the Flutter SDK |

**Quick usage:**
```dart
// One-liner toasts — no context required
ToastKit.success('File saved!');
ToastKit.error('Network failed');
ToastKit.warning('Low battery');
ToastKit.info('New update available');

// Stateful loading → result transition
final ctrl = ToastKit.showLoading('Uploading…');
await uploadFile();
ctrl.success('Upload complete!');
```

---

## 🌐 Live Preview

Explore the interactive demo here:
**[https://toast-brown.vercel.app/](https://toast-brown.vercel.app/)**

---

## 🎨 Engineering Prompt — Image Poster

Use the following prompt with any AI image generator (Midjourney, DALL·E 3, Stable Diffusion, Firefly, etc.) to create a promotional poster for ToastKit:

```
A sleek, dark-mode tech poster for a Flutter package called "ToastKit".
The centerpiece is a modern smartphone displaying multiple layered in-app
toast notification cards in different styles — glassmorphism, Material 3,
and gradient — floating above the screen like a holographic stack.
Each toast card shows a different state: a green success checkmark
("File saved!"), a red error icon ("Network failed"), an amber warning
("Low battery"), and a blue info badge ("New update available").
Behind the phone, a subtle neon-teal event-flow diagram with arrows and
nodes illustrates the pipeline: EventBus → QueueManager → OverlayEngine.
Typography: "ToastKit" in bold futuristic sans-serif at the top, tagline
"Production-grade Flutter Toasts. Zero BuildContext." below in smaller
text. Color palette: deep navy background (#0A0E1A), neon teal (#00E5CC),
electric violet (#7B2FFF), and white text. Clean, minimal, developer-
aesthetic. 4K resolution, high detail, product-launch style.
```

---

## 💼 LinkedIn Caption

```
🚀 Introducing ToastKit — a production-grade Flutter package for in-app
toast notifications, built for real-world apps.

Most toast libraries stop at a simple overlay. ToastKit goes further:

✅ No BuildContext required — show toasts from anywhere
🔄 Stateful toasts — Loading → Success/Error transitions
📬 Queue management — FIFO, LIFO, priority ordering
🔀 Channel system — independent policies per notification category
🧠 Smart rule engine — auto-trigger actions after N errors
🎨 12+ visual variants — Glassmorphism, Material 3, iOS, Gradient & more
🔌 Plugin architecture — analytics, haptics, logging with zero coupling
♿ Accessible by default — semantic labels & screen reader support

Whether you're building an e-commerce app, a fintech product, or a
complex enterprise tool — ToastKit handles your notification pipeline
so you don't have to.

🌐 Live Demo → https://toast-brown.vercel.app/
📦 pub.dev → https://pub.dev/packages/toast_kit
💻 GitHub → https://github.com/yasersabri580-oss/toast-kit

#Flutter #Dart #MobileAppDevelopment #OpenSource #FlutterDev #SDK
#UIComponents #FlutterPackage #ToastKit
```

---

## ✈️ Telegram Caption & Description

### Caption *(short — for channel post preview)*

```
🔔 ToastKit v1.0 — Production-grade Flutter toast notifications.

No BuildContext. Stateful transitions. Queue management. Rule engine.
12+ visual variants. Zero external dependencies.

🌐 Live Demo: https://toast-brown.vercel.app/
📦 pub.dev: https://pub.dev/packages/toast_kit
```

### Description *(full — for pinned post or bot description)*

```
🚀 ToastKit — Flutter In-App Toast SDK

ToastKit is a complete notification pipeline for Flutter apps.
Show elegant, stateful toast notifications from anywhere in your codebase
— no BuildContext, no boilerplate.

🔑 Key Features:
• ToastKit.success() / .error() / .warning() / .info() — call from anywhere
• ToastController — seamless Loading → Success / Error flow
• Channel system — named channels with independent policies
• Deduplication & throttling — no message spam
• Smart rule engine — trigger toasts or actions based on error counts
• 12+ visual styles — Glassmorphism, Material 3, iOS, Gradient, Compact…
• 9 animation presets — fade, slide, bounce, spring, shake, glow…
• Plugin hooks — analytics, haptics, logging without touching core code
• Accessibility-ready — semantic labels & screen reader support
• Zero external dependencies — pure Flutter SDK

🌐 Live Demo: https://toast-brown.vercel.app/
📦 Install: flutter pub add toast_kit
💻 GitHub: https://github.com/yasersabri580-oss/toast-kit
📖 Docs: https://github.com/yasersabri580-oss/toast-kit/tree/main/document
```

---

*Made with ❤️ for the Flutter community.*
