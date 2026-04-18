# Example: Form Validation

Show validation feedback using toast channels with a proactive help rule.

## What This Example Demonstrates

- Channel-based form validation toasts
- Grouped field validation with toast feedback
- Warning vs error severity for different validation issues
- **Custom rule** that offers help after repeated validation failures
- **Combined conditions** using `errorCount` to detect frustrated users

---

## Setup

```dart
void setupFormChannel() {
  const formChannel = ToastChannel(
    id: 'form',
    label: 'Form Validation',
    maxVisible: 2,
    defaultDuration: Duration(seconds: 4),
    defaultPriority: ToastPriority.normal,
  );

  ToastKit.registerChannel(formChannel);

  // Proactive help rule: after 3 failed submissions, offer guidance.
  // maxTriggers: 1 ensures it fires only once (not on every subsequent error).
  ToastKit.addRule(ToastRule(
    id: 'form-help-guide',
    channel: 'form',
    maxTriggers: 1,
    condition: (stats, event) => stats.errorCount >= 3,
    action: (context) {
      ToastKit.show(ToastEvent.info(
        message: 'Having trouble with the form? Check our help guide.',
        variant: ToastVariant.action,
        deduplicationKey: 'form-help-toast',
        actions: [
          ToastAction(
            label: 'View Guide',
            onPressed: () => ToastKit.success('Opening help guide…'),
          ),
          ToastAction(
            label: 'Contact Us',
            onPressed: () => ToastKit.info('Opening contact form…'),
          ),
        ],
        channel: 'form',
      ));
    },
  ));
}
```

## Validation Logic

```dart
class FormValidator {
  /// Validate all fields and show toast feedback.
  /// Returns true if all fields are valid.
  static bool validate({
    required String name,
    required String email,
    required String phone,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // Required field checks
    if (name.trim().isEmpty) {
      errors.add('Name is required');
    }
    if (email.trim().isEmpty) {
      errors.add('Email is required');
    } else if (!email.contains('@')) {
      errors.add('Invalid email format');
    }

    // Soft warnings
    if (phone.trim().isEmpty) {
      warnings.add('Phone number recommended for account recovery');
    }

    // Show per-field warnings
    for (final warning in warnings) {
      ToastKit.warning(warning, channel: 'form');
    }

    // Show errors and record on channel for rule tracking
    if (errors.isNotEmpty) {
      ToastKit.error(
        errors.join('\n'),
        title: '${errors.length} validation error${errors.length > 1 ? 's' : ''}',
        channel: 'form',
      );
      return false;
    }

    return true;
  }
}
```

## Usage in a Form Widget

```dart
class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  Future<void> _submit() async {
    final isValid = FormValidator.validate(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
    );

    if (!isValid) return;

    final ctrl = ToastKit.showLoading('Saving profile…', channel: 'form');

    try {
      await api.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
      );
      ctrl.success('Profile updated!');
    } catch (e) {
      ctrl.error('Failed to save profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
        TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
        TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
        ElevatedButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
```

## What Happens

| Submission | What Fires | User Sees |
|------------|------------|-----------|
| 1st (invalid) | — | Per-field error toast |
| 2nd (invalid) | — | Per-field error toast |
| 3rd (invalid) | `form-help-guide` | Error toast + "Check our help guide" with action buttons |
| 4th+ (invalid) | — | Per-field error toast (help already shown once) |

---

[← Payment Failure](payment_failure.md) | [Next: Custom Toast UI →](custom_toast_ui.md)
