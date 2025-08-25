import 'package:flutter/material.dart';
import '../../../../core/game/game_base.dart';

class GameCard extends StatelessWidget {
  final GameMetadata gameMetadata;
  final bool isRecent;
  final int playerCount;
  final VoidCallback onTap;

  const GameCard({
    super.key,
    required this.gameMetadata,
    this.isRecent = false,
    required this.playerCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: 12),
              _buildDescription(context),
              SizedBox(height: 12),
              _buildGameInfo(context),
              SizedBox(height: 12),
              _buildTags(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // Game icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: gameMetadata.iconPath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    gameMetadata.iconPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(context),
                  ),
                )
              : _buildDefaultIcon(context),
        ),
        SizedBox(width: 12),
        
        // Game title and badges
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      gameMetadata.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isRecent) _buildRecentBadge(context),
                ],
              ),
              SizedBox(height: 4),
              _buildPlayerCountInfo(context),
            ],
          ),
        ),
        
        // Action icon
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: colorScheme.outline,
        ),
      ],
    );
  }

  Widget _buildDefaultIcon(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Icon(
      _getGameIcon(),
      size: 24,
      color: colorScheme.onPrimaryContainer,
    );
  }

  IconData _getGameIcon() {
    // Return appropriate icon based on game type or tags
    if (gameMetadata.tags.contains('word') || gameMetadata.gameType.contains('word')) {
      return Icons.text_fields;
    } else if (gameMetadata.tags.contains('number') || gameMetadata.gameType.contains('number')) {
      return Icons.numbers;
    } else if (gameMetadata.tags.contains('strategy')) {
      return Icons.psychology;
    } else if (gameMetadata.tags.contains('party')) {
      return Icons.celebration;
    } else {
      return Icons.games;
    }
  }

  Widget _buildRecentBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Recent',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPlayerCountInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final isValidPlayerCount = playerCount >= gameMetadata.minPlayers && 
                              playerCount <= gameMetadata.maxPlayers;
    
    return Row(
      children: [
        Icon(
          Icons.people,
          size: 14,
          color: isValidPlayerCount ? colorScheme.primary : colorScheme.error,
        ),
        SizedBox(width: 4),
        Text(
          '${gameMetadata.minPlayers}-${gameMetadata.maxPlayers} players',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isValidPlayerCount ? colorScheme.primary : colorScheme.error,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      gameMetadata.description,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildGameInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      children: [
        // Duration
        Icon(
          Icons.schedule,
          size: 16,
          color: colorScheme.outline,
        ),
        SizedBox(width: 4),
        Text(
          _formatDuration(gameMetadata.estimatedDuration),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.outline,
          ),
        ),
        
        SizedBox(width: 16),
        
        // Difficulty or complexity indicator
        if (gameMetadata.tags.contains('easy'))
          _buildDifficultyChip(context, 'Easy', Colors.green)
        else if (gameMetadata.tags.contains('medium'))
          _buildDifficultyChip(context, 'Medium', Colors.orange)
        else if (gameMetadata.tags.contains('hard'))
          _buildDifficultyChip(context, 'Hard', Colors.red),
      ],
    );
  }

  Widget _buildDifficultyChip(BuildContext context, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTags(BuildContext context) {
    if (gameMetadata.tags.isEmpty) return SizedBox.shrink();
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: gameMetadata.tags.take(4).map((tag) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tag,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 60) {
      return '${minutes}min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${remainingMinutes}min';
      }
    }
  }
}