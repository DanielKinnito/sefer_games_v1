import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/game/game_base.dart';
import '../../../../../core/error/error_handler.dart';
import '../../models/word_blitz_models.dart';
import '../../actions/word_blitz_actions.dart';
import '../../word_blitz_game.dart';
import '../../../../lobby/data/services/lan_service.dart';
import '../../../../lobby/data/models/network_models.dart';

// Word Blitz specific events
abstract class WordBlitzGameEvent {}

class InitializeWordBlitzEvent extends WordBlitzGameEvent {
  final List<String> playerIds;
  final List<String> playerNames;
  final WordBlitzConfig config;

  InitializeWordBlitzEvent({
    required this.playerIds,
    required this.playerNames,
    required this.config,
  });
}

class ProcessWordBlitzActionEvent extends WordBlitzGameEvent {
  final WordBlitzAction action;

  ProcessWordBlitzActionEvent(this.action);
}

class WordBlitzNetworkEventReceived extends WordBlitzGameEvent {
  final NetworkMessage message;

  WordBlitzNetworkEventReceived(this.message);
}

class SyncWordBlitzStateEvent extends WordBlitzGameEvent {}

// Word Blitz specific states
abstract class WordBlitzGameState {}

class WordBlitzInitial extends WordBlitzGameState {}

class WordBlitzLoading extends WordBlitzGameState {}

class WordBlitzGameActive extends WordBlitzGameState {
  final WordBlitzState gameState;
  final String currentPlayerId;

  WordBlitzGameActive({
    required this.gameState,
    required this.currentPlayerId,
  });
}

class WordBlitzActionProcessed extends WordBlitzGameState {
  final WordBlitzState gameState;
  final String actionType;
  final Map<String, dynamic> result;

  WordBlitzActionProcessed({
    required this.gameState,
    required this.actionType,
    required this.result,
  });
}

class WordBlitzGameFinished extends WordBlitzGameState {
  final WordBlitzState gameState;
  final String winner;

  WordBlitzGameFinished({
    required this.gameState,
    required this.winner,
  });
}

class WordBlitzError extends WordBlitzGameState {
  final String message;
  final WordBlitzErrorType errorType;
  final bool canRetry;

  WordBlitzError({
    required this.message,
    required this.errorType,
    this.canRetry = false,
  });
}

enum WordBlitzErrorType {
  initialization,
  action,
  network,
  synchronization,
}

/// BLoC for managing Word Blitz game state and events
class WordBlitzGameBloc extends Bloc<WordBlitzGameEvent, WordBlitzGameState> {
  final LanService lanService;
  final String currentPlayerId;
  final bool isHost;

  WordBlitzGame? _game;
  WordBlitzState? _gameState;
  StreamSubscription? _gameEventSubscription;
  StreamSubscription? _networkSubscription;

  WordBlitzGameBloc({
    required this.lanService,
    required this.currentPlayerId,
    required this.isHost,
  }) : super(WordBlitzInitial()) {
    _setupNetworkListener();
    _registerEventHandlers();
  }

  void _setupNetworkListener() {
    _networkSubscription = lanService.messageStream
        .where((message) => _isWordBlitzMessage(message))
        .listen((message) {
      add(WordBlitzNetworkEventReceived(message));
    });
  }

  void _registerEventHandlers() {
    on<InitializeWordBlitzEvent>(_onInitializeGame);
    on<ProcessWordBlitzActionEvent>(_onProcessAction);
    on<WordBlitzNetworkEventReceived>(_onNetworkEvent);
    on<SyncWordBlitzStateEvent>(_onSyncState);
  }

  Future<void> _onInitializeGame(
    InitializeWordBlitzEvent event,
    Emitter<WordBlitzGameState> emit,
  ) async {
    emit(WordBlitzLoading());

    try {
      _game = WordBlitzGame(
        availableThemes: event.config.availableThemes,
        roundsToWin: event.config.roundsToWin,
        roundTimeout: event.config.roundTimeout,
        allowCustomThemes: event.config.allowCustomThemes,
      );

      await _game!.initializeGame(event.playerIds);
      await _game!.startGame();

      _gameState = WordBlitzState.initial(
        gameId: _game!.gameId,
        playerIds: event.playerIds,
        playerNames: event.playerNames,
        roundsToWin: event.config.roundsToWin,
        roundTimeout: event.config.roundTimeout,
        availableThemes: event.config.availableThemes,
        allowCustomThemes: event.config.allowCustomThemes,
      );

      _subscribeToGameEvents();

      emit(WordBlitzGameActive(
        gameState: _gameState!,
        currentPlayerId: currentPlayerId,
      ));

      // Broadcast initial state to all players
      if (isHost) {
        await _broadcastGameState();
      }
    } catch (e) {
      emit(WordBlitzError(
        message: 'Failed to initialize game: $e',
        errorType: WordBlitzErrorType.initialization,
        canRetry: true,
      ));
    }
  }

  Future<void> _onProcessAction(
    ProcessWordBlitzActionEvent event,
    Emitter<WordBlitzGameState> emit,
  ) async {
    if (_game == null || _gameState == null) {
      emit(WordBlitzError(
        message: 'Game not initialized',
        errorType: WordBlitzErrorType.action,
      ));
      return;
    }

    try {
      // Validate host permissions
      if (WordBlitzActionFactory.requiresHostPermission(event.action.type) && !isHost) {
        emit(WordBlitzError(
          message: 'Action requires host permissions',
          errorType: WordBlitzErrorType.action,
        ));
        return;
      }

      // Process the action
      final result = await _game!.processAction(currentPlayerId, event.action);

      if (result.success) {
        // Update local state
        _updateGameState();

        emit(WordBlitzActionProcessed(
          gameState: _gameState!,
          actionType: event.action.type,
          result: result.resultData ?? {},
        ));

        // Broadcast action to other players
        if (isHost) {
          await _broadcastAction(event.action, result);
        }

        // Check if game is finished
        if (_gameState!.isGameFinished) {
          emit(WordBlitzGameFinished(
            gameState: _gameState!,
            winner: _gameState!.winner!,
          ));
        } else {
          emit(WordBlitzGameActive(
            gameState: _gameState!,
            currentPlayerId: currentPlayerId,
          ));
        }
      } else {
        emit(WordBlitzError(
          message: result.errorMessage ?? 'Action failed',
          errorType: WordBlitzErrorType.action,
        ));
      }
    } catch (e) {
      emit(WordBlitzError(
        message: 'Failed to process action: $e',
        errorType: WordBlitzErrorType.action,
      ));
    }
  }

  Future<void> _onNetworkEvent(
    WordBlitzNetworkEventReceived event,
    Emitter<WordBlitzGameState> emit,
  ) async {
    try {
      final message = event.message;

      switch (message.type) {
        case 'word_blitz_action':
          await _handleRemoteAction(message, emit);
          break;
        case 'word_blitz_state_sync':
          await _handleStateSync(message, emit);
          break;
        case 'word_blitz_event':
          await _handleGameEvent(message, emit);
          break;
      }
    } catch (e) {
      emit(WordBlitzError(
        message: 'Failed to process network event: $e',
        errorType: WordBlitzErrorType.network,
      ));
    }
  }

  Future<void> _onSyncState(
    SyncWordBlitzStateEvent event,
    Emitter<WordBlitzGameState> emit,
  ) async {
    if (_gameState == null) return;

    try {
      if (isHost) {
        await _broadcastGameState();
      } else {
        await _requestStateSync();
      }

      emit(WordBlitzGameActive(
        gameState: _gameState!,
        currentPlayerId: currentPlayerId,
      ));
    } catch (e) {
      emit(WordBlitzError(
        message: 'Failed to sync state: $e',
        errorType: WordBlitzErrorType.synchronization,
        canRetry: true,
      ));
    }
  }

  void _subscribeToGameEvents() {
    _gameEventSubscription?.cancel();
    _gameEventSubscription = _game!.gameEvents.listen((gameEvent) {
      _updateGameState();
      
      // Broadcast event to other players if host
      if (isHost) {
        _broadcastGameEvent(gameEvent);
      }
    });
  }

  void _updateGameState() {
    if (_game == null || _gameState == null) return;

    final gameStateData = _game!.gameState;
    _gameState = WordBlitzState.fromJson(gameStateData);
  }

  Future<void> _handleRemoteAction(
    NetworkMessage message,
    Emitter<WordBlitzGameState> emit,
  ) async {
    if (!isHost) return; // Only host processes remote actions

    try {
      final actionData = message.data;
      final actionType = actionData['actionType'] as String;
      final playerId = actionData['playerId'] as String;
      final data = actionData['data'] as Map<String, dynamic>;

      final action = BasicGameAction(
        type: actionType,
        playerId: playerId,
        data: data,
      );

      // Process the action locally
      add(ProcessWordBlitzActionEvent(
        WordBlitzActionFactory.fromGameAction(action),
      ));
    } catch (e) {
      emit(WordBlitzError(
        message: 'Failed to handle remote action: $e',
        errorType: WordBlitzErrorType.network,
      ));
    }
  }

  Future<void> _handleStateSync(
    NetworkMessage message,
    Emitter<WordBlitzGameState> emit,
  ) async {
    try {
      final stateData = message.data['gameState'] as Map<String, dynamic>;
      _gameState = WordBlitzState.fromJson(stateData);

      emit(WordBlitzGameActive(
        gameState: _gameState!,
        currentPlayerId: currentPlayerId,
      ));
    } catch (e) {
      emit(WordBlitzError(
        message: 'Failed to sync state: $e',
        errorType: WordBlitzErrorType.synchronization,
      ));
    }
  }

  Future<void> _handleGameEvent(
    NetworkMessage message,
    Emitter<WordBlitzGameState> emit,
  ) async {
    try {
      final eventType = message.data['eventType'] as String;
      final eventData = message.data['eventData'] as Map<String, dynamic>;

      // Update local state based on event
      _updateGameState();

      emit(WordBlitzGameActive(
        gameState: _gameState!,
        currentPlayerId: currentPlayerId,
      ));
    } catch (e) {
      emit(WordBlitzError(
        message: 'Failed to handle game event: $e',
        errorType: WordBlitzErrorType.network,
      ));
    }
  }

  Future<void> _broadcastAction(WordBlitzAction action, GameActionResult result) async {
    final message = NetworkMessage(
      type: 'word_blitz_action',
      senderId: currentPlayerId,
      data: {
        'actionType': action.type,
        'playerId': action.playerId,
        'data': action.data,
        'result': result.resultData,
        'timestamp': action.timestamp.toIso8601String(),
      },
    );

    await lanService.broadcastMessage(message);
  }

  Future<void> _broadcastGameState() async {
    if (_gameState == null) return;

    final message = NetworkMessage(
      type: 'word_blitz_state_sync',
      senderId: currentPlayerId,
      data: {
        'gameState': _gameState!.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    await lanService.broadcastMessage(message);
  }

  Future<void> _broadcastGameEvent(GameEvent gameEvent) async {
    final message = NetworkMessage(
      type: 'word_blitz_event',
      senderId: currentPlayerId,
      data: {
        'eventType': gameEvent.type,
        'eventData': gameEvent.data,
        'timestamp': gameEvent.timestamp.toIso8601String(),
      },
    );

    await lanService.broadcastMessage(message);
  }

  Future<void> _requestStateSync() async {
    final message = NetworkMessage(
      type: 'word_blitz_sync_request',
      senderId: currentPlayerId,
      data: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    await lanService.sendMessage(message);
  }

  bool _isWordBlitzMessage(NetworkMessage message) {
    const wordBlitzMessageTypes = [
      'word_blitz_action',
      'word_blitz_state_sync',
      'word_blitz_event',
      'word_blitz_sync_request',
    ];

    return wordBlitzMessageTypes.contains(message.type);
  }

  @override
  Future<void> close() {
    _gameEventSubscription?.cancel();
    _networkSubscription?.cancel();
    _game?.dispose();
    return super.close();
  }
}