import 'dart:async';
import 'dart:math';

/// Simulates a backend API with configurable failure rates and latency.
///
/// Used across all feature demos to produce realistic async behaviour.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final _rng = Random();

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  /// Simulates a login attempt.
  ///
  /// Returns a user map on success or throws [ApiException].
  Future<Map<String, dynamic>> login(String email, String password) async {
    await _latency(800, 2000);
    if (email.isEmpty || password.isEmpty) {
      throw const ApiException(
        code: 'invalid_input',
        message: 'Email and password are required',
      );
    }
    // 40 % chance of failure
    if (_rng.nextDouble() < 0.4) {
      final errors = [
        const ApiException(
            code: 'invalid_credentials',
            message: 'Invalid email or password'),
        const ApiException(
            code: 'account_locked',
            message: 'Account locked — too many attempts'),
        const ApiException(
            code: 'rate_limited',
            message: 'Rate limit exceeded — try again later'),
      ];
      throw errors[_rng.nextInt(errors.length)];
    }
    return {
      'uid': 'usr_${_rng.nextInt(99999)}',
      'email': email,
      'name': 'Demo User',
      'token': 'tok_${_rng.nextInt(99999)}',
    };
  }

  /// Simulates a logout call.
  Future<void> logout() async {
    await _latency(300, 800);
    if (_rng.nextDouble() < 0.1) {
      throw const ApiException(
          code: 'logout_failed', message: 'Session invalidation failed');
    }
  }

  // ---------------------------------------------------------------------------
  // Network / Data fetching
  // ---------------------------------------------------------------------------

  /// Fetches a user profile — may fail to demonstrate retry logic.
  Future<Map<String, dynamic>> fetchProfile() async {
    await _latency(500, 1500);
    if (_rng.nextDouble() < 0.6) {
      throw const ApiException(
          code: 'network_error', message: 'Connection timed out');
    }
    return {
      'name': 'Alex Johnson',
      'email': 'alex@example.com',
      'role': 'Admin',
    };
  }

  /// Fetches a list of items — used in deduplication demos.
  Future<List<Map<String, dynamic>>> fetchItems() async {
    await _latency(400, 1200);
    if (_rng.nextDouble() < 0.5) {
      throw const ApiException(
          code: 'server_error', message: 'Internal server error');
    }
    return List.generate(
      5,
      (i) => {'id': i, 'title': 'Item $i', 'value': _rng.nextInt(1000)},
    );
  }

  /// Simulates fetching dashboard stats.
  Future<Map<String, int>> fetchDashboardStats() async {
    await _latency(300, 900);
    if (_rng.nextDouble() < 0.3) {
      throw const ApiException(
          code: 'stats_error', message: 'Failed to load dashboard stats');
    }
    return {
      'users': _rng.nextInt(5000) + 1000,
      'revenue': _rng.nextInt(50000) + 10000,
      'orders': _rng.nextInt(500) + 100,
      'tickets': _rng.nextInt(50) + 5,
    };
  }

  // ---------------------------------------------------------------------------
  // Payments
  // ---------------------------------------------------------------------------

  /// Processes a payment — may fail with typed errors.
  Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String method,
  }) async {
    await _latency(1500, 3000);
    if (amount <= 0) {
      throw const ApiException(
          code: 'invalid_amount', message: 'Amount must be positive');
    }
    final failChance = _rng.nextDouble();
    if (failChance < 0.15) {
      throw const PaymentException(
          code: 'card_declined', message: 'Card was declined');
    }
    if (failChance < 0.30) {
      throw const PaymentException(
          code: 'insufficient_funds', message: 'Insufficient funds');
    }
    if (failChance < 0.40) {
      throw const PaymentException(
          code: 'network_timeout', message: 'Payment gateway timeout');
    }
    return {
      'transaction_id': 'txn_${_rng.nextInt(99999)}',
      'amount': amount,
      'method': method,
      'status': 'completed',
    };
  }

  /// Cancels a payment.
  Future<void> cancelPayment(String transactionId) async {
    await _latency(500, 1000);
    if (_rng.nextDouble() < 0.2) {
      throw const ApiException(
          code: 'cancel_failed', message: 'Cannot cancel completed payment');
    }
  }

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  /// Fetches pending notifications from the mock backend.
  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    await _latency(300, 800);
    final count = _rng.nextInt(5) + 1;
    return List.generate(count, (i) {
      final types = ['message', 'alert', 'promotion', 'system', 'reminder'];
      return {
        'id': 'notif_${_rng.nextInt(99999)}',
        'type': types[_rng.nextInt(types.length)],
        'title': 'Notification ${i + 1}',
        'body': 'This is notification body ${i + 1}.',
        'read': false,
      };
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _latency(int minMs, int maxMs) =>
      Future.delayed(Duration(milliseconds: minMs + _rng.nextInt(maxMs - minMs)));
}

// ---------------------------------------------------------------------------
// Exception types
// ---------------------------------------------------------------------------

class ApiException implements Exception {
  const ApiException({required this.code, required this.message});
  final String code;
  final String message;

  @override
  String toString() => 'ApiException($code): $message';
}

class PaymentException extends ApiException {
  const PaymentException({required super.code, required super.message});
}
