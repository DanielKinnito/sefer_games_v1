import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/lobby_info_data.dart';

class LobbyInfoCard extends StatelessWidget {
  final LobbyInfoData lobbyInfo;

  const LobbyInfoCard({
    super.key,
    required this.lobbyInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Lobby Information',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              'Lobby Name',
              lobbyInfo.lobbyName,
              icon: Icons.label_outline,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Host',
              lobbyInfo.hostName,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Game Type',
              _formatGameType(lobbyInfo.gameType),
              icon: Icons.games_outlined,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Players',
              '${lobbyInfo.currentPlayerCount}/${lobbyInfo.maxPlayers}',
              icon: Icons.group_outlined,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Status',
              lobbyInfo.isGameStarted ? 'Game In Progress' : 'Waiting for Players',
              icon: lobbyInfo.isGameStarted ? Icons.play_circle_outline : Icons.hourglass_empty,
              valueColor: lobbyInfo.isGameStarted ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildCopyableInfoRow(
                    context,
                    'Lobby ID',
                    lobbyInfo.lobbyId,
                    icon: Icons.tag,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildCopyableInfoRow(
                    context,
                    'Connection',
                    '${lobbyInfo.hostIp}:${lobbyInfo.port}',
                    icon: Icons.wifi,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: valueColor ?? Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableInfoRow(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => _copyToClipboard(context, value),
                icon: const Icon(Icons.copy, size: 16),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(4),
                tooltip: 'Copy to clipboard',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatGameType(String gameType) {
    switch (gameType) {
      case 'number_guessing':
        return 'Number Guessing';
      case 'word_game':
        return 'Word Game';
      case 'trivia':
        return 'Trivia';
      default:
        return gameType.replaceAll('_', ' ').split(' ')
            .map((word) => word.isNotEmpty 
                ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                : word)
            .join(' ');
    }
  }
}
