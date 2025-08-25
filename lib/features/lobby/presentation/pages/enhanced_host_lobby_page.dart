import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/lobby_bloc.dart';
import '../../domain/entities/lobby.dart';
import '../../../games/presentation/pages/game_selection_page.dart';
import '../../../../core/game/game_selection_manager.dart';
import '../../../../core/game/game_base.dart';
import '../widgets/connection_status_indicator.dart';
import '../widgets/real_time_player_list.dart';

class EnhancedHostLobbyPage extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool? isDarkMode;

  const EnhancedHostLobbyPage({
    Key? key,
    this.onToggleTheme,
    this.isDarkMode,
  }) : super(key: key);

  @override
  State<EnhancedHostLobbyPage> createState() => _EnhancedHostLobbyPageState();
}

class _EnhancedHostLobbyPageState extends State<EnhancedHostLobbyPage> {
  final TextEditingController _lobbyNameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final GameSelectionManager _gameManager = GameSelectionManager();
  
  int _selectedAvatar = 0;
  bool _isHosting = false;
  GameSelectionResult? _selectedGame;

  @override
  void dispose() {
    _lobbyNameController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onCreatePressed() async {
    if (_lobbyNameController.text.isEmpty || _nameController.text.isEmpty) {
      _showErrorMessage('Please fill in all fields');
      return;
    }

    // Show game selection if no game is selected
    if (_selectedGame == null || !_selectedGame!.isSuccess) {
      await _showGameSelection();
      if (_selectedGame == null || !_selectedGame!.isSuccess) {
        return; // User cancelled or error occurred
      }
    }

    setState(() => _isHosting = true);

    try {
      // Create lobby with selected game
      context.read<LobbyBloc>().add(CreateLobbyEvent(
        _lobbyNameController.text,
        _nameController.text,
        'avatar_$_selectedAvatar',
        _selectedGame!.gameType!,
        gameConfig: _selectedGame!.config?.toJson(),
      ));
    } catch (e) {
      setState(() => _isHosting = false);
      _showErrorMessage('Failed to create lobby: $e');
    }
  }

  Future<void> _showGameSelection() async {
    final result = await Navigator.of(context).push<GameSelectionResult>(
      MaterialPageRoute(
        builder: (context) => GameSelectionPage(
          playerIds: [_nameController.text], // Just host for now
          hostId: _nameController.text,
          playerCount: 1, // Will be updated as players join
          onGameSelected: (result) => Navigator.of(context).pop(result),
        ),
      ),
    );

    if (result != null && result.isSuccess) {
      setState(() => _selectedGame = result);
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Host Game'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.onToggleTheme != null)
            IconButton(
              icon: Icon(widget.isDarkMode == true ? Icons.light_mode : Icons.dark_mode),
              onPressed: widget.onToggleTheme,
            ),
        ],
      ),
      body: BlocListener<LobbyBloc, LobbyState>(
        listener: (context, state) {
          if (state is LobbyError) {
            setState(() => _isHosting = false);
            _showErrorMessage(state.message);
          } else if (state is LobbyCreated) {
            setState(() => _isHosting = false);
            // Navigate to lobby waiting room
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => LobbyWaitingRoomPage(
                  lobby: state.lobby,
                  selectedGame: _selectedGame,
                ),
              ),
            );
          }
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildWelcomeSection(),
                  SizedBox(height: 24),
                  _buildLobbyDetailsSection(),
                  SizedBox(height: 24),
                  _buildHostDetailsSection(),
                  SizedBox(height: 24),
                  _buildGameSelectionSection(),
                  SizedBox(height: 32),
                  _buildCreateButton(),
                ],
              ),
            ),
            if (_isHosting) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.games,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: 12),
            Text(
              'Host a Game',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create a lobby and invite friends to play together',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLobbyDetailsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lobby Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _lobbyNameController,
              decoration: InputDecoration(
                labelText: 'Lobby Name',
                hintText: 'Enter a name for your lobby',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostDetailsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your display name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Choose Avatar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            _buildAvatarSelection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSelection() {
    return Wrap(
      spacing: 8,
      children: List.generate(6, (index) {
        final isSelected = _selectedAvatar == index;
        return GestureDetector(
          onTap: () => setState(() => _selectedAvatar = index),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(24),
              border: isSelected 
                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                  : null,
            ),
            child: Icon(
              Icons.person,
              color: isSelected 
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildGameSelectionSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Selected Game',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                TextButton.icon(
                  onPressed: _showGameSelection,
                  icon: Icon(Icons.games),
                  label: Text(_selectedGame == null ? 'Select Game' : 'Change Game'),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (_selectedGame != null && _selectedGame!.isSuccess)
              _buildSelectedGameInfo()
            else
              _buildNoGameSelected(),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedGameInfo() {
    final gameMetadata = GameRegistry.getGameMetadata(_selectedGame!.gameType!);
    if (gameMetadata == null) return _buildNoGameSelected();

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.games,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameMetadata.displayName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${gameMetadata.minPlayers}-${gameMetadata.maxPlayers} players • ${_formatDuration(gameMetadata.estimatedDuration)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoGameSelected() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.games_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No game selected. Tap "Select Game" to choose a game.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return ElevatedButton(
      onPressed: _isHosting ? null : _onCreatePressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        _isHosting ? 'Creating Lobby...' : 'Create Lobby',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Creating lobby...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
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

/// Lobby waiting room page with game information
class LobbyWaitingRoomPage extends StatelessWidget {
  final Lobby lobby;
  final GameSelectionResult? selectedGame;

  const LobbyWaitingRoomPage({
    Key? key,
    required this.lobby,
    this.selectedGame,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lobby.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          if (selectedGame != null) _buildGameInfo(context),
          Expanded(
            child: RealTimePlayerList(
              lobbyBloc: context.read<LobbyBloc>(),
            ),
          ),
          _buildStartGameButton(context),
        ],
      ),
    );
  }

  Widget _buildGameInfo(BuildContext context) {
    final gameMetadata = GameRegistry.getGameMetadata(selectedGame!.gameType!);
    if (gameMetadata == null) return SizedBox.shrink();

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.games,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Selected Game',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              gameMetadata.displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              gameMetadata.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text('${gameMetadata.minPlayers}-${gameMetadata.maxPlayers} players'),
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                ),
                SizedBox(width: 8),
                Chip(
                  label: Text('~${gameMetadata.estimatedDuration.inMinutes}min'),
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartGameButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () {
          // TODO: Implement game start functionality
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Starting game...')),
          );
        },
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 48),
        ),
        child: Text('Start Game'),
      ),
    );
  }
}