import 'package:flutter/material.dart';
import '../../models/word_blitz_models.dart';
import '../../actions/word_blitz_actions.dart';

class WordBlitzHostPanel extends StatefulWidget {
  final WordBlitzState gameState;
  final String hostId;
  final Function(WordBlitzAction) onAction;
  final VoidCallback? onEndGame;

  const WordBlitzHostPanel({
    super.key,
    required this.gameState,
    required this.hostId,
    required this.onAction,
    this.onEndGame,
  });

  @override
  State<WordBlitzHostPanel> createState() => _WordBlitzHostPanelState();
}

class _WordBlitzHostPanelState extends State<WordBlitzHostPanel> {
  String? _selectedTheme;
  String? _customTheme;
  final TextEditingController _customThemeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.gameState.currentTheme.isNotEmpty 
        ? widget.gameState.currentTheme 
        : null;
  }

  @override
  void dispose() {
    _customThemeController.dispose();
    super.dispose();
  }

  void _setTheme(String theme) {
    final action = SetThemeAction(
      playerId: widget.hostId,
      theme: theme,
    );
    widget.onAction(action);
    setState(() => _selectedTheme = theme);
  }

  void _generateLetter() {
    final action = GenerateLetterAction(playerId: widget.hostId);
    widget.onAction(action);
  }

  void _startRound() {
    final action = StartRoundAction(playerId: widget.hostId);
    widget.onAction(action);
  }

  void _endRound() {
    final action = EndRoundAction(playerId: widget.hostId);
    widget.onAction(action);
  }

  void _eliminatePlayer(String playerId) {
    final action = EliminatePlayerAction(
      playerId: widget.hostId,
      targetPlayerId: playerId,
    );
    widget.onAction(action);
  }

  void _addCustomTheme() {
    if (_customTheme != null && _customTheme!.isNotEmpty) {
      final action = AddCustomThemeAction(
        playerId: widget.hostId,
        theme: _customTheme!,
      );
      widget.onAction(action);
      _customThemeController.clear();
      setState(() => _customTheme = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 16),
            _buildGameStatus(),
            SizedBox(height: 16),
            _buildThemeSelection(),
            if (widget.gameState.allowCustomThemes) ...[
              SizedBox(height: 16),
              _buildCustomThemeInput(),
            ],
            SizedBox(height: 16),
            _buildRoundControls(),
            if (widget.gameState.isRoundActive) ...[
              SizedBox(height: 16),
              _buildPlayerElimination(),
            ],
            SizedBox(height: 16),
            _buildGameControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.admin_panel_settings,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(width: 8),
        Text(
          'Host Controls',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Spacer(),
        if (widget.gameState.isGameFinished)
          Chip(
            label: Text('Game Finished'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          )
        else if (widget.gameState.isRoundActive)
          Chip(
            label: Text('Round Active'),
            backgroundColor: Colors.green.withValues(alpha: 0.2),
          ),
      ],
    );
  }

  Widget _buildGameStatus() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game Status',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildStatusItem('Round', '${widget.gameState.currentRound}'),
              SizedBox(width: 16),
              _buildStatusItem('Active Players', '${widget.gameState.activePlayers.length}'),
              SizedBox(width: 16),
              _buildStatusItem('Rounds to Win', '${widget.gameState.roundsToWin}'),
            ],
          ),
          if (widget.gameState.currentTheme.isNotEmpty) ...[
            SizedBox(height: 8),
            _buildStatusItem('Current Theme', widget.gameState.currentTheme),
          ],
          if (widget.gameState.currentLetter != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Current Letter: ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.gameState.currentLetter!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Theme',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.gameState.availableThemes.map((theme) {
            final isSelected = _selectedTheme == theme;
            return FilterChip(
              label: Text(theme),
              selected: isSelected,
              onSelected: widget.gameState.isRoundActive ? null : (selected) {
                if (selected) _setTheme(theme);
              },
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomThemeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Custom Theme',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customThemeController,
                decoration: InputDecoration(
                  hintText: 'Enter custom theme...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onChanged: (value) => setState(() => _customTheme = value),
                onSubmitted: (_) => _addCustomTheme(),
                enabled: !widget.gameState.isRoundActive,
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: widget.gameState.isRoundActive || 
                         _customTheme == null || 
                         _customTheme!.isEmpty 
                  ? null 
                  : _addCustomTheme,
              child: Text('Add'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoundControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Round Controls',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: widget.gameState.isRoundActive ||
                         widget.gameState.currentTheme.isEmpty ||
                         widget.gameState.isGameFinished
                  ? null
                  : _startRound,
              icon: Icon(Icons.play_arrow),
              label: Text('Start Round'),
            ),
            SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: !widget.gameState.isRoundActive ||
                         widget.gameState.currentTheme.isEmpty ||
                         widget.gameState.isGameFinished
                  ? null
                  : _generateLetter,
              icon: Icon(Icons.shuffle),
              label: Text('Generate Letter'),
            ),
            SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: !widget.gameState.isRoundActive ||
                         widget.gameState.isGameFinished
                  ? null
                  : _endRound,
              icon: Icon(Icons.stop),
              label: Text('End Round'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerElimination() {
    final activePlayers = widget.gameState.activePlayers;
    
    if (activePlayers.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Eliminate Player',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Select the player who said the word last:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: activePlayers.map((player) {
            return ElevatedButton(
              onPressed: () => _eliminatePlayer(player.playerId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
              child: Text(player.playerName),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGameControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Game Controls',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            if (widget.onEndGame != null)
              ElevatedButton.icon(
                onPressed: widget.onEndGame,
                icon: Icon(Icons.exit_to_app),
                label: Text('End Game'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
              ),
          ],
        ),
      ],
    );
  }
}