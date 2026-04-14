import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_service.dart';

/// A generic retry service with exponential back-off.
///
/// Reports per-attempt results via [onAttempt] so callers can display toasts.
class RetryService {
  RetryService._();
  static final RetryService instance = RetryService._();

  /// Executes [action] with up to [maxRetries] attempts using exponential
  /// back-off.
  ///
  /// [onAttempt] is called after each failed attempt with the current attempt
  /// number, the total allowed, and the error.
  ///
  /// Returns the result of [action] on success or throws the last error.
  Future<T> withRetry<T>({
    required Future<T> Function() action,
    int maxRetries = 3,
    Duration baseDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    void Function(int attempt, int maxAttempts, Object error)? onAttempt,
    int? generation,
    int Function()? currentGeneration,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      // Guard against stale retries when a newer request supersedes this one.
      if (generation != null && currentGeneration != null) {
        if (generation != currentGeneration()) return Future.error(lastError ?? 'cancelled');
      }
      try {
        return await action();
      } catch (e) {
        lastError = e;
        final msg = e is ApiException ? e.message : e.toString();
        debugPrint(
            '[RetryService] Attempt $attempt/$maxRetries failed: $msg');
        onAttempt?.call(attempt, maxRetries, e);

        if (attempt < maxRetries) {
          final delay = baseDelay * (backoffMultiplier * attempt);
          debugPrint(
              '[RetryService] Waiting ${delay.inMilliseconds}ms before retry…');
          await Future.delayed(delay);
        }
      }
    }
    throw lastError!;
  }
}
