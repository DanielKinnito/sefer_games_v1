import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/lobby_info_card.dart';
import '../widgets/players_list_card.dart';
import '../widgets/primary_button.dart';
import '../models/lobby_info_data.dart';
import '../bloc/lobby_bloc.dart';
import '../../lobby_di.dart';
import 'package:sefer_games_v1/core/presentation/widgets/bottom_nav_bar.dart';

class LobbyManagementPage extends StatefulWidget {
  final LobbyInfoData initialLobbyInfo;
  final VoidCallback? onToggleTheme;
  final bool? isDarkMode;

  const LobbyManagementPage({
    super.key,
    required this.initialLobbyInfo,
    this.onToggleTheme,
    this.isDarkMode,
  });

  @override
  State<LobbyManagementPage> createState() => _LobbyManagementPageState();
}

class _LobbyManagementPageState extends State<LobbyManagementPage>
    with TickerProviderStateMixin {
  late LobbyBloc _lobbyBloc;
  late TabController _tabController;
  late LobbyInfoData _currentLobbyInfo;

  @override
  void initState() {
    super.initState();
    _lobbyBloc = LobbyDI.getBloc();
    _tabController = TabController(length: 2, vsync: this);
    _currentLobbyInfo = widget.initialLobbyInfo;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onStartGame() {
    if (_currentLobbyInfo.players.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 2 players are required to start the game'),
        ),
      );
      return;
    }

    // TODO: Implement start game logic with BLoC
    // For now, show a placeholder message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting game...')),
    );
  }

  void _onLeaveLobby() {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Lobby'),
        content: const Text('Are you sure you want to leave this lobby?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    ).then((shouldLeave) {
      if (shouldLeave == true) {
        // TODO: Get current player ID
        const currentPlayerId = 'current_player'; // Placeholder
        _lobbyBloc.add(LeaveLobbyEvent(_currentLobbyInfo.lobbyId, currentPlayerId));
        Navigator.of(context).pop(); // Go back to previous screen
      }
    });
  }

  void _onRefresh() {
    // TODO: Implement refresh logic with BLoC
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          _currentLobbyInfo.lobbyName,
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Theme.of(context).appBarTheme.foregroundColor,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
            tooltip: 'Refresh lobby',
          ),
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
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'leave':
                  _onLeaveLobby();
                  break;
                case 'copy_id':
                  // TODO: Copy lobby ID to clipboard
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy_id',
                child: ListTile(
                  leading: Icon(Icons.copy),
                  title: Text('Copy Lobby ID'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'leave',
                child: ListTile(
                  leading: Icon(Icons.exit_to_app, color: Colors.red),
                  title: Text('Leave Lobby', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.info_outline),
              text: 'Info',
            ),
            Tab(
              icon: Icon(Icons.leaderboard),
              text: 'Leaderboard',
            ),
          ],
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Theme.of(context).iconTheme.color?.withOpacity(0.6),
          indicatorColor: Theme.of(context).primaryColor,
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocListener<LobbyBloc, LobbyState>(
        bloc: _lobbyBloc,
        listener: (context, state) {
          if (state is LobbyError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          // TODO: Handle other states and update _currentLobbyInfo when lobby state changes
        },
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Info Tab
                    _buildInfoTab(),
                    // Leaderboard Tab
                    _buildLeaderboardTab(),
                  ],
                ),
              ),
              // Action buttons
              _buildActionButtons(),
              // Bottom navigation
              const BottomNavBar(selectedIndex: 0), // Lobby section
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          LobbyInfoCard(lobbyInfo: _currentLobbyInfo),
          const SizedBox(height: 16),
          PlayersListCard(
            players: _currentLobbyInfo.players,
            showScores: false,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_currentLobbyInfo.leaderboard.isNotEmpty)
            PlayersListCard(
              players: _currentLobbyInfo.players,
              leaderboard: _currentLobbyInfo.leaderboard,
              showScores: true,
            )
          else
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 64,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Games Played Yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).textTheme.titleLarge?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start a game to see player scores and rankings',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_currentLobbyInfo.isGameStarted) ...[
              PrimaryButton(
                label: 'Start Game',
                onPressed: _onStartGame,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _onRefresh,
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Refresh'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _onLeaveLobby,
                      icon: const Icon(Icons.exit_to_app, size: 20, color: Colors.red),
                      label: const Text('Leave', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              PrimaryButton(
                label: 'View Game',
                onPressed: () {
                  // TODO: Navigate to game view
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _onLeaveLobby,
                icon: const Icon(Icons.exit_to_app, size: 20, color: Colors.red),
                label: const Text('Leave Game', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
