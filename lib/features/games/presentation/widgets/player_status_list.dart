import 'package:flutter/material.dart';
import 'game_ui_widget.dart';
import '../../../../core/game/game_base.dart';

/// Widget for displaying real-time player status in games
class PlayerStatusList extends StatefulWidget {
  final List<PlayerInfo> players;
  final String? currentPlayerId;
  final bool showScores;
  final bool showStatus;
  final Function(String playerId)? onPlayerTap;
  final Widget Function(PlayerInfo player)? customPlayerWidget;

  const PlayerStatusList({
    Key? key,
    required this.players,
    this.currentPlayerId,
    this.showScores = true,
    this.showStatus = true,
    this.onPlayerTap,
    this.customPlayerWidget,
  }) : super(key: key);

  @override
  State<PlayerStatusList> createState() => _PlayerStatusListState();
}

class _PlayerStatusListState extends State<PlayerStatusList>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.players.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 8),
          _buildPlayerList(),
        ],
      ),
    );
  }  Widget 
_buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.people,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        SizedBox(width: 8),
        Text(
          'Players (${widget.players.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: widget.players.length,
      separatorBuilder: (context, index) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        final player = widget.players[index];
        return _buildPlayerItem(player);
      },
    );
  }

  Widget _buildPlayerItem(PlayerInfo player) {
    if (widget.customPlayerWidget != null) {
      return widget.customPlayerWidget!(player);
    }

    final isCurrentPlayer = player.id == widget.currentPlayerId;
    
    return Card(
      elevation: isCurrentPlayer ? 4 : 1,
      color: isCurrentPlayer 
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        onTap: widget.onPlayerTap != null 
            ? () => widget.onPlayerTap!(player.id)
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              _buildPlayerAvatar(player, isCurrentPlayer),
              SizedBox(width: 12),
              Expanded(
                child: _buildPlayerInfo(player, isCurrentPlayer),
              ),
              if (widget.showStatus) _buildPlayerStatus(player),
              if (widget.showScores) _buildPlayerScore(player),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerAvatar(PlayerInfo player, bool isCurrentPlayer) {
    return CircleAvatar(
      backgroundColor: isCurrentPlayer
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.outline,
      child: Text(
        player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: isCurrentPlayer
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.surface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPlayerInfo(PlayerInfo player, bool isCurrentPlayer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          player.name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
            color: isCurrentPlayer
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : null,
          ),
        ),
        if (isCurrentPlayer)
          Text(
            'You',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildPlayerStatus(PlayerInfo player) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (player.status) {
      case PlayerStatus.active:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Active';
        break;
      case PlayerStatus.eliminated:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Out';
        break;
      case PlayerStatus.waiting:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Waiting';
        break;
      case PlayerStatus.disconnected:
        statusColor = Colors.grey;
        statusIcon = Icons.wifi_off;
        statusText = 'Offline';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 14,
            color: statusColor,
          ),
          SizedBox(width: 4),
          Text(
            statusText,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerScore(PlayerInfo player) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${player.score}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          SizedBox(height: 8),
          Text(
            'No players yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// Player information for display in the status list
class PlayerInfo {
  final String id;
  final String name;
  final PlayerStatus status;
  final int score;
  final Map<String, dynamic>? metadata;

  const PlayerInfo({
    required this.id,
    required this.name,
    required this.status,
    this.score = 0,
    this.metadata,
  });

  PlayerInfo copyWith({
    String? id,
    String? name,
    PlayerStatus? status,
    int? score,
    Map<String, dynamic>? metadata,
  }) {
    return PlayerInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      score: score ?? this.score,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Player status enumeration
enum PlayerStatus {
  active,
  eliminated,
  waiting,
  disconnected,
}