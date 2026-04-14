# Example: Form Validation

Show validation feedback using toast channels.

## What This Example Demonstrates

- Channel-based form validation toasts
- Grouped field validation with toast feedback
- Warning vs error severity for different validation issues

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

    // Show errors first
    if (errors.isNotEmpty) {
      ToastKit.error(
        errors.join('\n'),
        title: '${errors.length} validation error${errors.length > 1 ? 's' : ''}',
        channel: 'form',
      );
      return false;
    }

    // Then show warnings
    if (warnings.isNotEmpty) {
      ToastKit.warning(
        warnings.join('\n'),
        channel: 'form',
      );
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

---

[← Payment Failure](payment_failure.md) | [Next: Custom Toast UI →](custom_toast_ui.md)
