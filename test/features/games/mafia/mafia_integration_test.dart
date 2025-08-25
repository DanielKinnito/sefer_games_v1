import 'package:flutter_test/flutter_test.dart';
import 'package:sefer_games_v1/core/game/game_base.dart';
import 'package:sefer_games_v1/features/games/game_initialization.dart';
import 'package:sefer_games_v1/features/games/mafia/mafia_game.dart';

void main() {
  group('Mafia Game Integration', () {
    setUpAll(() {
      // Initialize all games including Mafia
      initializeGames();
    });

    test('should be registered in GameRegistry', () {
      // Check if Mafia game is registered
      expect(GameRegistry.isGameTypeSupported(MafiaGame.gameTypeId), isTrue);
      
      // Create a game instance
      final game = GameRegistry.createGame(MafiaGame.gameTypeId);
      expect(game, isNotNull);
      expect(game, isA<MafiaGame>());
      expect(game!.gameType, equals(MafiaGame.gameTypeId));
      expect(game.gameName, equals('Mafia'));
    });

    test('should have correct metadata', () {
      final metadata = GameRegistry.getGameMetadata(MafiaGame.gameTypeId);
      expect(metadata, isNotNull);
      expect(metadata!.displayName, equals('Mafia'));
      expect(metadata.gameType, equals(MafiaGame.gameTypeId));
      expect(metadata.minPlayers, equals(6));
      expect(metadata.maxPlayers, equals(20));
      expect(metadata.tags, contains('social'));
      expect(metadata.tags, contains('deduction'));
    });

    test('should create game with default configuration', () {
      final game = GameRegistry.createGame(MafiaGame.gameTypeId) as MafiaGame?;
      expect(game, isNotNull);
      
      expect(game!.minPlayers, equals(6)); // 2 mafia + 1 police + 1 doctor + 2 civilians
      expect(game.maxPlayers, equals(20));
      expect(game.gameType, equals('mafia'));
      expect(game.isGameFinished, isFalse);
    });

    test('should work with direct game instantiation', () async {
      final game = MafiaGame(
        mafiaCount: 2,
        policeCount: 1,
        doctorCount: 1,
        jokerCount: 0,
      );
      
      // Create a lobby with enough players for Mafia
      final playerIds = List.generate(8, (i) => 'player_$i');
      
      // Initialize and start the game
      await game.initializeGame(playerIds);
      await game.startGame();
      
      expect(game.alivePlayers.length, equals(8));
      expect(game.currentPhase, equals(GamePhase.day));
      expect(game.currentDay, equals(1));
      
      // Clean up
      game.dispose();
    });

    test('should handle game actions directly', () async {
      final game = MafiaGame(
        mafiaCount: 1,
        policeCount: 1,
        doctorCount: 1,
        jokerCount: 0,
      );
      
      // Create a lobby with players
      final playerIds = List.generate(6, (i) => 'player_$i');
      
      await game.initializeGame(playerIds);
      await game.startGame();
      
      // Start voting phase
      final startVotingAction = BasicGameAction(
        type: 'start_voting',
        playerId: playerIds.first, // Host
        data: {},
      );
      
      final result = await game.processAction(playerIds.first, startVotingAction);
      expect(result.success, isTrue);
      expect(game.currentPhase, equals(GamePhase.voting));
      
      // Cast a vote
      final voteAction = BasicGameAction(
        type: 'vote',
        playerId: playerIds[0],
        data: {'targetId': playerIds[1]},
      );
      
      final voteResult = await game.processAction(playerIds[0], voteAction);
      expect(voteResult.success, isTrue);
      expect(game.voteCounts[playerIds[1]], equals(1));
      
      // Clean up
      game.dispose();
    });

    test('should validate player count requirements', () async {
      final game = MafiaGame();
      
      // Try with too few players
      final tooFewPlayers = ['player1', 'player2', 'player3'];
      
      expect(
        () async => await game.initializeGame(tooFewPlayers),
        throwsA(isA<ArgumentError>()),
      );
      
      game.dispose();
    });

    test('should handle custom game configuration', () async {
      final game = MafiaGame(
        mafiaCount: 3,
        policeCount: 2,
        doctorCount: 1,
        jokerCount: 1,
        doctorCanSaveSamePerson: true,
        doctorCanSaveSelf: false,
      );
      
      final playerIds = List.generate(10, (i) => 'player_$i');
      
      await game.initializeGame(playerIds);
      
      // Verify the custom configuration was applied
      final gameState = game.gameState;
      expect(gameState['mafiaCount'], equals(3));
      expect(gameState['policeCount'], equals(2));
      expect(gameState['doctorCount'], equals(1));
      expect(gameState['jokerCount'], equals(1));
      expect(gameState['doctorCanSaveSamePerson'], isTrue);
      expect(gameState['doctorCanSaveSelf'], isFalse);
      
      // Clean up
      game.dispose();
    });
  });
}