import 'package:flutter/material.dart';
import 'game_ui_widget.dart';
import '../../../../core/game/game_base.dart';

/// Common game control panel with standard game controls
class GameControlPanel extends StatefulWidget {
  final GameBase game;
  final bool isHost;
  final String currentPlayerId;
  final VoidCallback? onPauseGame;
  final VoidCallback? onResumeGame;
  final VoidCallback? onEndGame;
  final VoidCallback? onShowSettings;
  final VoidCallback? onShowHelp;
  final Map<String, VoidCallback>? customActions;
  final bool showPauseButton;
  final bool showSettingsButton;
  final bool showHelpButton;
  final bool showEndGameButton;

  const GameControlPanel({
    Key? key,
    required this.game,
    required this.isHost,
    required this.currentPlayerId,
    this.onPauseGame,
    this.onResumeGame,
    this.onEndGame,
    this.onShowSettings,
    this.onShowHelp,
    this.customActions,
    this.showPauseButton = true,
    this.showSettingsButton = true,
    this.showHelpButton = true,
    this.showEndGameButton = true,
  }) : super(key: key);

  @override
  State<GameControlPanel> createState() => _GameControlPanelState();
}

class _GameControlPanelState extends State<GameControlPanel> {
  bool _isPaused = false;
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: _showControls ? null : 60,
      child: Card(
        margin: EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (_showControls) ...[
              Divider(height: 1),
              _buildControlButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.gamepad,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            'Game Controls',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Spacer(),
          IconButton(
            icon: Icon(
              _showControls ? Icons.expand_less : Icons.expand_more,
              size: 20,
            ),
            onPressed: () => setState(() => _showControls = !_showControls),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Pause/Resume button
          if (widget.showPauseButton && widget.isHost)
            _buildControlButton(
              icon: _isPaused ? Icons.play_arrow : Icons.pause,
              label: _isPaused ? 'Resume' : 'Pause',
              onPressed: _isPaused ? widget.onResumeGame : widget.onPauseGame,
              color: _isPaused ? Colors.green : Colors.orange,
            ),

          // Settings button
          if (widget.showSettingsButton)
            _buildControlButton(
              icon: Icons.settings,
              label: 'Settings',
              onPressed: widget.onShowSettings,
            ),

          // Help button
          if (widget.showHelpButton)
            _buildControlButton(
              icon: Icons.help_outline,
              label: 'Help',
              onPressed: widget.onShowHelp,
            ),

          // Custom action buttons
          if (widget.customActions != null)
            ...widget.customActions!.entries.map((entry) =>
                _buildControlButton(
                  icon: Icons.extension,
                  label: entry.key,
                  onPressed: entry.value,
                ),
            ),

          // End game button (host only)
          if (widget.showEndGameButton && widget.isHost)
            _buildControlButton(
              icon: Icons.exit_to_app,
              label: 'End Game',
              onPressed: () => _showEndGameConfirmation(),
              color: Theme.of(context).colorScheme.error,
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    Color? color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color?.withOpacity(0.1),
        foregroundColor: color ?? Theme.of(context).colorScheme.primary,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size(0, 36),
      ),
    );
  }

  Future<void> _showEndGameConfirmation() async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('End Game'),
        content: Text(
          'Are you sure you want to end the game? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text('End Game'),
          ),
        ],
      ),
    );

    if (shouldEnd == true && widget.onEndGame != null) {
      widget.onEndGame!();
    }
  }
}