import 'dart:async';
import 'dart:io';

/// Comprehensive error handling utilities for the application
class ErrorHandler {
  static const int maxRetryAttempts = 3;
  static const Duration baseRetryDelay = Duration(seconds: 2);

  /// Handle network-related errors with appropriate user messages
  static String handleNetworkError(dynamic error) {
    if (error is SocketException) {
      return 'Network connection failed. Please check your WiFi connection.';
    } else if (error is TimeoutException) {
      return 'Connection timed out. Please try again.';
    } else if (error is HttpException) {
      return 'Server error occurred. Please try again later.';
    } else if (error.toString().contains('Connection refused')) {
      return 'Unable to connect to host. Make sure the host is still active.';
    } else if (error.toString().contains('Network is unreachable')) {
      return 'Network is unreachable. Please check your connection.';
    }
    
    return 'Network error occurred: ${error.toString()}';
  }

  /// Handle game-related errors
  static String handleGameError(dynamic error) {
    final errorMessage = error.toString().toLowerCase();
    
    if (errorMessage.contains('not enough players')) {
      return 'Not enough players to start the game.';
    } else if (errorMessage.contains('too many players')) {
      return 'Too many players for this game type.';
    } else if (errorMessage.contains('invalid action')) {
      return 'Invalid game action. Please try again.';
    } else if (errorMessage.contains('not your turn')) {
      return 'It\'s not your turn yet. Please wait.';
    } else if (errorMessage.contains('game not found')) {
      return 'Game session not found. It may have ended.';
    } else if (errorMessage.contains('unsupported game')) {
      return 'This game type is not supported.';
    }
    
    return 'Game error: ${error.toString()}';
  }

  /// Handle lobby-related errors
  static String handleLobbyError(dynamic error) {
    final errorMessage = error.toString().toLowerCase();
    
    if (errorMessage.contains('lobby not found')) {
      return 'Lobby not found. It may have been closed.';
    } else if (errorMessage.contains('lobby is full')) {
      return 'This lobby is full. Try joining another one.';
    } else if (errorMessage.contains('already in lobby')) {
      return 'You are already in this lobby.';
    } else if (errorMessage.contains('invalid lobby')) {
      return 'Invalid lobby information provided.';
    } else if (errorMessage.contains('host left')) {
      return 'The host has left the lobby.';
    }
    
    return 'Lobby error: ${error.toString()}';
  }

  /// Determine if an error is retryable
  static bool isRetryableError(dynamic error) {
    if (error is SocketException || error is TimeoutException) {
      return true;
    }
    
    final errorMessage = error.toString().toLowerCase();
    return errorMessage.contains('connection') ||
           errorMessage.contains('timeout') ||
           errorMessage.contains('network') ||
           errorMessage.contains('unreachable');
  }

  /// Get retry delay with exponential backoff
  static Duration getRetryDelay(int attemptNumber) {
    return baseRetryDelay * (attemptNumber * attemptNumber);
  }

  /// Create user-friendly error message based on error type
  static String getUserFriendlyMessage(dynamic error, ErrorContext context) {
    switch (context) {
      case ErrorContext.network:
        return handleNetworkError(error);
      case ErrorContext.game:
        return handleGameError(error);
      case ErrorContext.lobby:
        return handleLobbyError(error);
      case ErrorContext.general:
      default:
        return 'An unexpected error occurred: ${error.toString()}';
    }
  }

  /// Log error for debugging purposes
  static void logError(dynamic error, StackTrace? stackTrace, {String? context}) {
    print('ERROR${context != null ? ' [$context]' : ''}: $error');
    if (stackTrace != null) {
      print('STACK TRACE: $stackTrace');
    }
  }
}

/// Error context for determining appropriate error handling
enum ErrorContext {
  network,
  game,
  lobby,
  general,
}

/// Retry mechanism utility
class RetryMechanism {
  final int maxAttempts;
  final Duration baseDelay;
  final bool useExponentialBackoff;

  RetryMechanism({
    this.maxAttempts = 3,
    this.baseDelay = const Duration(seconds: 2),
    this.useExponentialBackoff = true,
  });

  /// Execute a function with retry logic
  Future<T> execute<T>(
    Future<T> Function() operation, {
    bool Function(dynamic error)? shouldRetry,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    int attempts = 0;
    dynamic lastError;

    while (attempts < maxAttempts) {
      try {
        return await operation();
      } catch (error) {
        lastError = error;
        attempts++;

        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(error)) {
          rethrow;
        }

        // If this was the last attempt, rethrow the error
        if (attempts >= maxAttempts) {
          rethrow;
        }

        // Calculate delay
        Duration delay = useExponentialBackoff
            ? baseDelay * (attempts * attempts)
            : baseDelay;

        // Notify about retry attempt
        onRetry?.call(attempts, error);

        // Wait before retrying
        await Future.delayed(delay);
      }
    }

    // This should never be reached, but just in case
    throw lastError ?? Exception('Unknown error during retry mechanism');
  }
}

/// Error recovery strategies
class ErrorRecoveryStrategy {
  /// Attempt to recover from network errors
  static Future<bool> recoverFromNetworkError(dynamic error) async {
    // Wait a bit and try to reconnect
    await Future.delayed(const Duration(seconds: 1));
    
    try {
      // Try to ping a reliable host to check connectivity
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Attempt to recover from game synchronization errors
  static Future<bool> recoverFromSyncError() async {
    // For now, just wait a bit to allow network to stabilize
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  /// Attempt to recover from lobby connection errors
  static Future<bool> recoverFromLobbyError(dynamic error) async {
    final errorMessage = error.toString().toLowerCase();
    
    if (errorMessage.contains('connection') || errorMessage.contains('timeout')) {
      return await recoverFromNetworkError(error);
    }
    
    // For other lobby errors, no automatic recovery
    return false;
  }
}