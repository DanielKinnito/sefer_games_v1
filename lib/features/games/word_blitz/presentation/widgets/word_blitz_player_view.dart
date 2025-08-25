import 'package:flutter/material.dart';
import '../../models/word_blitz_models.dart';

class WordBlitzPlayerView extends StatefulWidget {
  final WordBlitzState gameState;
  final String playerId;

  const WordBlitzPlayerView({
    Key? key,
    required this.gameState,
    required this.playerId,
  }) : super(key: key);

  @override
  State<WordBlitzPlayerView> createState() => _WordBlitzPlayerViewState();
}

class _WordBlitzPlayerViewState extends State<WordBlitzPlayerView>
    with TickerProviderStateMixin {
  late AnimationController _letterAnimationController;
  late Animation<double> _letterScaleAnimation;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _letterAnimationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    
    _letterScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _letterAnimationController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    if (widget.gameState.isRoundActive) {
      _pulseAnimationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(WordBlitzPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate letter appearance
    if (oldWidget.gameState.currentLetter != widget.gameState.currentLetter &&
        widget.gameState.currentLetter != null) {
      _letterAnimationController.forward();
    }

    // Control pulse animation based on round state
    if (oldWidget.gameState.isRoundActive != widget.gameState.isRoundActive) {
      if (widget.gameState.isRoundActive) {
        _pulseAnimationController.repeat(reverse: true);
      } else {
        _pulseAnimationController.stop();
        _pulseAnimationController.reset();
      }
    }
  }

  @override
  void dispose() {
    _letterAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  PlayerStatus? get _currentPlayer {
    return widget.gameState.getPlayer(widget.playerId);
  }

  bool get _isPlayerActive {
    return _currentPlayer?.isActive ?? false;
  }

  bool get _isPlayerEliminated {
    return _currentPlayer?.isEliminated ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: 16),
              _buildGameStatus(),
              SizedBox(height: 24),
              Expanded(
                child: _buildMainContent(),
              ),
              _buildPlayerStatus(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.games,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
        SizedBox(width: 12),
        Text(
          'Word Blitz',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Spacer(),
        if (widget.gameState.isGameFinished)
          _buildGameFinishedChip()
        else if (widget.gameState.isRoundActive)
          _buildRoundActiveChip()
        else
          _buildWaitingChip(),
      ],
    );
  }

  Widget _buildGameFinishedChip() {
    return Chip(
      label: Text('Game Finished'),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      avatar: Icon(
        Icons.flag,
        size: 16,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildRoundActiveChip() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Chip(
            label: Text('Round Active'),
            backgroundColor: Colors.green.withOpacity(0.2),
            avatar: Icon(
              Icons.play_circle,
              size: 16,
              color: Colors.green,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaitingChip() {
    return Chip(
      label: Text('Waiting'),
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      avatar: Icon(
        Icons.hourglass_empty,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildGameStatus() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusItem(
                'Round',
                '${widget.gameState.currentRound}',
                Icons.refresh,
              ),
              _buildStatusItem(
                'Players',
                '${widget.gameState.activePlayers.length}',
                Icons.people,
              ),
              _buildStatusItem(
                'To Win',
                '${widget.gameState.roundsToWin}',
                Icons.emoji_events,
              ),
            ],
          ),
          if (widget.gameState.currentTheme.isNotEmpty) ...[
            SizedBox(height: 12),
            _buildThemeDisplay(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeDisplay() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.category,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          SizedBox(width: 6),
          Text(
            'Theme: ${widget.gameState.currentTheme}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (widget.gameState.isGameFinished) {
      return _buildGameFinishedContent();
    } else if (widget.gameState.currentLetter != null) {
      return _buildLetterDisplay();
    } else if (widget.gameState.isRoundActive) {
      return _buildWaitingForLetter();
    } else {
      return _buildWaitingForRound();
    }
  }

  Widget _buildLetterDisplay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Your letter is:',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 24),
          AnimatedBuilder(
            animation: _letterScaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _letterScaleAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.gameState.currentLetter!,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 24),
          Text(
            'Think of a ${widget.gameState.currentTheme.toLowerCase()} that starts with this letter!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          if (_isPlayerEliminated)
            _buildEliminatedMessage()
          else if (_isPlayerActive)
            _buildActivePlayerMessage(),
        ],
      ),
    );
  }

  Widget _buildActivePlayerMessage() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            'You\'re still in the round!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEliminatedMessage() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cancel,
            color: Colors.red,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            'You\'ve been eliminated this round',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForLetter() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text(
            'Waiting for letter...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'The host will generate a letter soon',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForRound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          SizedBox(height: 24),
          Text(
            'Waiting for round to start...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 12),
          Text(
            widget.gameState.currentTheme.isEmpty
                ? 'The host is selecting a theme'
                : 'The host will start the round soon',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGameFinishedContent() {
    final winner = widget.gameState.winner;
    final isWinner = winner == widget.playerId;
    final winnerPlayer = widget.gameState.getPlayer(winner ?? '');
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isWinner ? Icons.emoji_events : Icons.flag,
            size: 80,
            color: isWinner 
                ? Colors.amber 
                : Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: 24),
          Text(
            isWinner ? 'Congratulations!' : 'Game Over',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isWinner 
                  ? Colors.amber.shade700 
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 12),
          Text(
            isWinner 
                ? 'You won the game!'
                : '${winnerPlayer?.playerName ?? 'Someone'} won the game!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          _buildFinalScores(),
        ],
      ),
    );
  }

  Widget _buildFinalScores() {
    final leaderboard = widget.gameState.leaderboard;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Final Scores',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          ...leaderboard.take(3).map((player) => _buildScoreItem(player)),
        ],
      ),
    );
  }

  Widget _buildScoreItem(PlayerStatus player) {
    final isCurrentPlayer = player.playerId == widget.playerId;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCurrentPlayer 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${player.roundsWon}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isCurrentPlayer
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.surface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              player.playerName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatus() {
    final currentPlayer = _currentPlayer;
    if (currentPlayer == null) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              currentPlayer.playerName.isNotEmpty 
                  ? currentPlayer.playerName[0].toUpperCase()
                  : 'P',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentPlayer.playerName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Rounds won: ${currentPlayer.roundsWon}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (currentPlayer.isEliminated)
            Chip(
              label: Text('Eliminated'),
              backgroundColor: Colors.red.withOpacity(0.2),
              labelStyle: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
            )
          else if (currentPlayer.isActive && widget.gameState.isRoundActive)
            Chip(
              label: Text('Active'),
              backgroundColor: Colors.green.withOpacity(0.2),
              labelStyle: TextStyle(
                color: Colors.green.shade700,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}