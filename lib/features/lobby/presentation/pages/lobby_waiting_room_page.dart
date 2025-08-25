import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/lobby_bloc.dart';
import '../../domain/entities/lobby.dart';
import '../../domain/entities/player.dart';
import '../../../games/presentation/pages/games_page.dart';
import '../../../../core/presentation/widgets/bottom_nav_bar.dart';
import '../../../../core/presentation/mixins/error_handler_mixin.dart';
import '../widgets/primary_button.dart';

class LobbyWaitingRoomPage extends StatefulWidget {
  final Lobby lobby;
  final String currentPlayerId;
  final bool isHost;
  final VoidCallback? onToggleTheme;
  final bool? isDarkMode;

  const LobbyWaitingRoomPage({
    super.key,
    required this.lobby,
    required this.currentPlayerId,
    required this.isHost,
    this.onToggleTheme,
    this.isDarkMode,
  });

  @override
  State<LobbyWaitingRoomPage> createState() => _LobbyWaitingRoomPageState();
}

class _LobbyWaitingRoomPageState extends State<LobbyWaitingRoomPage>
    with ErrorHandlerMixin, SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedGameIndex = 0;

  @override
  void initState() {
    super.initState();
    // Only create tab controller if user is host
    if (widget.isHost) {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  @override
  void dispose() {
    if (widget.isHost) {
      _tabController.dispose();
    }
    super.dispose();
  }

  void _leaveLobby() {
    context.read<LobbyBloc>().add(
      LeaveLobbyEvent(widget.lobby.id, widget.currentPlayerId),
    );
    Navigator.of(context).pop();
  }

  void _startGame() {
    // Navigate to game session
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GamesPage(
          onToggleTheme: widget.onToggleTheme,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          widget.lobby.name,
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Theme.of(context).appBarTheme.foregroundColor,
        ),
        actions: [
          if (widget.onToggleTheme != null && widget.isDarkMode != null)
            IconButton(
              icon: Icon(
                widget.isDarkMode! ? Icons.light_mode : Icons.dark_mode,
                color: Colors.deepPurple,
                size: 28,
              ),
              onPressed: widget.onToggleTheme,
              tooltip: widget.isDarkMode!
                  ? 'Switch to Light Mode'
                  : 'Switch to Dark Mode',
            ),
        ],
        bottom: widget.isHost
            ? TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                indicatorColor: Theme.of(context).primaryColor,
                tabs: const [
                  Tab(text: 'Players', icon: Icon(Icons.people)),
                  Tab(text: 'Games', icon: Icon(Icons.games)),
                ],
              )
            : null,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Lobby info header
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.gamepad,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Game: ${widget.lobby.gameType}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      if (widget.isHost)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'HOST',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Players: ${widget.lobby.players.length}/${widget.lobby.maxPlayers}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: widget.isHost
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPlayersTab(),
                        _buildGamesTab(),
                      ],
                    )
                  : _buildPlayersTab(),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (widget.isHost && widget.lobby.players.length >= 2)
                    PrimaryButton(
                      label: 'Start Game',
                      onPressed: _startGame,
                    ),
                  if (widget.isHost && widget.lobby.players.length >= 2)
                    const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _leaveLobby,
                          icon: const Icon(Icons.exit_to_app),
                          label: Text(widget.isHost ? 'Close Lobby' : 'Leave Lobby'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom nav bar
            const BottomNavBar(selectedIndex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersTab() {
    return BlocBuilder<LobbyBloc, LobbyState>(
      builder: (context, state) {
        List<Player> players = widget.lobby.players;
        
        // Update players list if we have newer state
        if (state is LobbyHosting) {
          players = state.lobby.players;
        } else if (state is PlayerJoined) {
          players = state.lobby.players;
        } else if (state is PlayerLeft) {
          players = state.lobby.players;
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index];
            final isCurrentPlayer = player.id == widget.currentPlayerId;
            final isHost = player.id == widget.lobby.hostId;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isHost 
                      ? Colors.amber 
                      : Theme.of(context).primaryColor,
                  child: Text(
                    player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: isHost ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        player.name,
                        style: TextStyle(
                          fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
                          color: isCurrentPlayer 
                              ? Theme.of(context).primaryColor 
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                    if (isHost)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (isCurrentPlayer && !isHost)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  'Avatar: ${player.avatarId}',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                trailing: player.isReady
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : Icon(Icons.schedule, color: Colors.orange),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGamesTab() {
    final availableGames = ['NumberGuessing', 'WordBlitz', 'Trivia', '20Questions'];
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Game',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: availableGames.length,
              itemBuilder: (context, index) {
                final game = availableGames[index];
                final isSelected = _selectedGameIndex == index;
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: isSelected 
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Theme.of(context).cardColor,
                  child: ListTile(
                    leading: Icon(
                      _getGameIcon(game),
                      color: isSelected 
                          ? Theme.of(context).primaryColor 
                          : Theme.of(context).iconTheme.color,
                    ),
                    title: Text(
                      game,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected 
                            ? Theme.of(context).primaryColor 
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    subtitle: Text(
                      _getGameDescription(game),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    trailing: isSelected 
                        ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedGameIndex = index;
                      });
                      // TODO: Update lobby game type
                      // context.read<LobbyBloc>().add(UpdateLobbyGameTypeEvent(widget.lobby.id, game));
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getGameIcon(String game) {
    switch (game) {
      case 'NumberGuessing':
        return Icons.numbers;
      case 'WordBlitz':
        return Icons.text_fields;
      case 'Trivia':
        return Icons.quiz;
      case '20Questions':
        return Icons.help_outline;
      default:
        return Icons.games;
    }
  }

  String _getGameDescription(String game) {
    switch (game) {
      case 'NumberGuessing':
        return 'Guess the secret number';
      case 'WordBlitz':
        return 'Fast-paced word game';
      case 'Trivia':
        return 'Test your knowledge';
      case '20Questions':
        return 'Guess with yes/no questions';
      default:
        return 'Fun party game';
    }
  }
}
