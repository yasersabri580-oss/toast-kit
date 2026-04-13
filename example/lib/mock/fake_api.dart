import 'dart:math';

/// Simulates common API call outcomes for demo purposes.
///
/// Each method introduces a short delay and randomly succeeds or fails,
/// making it easy to demonstrate loading states, error toasts, and retry
/// logic without a real backend.
class FakeApi {
  final _random = Random();

  /// Simulates fetching a user profile.
  ///
  /// Returns a map with `name` and `email` on success.
  /// Throws on failure (~60% failure rate).
  Future<Map<String, String>> fetchProfile() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (_random.nextDouble() < 0.6) {
      throw Exception('Server error: unable to fetch profile');
    }
    return {'name': 'Jane Doe', 'email': 'jane@example.com'};
  }

  /// Simulates processing a payment.
  ///
  /// Returns `true` on success (~30% success rate).
  /// Throws different failure types to demonstrate varied error toasts.
  Future<bool> processPayment(double amount) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final roll = _random.nextInt(10);
    if (roll < 3) return true; // success
    if (roll < 5) throw Exception('Card declined');
    if (roll < 7) throw Exception('Insufficient funds');
    if (roll < 9) throw Exception('Network timeout');
    throw Exception('Unknown payment error');
  }

  /// Simulates submitting a form.
  ///
  /// Returns `true` on success (~40% success rate).
  Future<bool> submitForm() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (_random.nextDouble() < 0.4) return true;
    throw Exception('Validation failed on server');
  }
}
