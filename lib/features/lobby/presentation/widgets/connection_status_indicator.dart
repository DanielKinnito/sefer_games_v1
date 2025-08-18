import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/lobby_bloc.dart';

class ConnectionStatusIndicator extends StatelessWidget {
  const ConnectionStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LobbyBloc, LobbyState>(
      builder: (context, state) {
        bool isConnected = true;
        String? hostAddress;
        String? errorMessage;
        bool isReconnecting = false;
        int reconnectAttempts = 0;

        if (state is NetworkConnected) {
          isConnected = true;
          hostAddress = state.hostAddress;
        } else if (state is NetworkDisconnected) {
          isConnected = false;
          errorMessage = state.reason;
        } else if (state is NetworkReconnecting) {
          isConnected = false;
          isReconnecting = true;
          reconnectAttempts = state.attemptNumber;
        } else if (state is LobbyWithNetworkStatus) {
          isConnected = state.networkStatus.isConnected;
          hostAddress = state.networkStatus.hostAddress;
          errorMessage = state.networkStatus.errorMessage;
          reconnectAttempts = state.networkStatus.reconnectAttempts;
        }

        return Card(
          color: Theme.of(context).cardColor,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(isConnected, isReconnecting),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Network Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const Spacer(),
                    if (isReconnecting)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getStatusText(isConnected, isReconnecting, reconnectAttempts),
                  style: TextStyle(
                    fontSize: 14,
                    color: _getStatusColor(isConnected, isReconnecting),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (hostAddress != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Host: $hostAddress',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
                if (errorMessage != null && !isReconnecting) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Error: $errorMessage',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ],
                if (!isConnected && !isReconnecting) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Trigger retry
                        context.read<LobbyBloc>().add(RetryLastOperationEvent());
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry Connection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(bool isConnected, bool isReconnecting) {
    if (isReconnecting) return Colors.orange;
    return isConnected ? Colors.green : Colors.red;
  }

  String _getStatusText(bool isConnected, bool isReconnecting, int reconnectAttempts) {
    if (isReconnecting) {
      return 'Reconnecting... (Attempt $reconnectAttempts)';
    }
    return isConnected ? 'Connected' : 'Disconnected';
  }
}