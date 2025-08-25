import 'package:flutter/material.dart';
import '../../../../core/game/game_base.dart';
import '../../../../core/game/game_selection_manager.dart';
import '../widgets/game_card.dart';
import '../widgets/game_configuration_dialog.dart';

class GameSelectionPage extends StatefulWidget {
  final List<String> playerIds;
  final String hostId;
  final int playerCount;
  final Function(GameSelectionResult) onGameSelected;

  const GameSelectionPage({
    Key? key,
    required this.playerIds,
    required this.hostId,
    required this.playerCount,
    required this.onGameSelected,
  }) : super(key: key);

  @override
  State<GameSelectionPage> createState() => _GameSelectionPageState();
}

class _GameSelectionPageState extends State<GameSelectionPage> {
  final GameSelectionManager _gameManager = GameSelectionManager();
  List<GameMetadata> _availableGames = [];
  List<GameMetadata> _filteredGames = [];
  List<String> _recentGames = [];
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    setState(() => _isLoading = true);

    try {
      // Load available games
      _availableGames = GameRegistry.getAvailableGames();
      
      // Filter by player count
      _filteredGames = GameRegistry.getGamesForPlayerCount(widget.playerCount);
      
      // Load recently used games
      _recentGames = await _gameManager.getRecentlyUsedGames();
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Failed to load games: $e');
    }
  }

  void _filterGames() {
    setState(() {
      List<GameMetadata> games = GameRegistry.getGamesForPlayerCount(widget.playerCount);

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        games = games.where((game) =>
            game.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            game.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            game.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
        ).toList();
      }

      // Apply category filter
      switch (_selectedFilter) {
        case 'recent':
          games = games.where((game) => _recentGames.contains(game.gameType)).toList();
          break;
        case 'quick':
          games = games.where((game) => game.estimatedDuration <= Duration(minutes: 15)).toList();
          break;
        case 'party':
          games = games.where((game) => game.tags.contains('party')).toList();
          break;
        case 'strategy':
          games = games.where((game) => game.tags.contains('strategy')).toList();
          break;
        case 'all':
        default:
          // No additional filtering
          break;
      }

      _filteredGames = games;
    });
  }

  Future<void> _selectGame(GameMetadata gameMetadata) async {
    try {
      // Show configuration dialog if needed
      final config = await _showConfigurationDialog(gameMetadata);
      if (config == null) return; // User cancelled

      // Validate configuration
      if (!_gameManager.validateGameConfig(config)) {
        _showErrorDialog('Invalid game configuration');
        return;
      }

      // Save preferences
      await _gameManager.saveGamePreferences(gameMetadata.gameType, config);

      // Return result
      final result = GameSelectionResult.success(gameMetadata.gameType, config);
      widget.onGameSelected(result);
    } catch (e) {
      _showErrorDialog('Failed to select game: $e');
    }
  }

  Future<GameConfig?> _showConfigurationDialog(GameMetadata gameMetadata) async {
    return await showDialog<GameConfig>(
      context: context,
      builder: (context) => GameConfigurationDialog(
        gameMetadata: gameMetadata,
        playerIds: widget.playerIds,
        hostId: widget.hostId,
        gameManager: _gameManager,
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Game'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadGames,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchAndFilters(),
                Expanded(
                  child: _buildGamesList(),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search games...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              _filterGames();
            },
          ),
          SizedBox(height: 12),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                SizedBox(width: 8),
                _buildFilterChip('Recent', 'recent'),
                SizedBox(width: 8),
                _buildFilterChip('Quick (≤15min)', 'quick'),
                SizedBox(width: 8),
                _buildFilterChip('Party', 'party'),
                SizedBox(width: 8),
                _buildFilterChip('Strategy', 'strategy'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = selected ? value : 'all');
        _filterGames();
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildGamesList() {
    if (_filteredGames.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.games_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: 16),
            Text(
              'No games found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search or filters'
                  : 'No games available for ${widget.playerCount} players',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredGames.length,
      itemBuilder: (context, index) {
        final game = _filteredGames[index];
        final isRecent = _recentGames.contains(game.gameType);
        
        return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: GameCard(
            gameMetadata: game,
            isRecent: isRecent,
            playerCount: widget.playerCount,
            onTap: () => _selectGame(game),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.people,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 8),
          Text(
            '${widget.playerCount} players',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          Text(
            '${_filteredGames.length} games available',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}