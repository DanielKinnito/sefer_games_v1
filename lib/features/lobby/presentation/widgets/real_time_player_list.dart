import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/lobby_bloc.dart';
import '../../domain/entities/player.dart';

class RealTimePlayerList extends StatelessWidget {
  final LobbyBloc? lobbyBloc;
  
  const RealTimePlayerList({super.key, this.lobbyBloc});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LobbyBloc, LobbyState>(
      bloc: lobbyBloc,
      builder: (context, state) {
        List<Player> players = [];
        String lobbyName = '';
        
        if (state is LobbyHosting) {
          players = state.lobby.players;
          lobbyName = state.lobby.name;
        } else if (state is LobbyJoined) {
          players = state.lobby.players;
          lobbyName = state.lobby.name;
        } else if (state is LobbyWithNetworkStatus) {
          players = state.lobby.players;
          lobbyName = state.lobby.name;
        } else if (state is PlayerJoined) {
          players = state.lobby.players;
          lobbyName = state.lobby.name;
        } else if (state is PlayerLeft) {
          players = state.lobby.players;
          lobbyName = state.lobby.name;
        }

        if (players.isEmpty) {
          return const SizedBox.shrink();
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
                    Icon(
                      Icons.people,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Players in $lobbyName',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${players.length}',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...players.map((player) => _buildPlayerTile(context, player)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayerTile(BuildContext context, Player player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]?.withValues(alpha: 0.3)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: player.isHost
            ? Border.all(color: Theme.of(context).primaryColor, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            child: Text(
              player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      player.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    if (player.isHost) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      player.isConnected ? Icons.circle : Icons.circle_outlined,
                      color: player.isConnected ? Colors.green : Colors.grey,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      player.isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        fontSize: 12,
                        color: player.isConnected ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Connection status indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: player.isConnected ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}