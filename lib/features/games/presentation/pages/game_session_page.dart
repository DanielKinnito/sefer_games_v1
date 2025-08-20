import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/widgets/loading_overlay.dart';
import '../../../../core/presentation/mixins/error_handler_mixin.dart';
import '../../../lobby/domain/entities/lobby.dart';
import '../../../lobby/presentation/pages/lobby_home_page.dart';
import '../bloc/game_bloc.dart';
import '../widgets/game_ui_container.dart';
import '../widgets/game_header.dart';

class GameSessionPage extends StatefulWidget {
  final Lobby lobby;
  final VoidCallback? onToggleTheme;
  final bool? isDarkMode;

  const GameSessionPage({
    super.key,
    required this.lobby,
    this.onToggleTheme,
    this.isDarkMode,
  });

  @override
  State<GameSessionPage> createState() => _GameSessionPageState();
}

class _GameSessionPageState extends State<GameSessionPage> with ErrorHandlerMixin {
  late GameBloc _gameBloc;
  bool _showExitConfirmation = false;

  @override
  void initState() {
    super.initState();
    // TODO: Initialize GameBloc with proper dependencies
    // _gameBloc = GameDI.getBloc();
    // _gameBloc.add(StartGameSessionEvent(widget.lobby));
  }

  @override
  void dispose() {
    _gameBloc.close();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_showExitConfirmation) return true;
    
    final shouldExit = await showConfirmationDialog(
      title: 'Leave Game?',
      message: 'Are you sure you want to leave the current game session? Your progress will be lost.',
      confirmText: 'Leave Game',
      confirmColor: Colors.red,
    );

    if (shouldExit) {
      _gameBloc.add(ReturnToLobbyEvent('current_session'));
    }

    return shouldExit;
  }

  void _returnToLobby() async {
    final shouldReturn = await showConfirmationDialog(
      title: 'Return to Lobby?',
      message: 'Do you want to return to the lobby? The current game will end.',
      confirmText: 'Return to Lobby',
    );

    if (shouldReturn) {
      _gameBloc.add(ReturnToLobbyEvent('current_session'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: BlocConsumer<GameBloc, GameState>(
            bloc: _gameBloc,
            listener: (context, state) {
              // Handle errors using the mixin
              handleGameError(state);
              
              if (state is GameSessionEnded) {
                _showGameResults(state.gameResults);
              } else if (state is GameInitial) {
                // Game ended, return to lobby
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => LobbyHomePage(
                      onToggleTheme: widget.onToggleTheme,
                      isDarkMode: widget.isDarkMode,
                    ),
                  ),
                  (route) => false,
                );
              } else if (state is PlayerActionReceived) {
                showInfoMessage('${state.playerId} performed ${state.actionType}');
              } else if (state is GameRoundChanged) {
                showInfoMessage('Round ${state.currentRound} of ${state.totalRounds}');
              } else if (state is GamePlayerTurnChanged) {
                showInfoMessage('It\'s ${state.currentPlayerId}\'s turn');
              }
            },
            builder: (context, state) {
              final isLoading = state is GameLoading || state is GameSynchronizing;
              
              return LoadingOverlay(
                isLoading: isLoading,
                loadingText: _getLoadingText(state),
                child: Column(
                  children: [
                    // Game header with lobby info and controls
                    GameHeader(
                      lobbyName: widget.lobby.name,
                      gameType: widget.lobby.gameType,
                      onReturnToLobby: _returnToLobby,
                      onToggleTheme: widget.onToggleTheme,
                      isDarkMode: widget.isDarkMode,
                    ),
                    
                    // Main game content
                    Expanded(
                      child: _buildGameContent(state),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGameContent(GameState state) {
    if (state is GameSessionActive) {
      return GameUIContainer(
        session: state.session,
        gameState: state.currentGameState,
        currentPlayer: state.currentPlayer,
        onGameAction: (action) {
          _gameBloc.add(ProcessGameActionEvent('current_player', action));
        },
      );
    } else if (state is GameActionProcessed) {
      return GameUIContainer(
        session: state.session,
        gameState: state.updatedGameState,
        onGameAction: (action) {
          _gameBloc.add(ProcessGameActionEvent('current_player', action));
        },
      );
    } else if (state is GameStateUpdated) {
      return GameUIContainer(
        session: state.session,
        gameState: state.gameState,
        onGameAction: (action) {
          _gameBloc.add(ProcessGameActionEvent('current_player', action));
        },
      );
    } else if (state is GameNetworkDisconnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Connection Lost',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.reason ?? 'Network connection was lost',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Attempt to reconnect
                _gameBloc.add(RecoverFromSyncErrorEvent(state.session.sessionId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reconnect'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing game...'),
          ],
        ),
      );
    }
  }

  String _getLoadingText(GameState state) {
    if (state is GameLoading) {
      return 'Starting game session...';
    } else if (state is GameSynchronizing) {
      return 'Synchronizing game state...';
    }
    return 'Loading...';
  }

  void _showGameResults(Map<String, dynamic> results) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            SizedBox(width: 12),
            Text('Game Results'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (results['winner'] != null) ...[
              Text(
                'Winner: ${results['winner']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (results['rankings'] != null) ...[
              const Text('Final Rankings:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...((results['rankings'] as List).asMap().entries.map((entry) {
                final index = entry.key;
                final player = entry.value as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('${index + 1}. '),
                      Expanded(child: Text(player['playerId'] as String)),
                      Text('${player['score']} pts'),
                    ],
                  ),
                );
              })),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _returnToLobby();
            },
            child: const Text('Return to Lobby'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Start a new game with the same lobby
              _gameBloc.add(StartGameSessionEvent(widget.lobby));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  void _retryGameOperation() {
    // Retry starting the game session
    _gameBloc.add(StartGameSessionEvent(widget.lobby));
  }
}