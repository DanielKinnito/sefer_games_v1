/// Network-specific error types for the lobby system
abstract class NetworkError implements Exception {
  final String message;
  final String? details;
  final DateTime timestamp;

  NetworkError(this.message, {this.details}) : timestamp = DateTime.now();

  @override
  String toString() => 'NetworkError: $message${details != null ? ' ($details)' : ''}';
}

/// Error when lobby discovery fails
class DiscoveryError extends NetworkError {
  DiscoveryError(String message, {String? details}) : super(message, details: details);
}

/// Error when connection to host fails
class ConnectionError extends NetworkError {
  final String? hostAddress;
  final int? port;

  ConnectionError(String message, {this.hostAddress, this.port, String? details}) 
      : super(message, details: details);

  @override
  String toString() => 'ConnectionError: $message${hostAddress != null ? ' (host: $hostAddress:$port)' : ''}';
}

/// Error when hosting fails
class HostingError extends NetworkError {
  final int? attemptedPort;

  HostingError(String message, {this.attemptedPort, String? details}) 
      : super(message, details: details);

  @override
  String toString() => 'HostingError: $message${attemptedPort != null ? ' (port: $attemptedPort)' : ''}';
}

/// Error when message communication fails
class CommunicationError extends NetworkError {
  final String? messageType;

  CommunicationError(String message, {this.messageType, String? details}) 
      : super(message, details: details);

  @override
  String toString() => 'CommunicationError: $message${messageType != null ? ' (type: $messageType)' : ''}';
}

/// Error when network operation times out
class TimeoutError extends NetworkError {
  final Duration timeout;

  TimeoutError(String message, this.timeout, {String? details}) 
      : super(message, details: details);

  @override
  String toString() => 'TimeoutError: $message (timeout: ${timeout.inSeconds}s)';
}

/// Error when lobby is not available (full, not found, etc.)
class LobbyUnavailableError extends NetworkError {
  final String? lobbyId;
  final String reason;

  LobbyUnavailableError(this.reason, {this.lobbyId, String? details}) 
      : super('Lobby unavailable: $reason', details: details);

  @override
  String toString() => 'LobbyUnavailableError: $reason${lobbyId != null ? ' (lobby: $lobbyId)' : ''}';
}

/// Utility class for network error handling and recovery
class NetworkErrorHandler {
  static const int maxRetryAttempts = 3;
  static const Duration baseRetryDelay = Duration(seconds: 1);

  /// Execute a network operation with retry logic
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = maxRetryAttempts,
    Duration baseDelay = baseRetryDelay,
    bool Function(dynamic error)? shouldRetry,
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

        // Don't retry on the last attempt
        if (attempts >= maxAttempts) {
          rethrow;
        }

        // Calculate delay with exponential backoff
        final delay = Duration(
          milliseconds: (baseDelay.inMilliseconds * (1 << (attempts - 1))).clamp(
            baseDelay.inMilliseconds,
            30000, // Max 30 seconds
          ),
        );

        print('Network operation failed (attempt $attempts/$maxAttempts), retrying in ${delay.inSeconds}s: $error');
        await Future.delayed(delay);
      }
    }

    throw lastError;
  }

  /// Execute a network operation with timeout
  static Future<T> withTimeout<T>(
    Future<T> Function() operation,
    Duration timeout, {
    String? operationName,
  }) async {
    try {
      return await operation().timeout(timeout);
    } on TimeoutException {
      throw TimeoutError(
        operationName != null 
            ? 'Operation "$operationName" timed out'
            : 'Network operation timed out',
        timeout,
      );
    }
  }

  /// Check if an error is retryable
  static bool isRetryableError(dynamic error) {
    if (error is NetworkError) {
      // Don't retry lobby unavailable errors
      if (error is LobbyUnavailableError) return false;
      
      // Don't retry hosting errors with specific port conflicts
      if (error is HostingError && error.message.contains('port')) return false;
      
      // Retry other network errors
      return true;
    }

    // Retry socket exceptions and IO exceptions
    if (error is SocketException || error is IOException) {
      return true;
    }

    // Don't retry other types of errors
    return false;
  }

  /// Convert generic exceptions to specific network errors
  static NetworkError convertToNetworkError(dynamic error, {String? context}) {
    if (error is NetworkError) {
      return error;
    }

    if (error is SocketException) {
      if (context?.contains('discovery') == true) {
        return DiscoveryError('Network discovery failed', details: error.message);
      } else if (context?.contains('connection') == true) {
        return ConnectionError('Failed to connect to host', details: error.message);
      } else if (context?.contains('hosting') == true) {
        return HostingError('Failed to start hosting', details: error.message);
      } else {
        return CommunicationError('Network communication failed', details: error.message);
      }
    }

    if (error is TimeoutException) {
      return TimeoutError('Network operation timed out', const Duration(seconds: 30), details: error.message);
    }

    if (error is FormatException) {
      return CommunicationError('Invalid message format', details: error.message);
    }

    // Generic network error for unknown exceptions
    return CommunicationError('Unknown network error', details: error.toString());
  }

  /// Get user-friendly error message
  static String getUserFriendlyMessage(NetworkError error) {
    switch (error.runtimeType) {
      case DiscoveryError:
        return 'Unable to find lobbies on the network. Make sure you\'re connected to the same WiFi network.';
      
      case ConnectionError:
        final connError = error as ConnectionError;
        if (connError.hostAddress != null) {
          return 'Cannot connect to ${connError.hostAddress}. The host may have left or the lobby may be full.';
        }
        return 'Connection failed. Please check your network connection.';
      
      case HostingError:
        return 'Failed to start hosting. Try using a different port or check your network settings.';
      
      case CommunicationError:
        return 'Communication error. Please check your network connection and try again.';
      
      case TimeoutError:
        return 'Operation timed out. Please check your network connection and try again.';
      
      case LobbyUnavailableError:
        final lobbyError = error as LobbyUnavailableError;
        return 'Lobby is ${lobbyError.reason}. Please try joining a different lobby.';
      
      default:
        return 'Network error occurred. Please try again.';
    }
  }

  /// Get suggested actions for error recovery
  static List<String> getSuggestedActions(NetworkError error) {
    switch (error.runtimeType) {
      case DiscoveryError:
        return [
          'Check WiFi connection',
          'Make sure all devices are on the same network',
          'Try refreshing the lobby list',
        ];
      
      case ConnectionError:
        return [
          'Check network connection',
          'Ask the host to restart the lobby',
          'Try joining a different lobby',
        ];
      
      case HostingError:
        return [
          'Check network permissions',
          'Try a different port',
          'Restart the app and try again',
        ];
      
      case CommunicationError:
        return [
          'Check network connection',
          'Move closer to the WiFi router',
          'Restart the app',
        ];
      
      case TimeoutError:
        return [
          'Check network connection',
          'Move closer to the WiFi router',
          'Try again in a moment',
        ];
      
      case LobbyUnavailableError:
        return [
          'Try joining a different lobby',
          'Ask the host to increase player limit',
          'Wait for a player to leave',
        ];
      
      default:
        return [
          'Check network connection',
          'Restart the app',
          'Try again',
        ];
    }
  }
}