import 'package:flutter/material.dart';
import 'package:toast_kit/toast_kit.dart';

// ---------------------------------------------------------------------------
// Form Validation Scenario
//
// Demonstrates:
// - Toast-based validation feedback
// - Channel-based grouping for form errors
// - Deduplication to prevent repeated warnings
// - Stateful loading for form submission
// ---------------------------------------------------------------------------

class FormValidationScenario extends StatefulWidget {
  const FormValidationScenario({super.key});

  @override
  State<FormValidationScenario> createState() => _FormValidationScenarioState();
}

class _FormValidationScenarioState extends State<FormValidationScenario> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  static const _formChannel = ToastChannel(
    id: 'form',
    label: 'Form Validation',
    maxVisible: 3,
  );

  @override
  void initState() {
    super.initState();
    ToastKit.registerChannel(_formChannel);

    // Rule: after 5 validation errors, suggest help.
    ToastKit.configureRule(
      'form',
      RuleConfig(
        errorThreshold: 5,
        deduplicateWindow: Duration(seconds: 30),
        maxTriggers: 1,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Validate all fields and show toast feedback for each error.
  List<String> _validate() {
    final errors = <String>[];
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      errors.add('Name is required');
    } else if (name.length < 2) {
      errors.add('Name must be at least 2 characters');
    }

    if (email.isEmpty) {
      errors.add('Email is required');
    } else if (!email.contains('@') || !email.contains('.')) {
      errors.add('Please enter a valid email address');
    }

    if (password.isEmpty) {
      errors.add('Password is required');
    } else {
      if (password.length < 8) {
        errors.add('Password must be at least 8 characters');
      }
      if (!password.contains(RegExp(r'[A-Z]'))) {
        errors.add('Password must contain an uppercase letter');
      }
      if (!password.contains(RegExp(r'[0-9]'))) {
        errors.add('Password must contain a number');
      }
    }

    return errors;
  }

  /// Submit the form with validation and loading feedback.
  Future<void> _onSubmit() async {
    ToastKit.dismissAll();

    final errors = _validate();

    if (errors.isNotEmpty) {
      for (final error in errors) {
        ToastKit.warning(error, channel: 'form');
      }
      return;
    }

    // All fields valid — submit with loading state.
    final ctrl = ToastKit.showLoading('Creating your account…');
    try {
      // Simulate network request.
      await Future.delayed(const Duration(seconds: 2));

      // Simulate occasional server errors.
      if (DateTime.now().second % 4 == 0) {
        throw Exception('Server error');
      }

      ctrl.success('Account created! Welcome aboard 🎉');
      _clearForm();
    } catch (e) {
      ctrl.error('Registration failed — please try again');
      ToastKit.error('Registration error', channel: 'form');
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Validation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Enter invalid data and submit to see toast-based validation. '
            'Repeated errors trigger a help suggestion via rules.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _onSubmit,
            child: const Text('Create Account'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _clearForm,
            child: const Text('Clear Form'),
          ),
        ],
      ),
    );
  }
}
