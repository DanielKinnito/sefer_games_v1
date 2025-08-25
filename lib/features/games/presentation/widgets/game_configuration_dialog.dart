import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/game/game_base.dart';
import '../../../../core/game/game_selection_manager.dart';

class GameConfigurationDialog extends StatefulWidget {
  final GameMetadata gameMetadata;
  final List<String> playerIds;
  final String hostId;
  final GameSelectionManager gameManager;

  const GameConfigurationDialog({
    Key? key,
    required this.gameMetadata,
    required this.playerIds,
    required this.hostId,
    required this.gameManager,
  }) : super(key: key);

  @override
  State<GameConfigurationDialog> createState() => _GameConfigurationDialogState();
}

class _GameConfigurationDialogState extends State<GameConfigurationDialog> {
  late Map<String, dynamic> _settings;
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    setState(() => _isLoading = true);

    try {
      // Load saved preferences or use defaults
      final savedSettings = await widget.gameManager.loadGamePreferences(widget.gameMetadata.gameType);
      _settings = {
        ...widget.gameMetadata.defaultConfig,
        ...?savedSettings,
      };
    } catch (e) {
      _settings = Map.from(widget.gameMetadata.defaultConfig);
    }

    setState(() => _isLoading = false);
  }

  void _updateSetting(String key, dynamic value) {
    setState(() {
      _settings[key] = value;
      _hasChanges = true;
    });
  }

  Future<void> _saveAndClose() async {
    try {
      final config = GameConfig(
        gameType: widget.gameMetadata.gameType,
        settings: _settings,
        playerIds: widget.playerIds,
        hostId: widget.hostId,
      );

      // Validate configuration
      if (!widget.gameManager.validateGameConfig(config)) {
        _showErrorSnackBar('Invalid configuration. Please check your settings.');
        return;
      }

      Navigator.of(context).pop(config);
    } catch (e) {
      _showErrorSnackBar('Failed to save configuration: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (_isLoading)
              Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: _buildConfigurationContent(),
              ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.settings,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configure ${widget.gameMetadata.displayName}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Customize your game settings',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGameSpecificSettings(),
        ],
      ),
    );
  }

  Widget _buildGameSpecificSettings() {
    switch (widget.gameMetadata.gameType) {
      case 'word_blitz':
        return _buildWordBlitzSettings();
      case 'number_guessing':
        return _buildNumberGuessingSettings();
      default:
        return _buildGenericSettings();
    }
  }

  Widget _buildWordBlitzSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Game Settings'),
        SizedBox(height: 16),
        
        // Available themes
        _buildThemeSelector(),
        SizedBox(height: 20),
        
        // Rounds to win
        _buildNumberSetting(
          'Rounds to Win',
          'roundsToWin',
          1,
          10,
          'Number of rounds a player needs to win the game',
        ),
        SizedBox(height: 20),
        
        // Round timeout
        _buildNumberSetting(
          'Round Timeout (minutes)',
          'roundTimeoutMinutes',
          1,
          10,
          'Maximum time allowed per round',
        ),
        SizedBox(height: 20),
        
        // Allow custom themes
        _buildSwitchSetting(
          'Allow Custom Themes',
          'allowCustomThemes',
          'Players can suggest their own themes',
        ),
      ],
    );
  }

  Widget _buildNumberGuessingSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Number Range'),
        SizedBox(height: 16),
        
        // Min number
        _buildNumberSetting(
          'Minimum Number',
          'minNumber',
          1,
          1000,
          'Lowest possible number to guess',
        ),
        SizedBox(height: 20),
        
        // Max number
        _buildNumberSetting(
          'Maximum Number',
          'maxNumber',
          10,
          10000,
          'Highest possible number to guess',
        ),
        SizedBox(height: 20),
        
        // Max guesses
        _buildNumberSetting(
          'Maximum Guesses',
          'maxGuesses',
          1,
          100,
          'Number of guesses allowed per player',
        ),
      ],
    );
  }

  Widget _buildGenericSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Settings'),
        SizedBox(height: 16),
        Text(
          'This game uses default settings.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildThemeSelector() {
    final availableThemes = _settings['availableThemes'] as List<String>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Themes',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Select which themes will be available during the game',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'Countries',
            'Famous People',
            'Capital Cities',
            'Movies',
            'TV Series',
            'Animals',
            'Food',
            'Sports',
            'Books',
            'Music',
          ].map((theme) {
            final isSelected = availableThemes.contains(theme);
            return FilterChip(
              label: Text(theme),
              selected: isSelected,
              onSelected: (selected) {
                final newThemes = List<String>.from(availableThemes);
                if (selected) {
                  newThemes.add(theme);
                } else {
                  newThemes.remove(theme);
                }
                _updateSetting('availableThemes', newThemes);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNumberSetting(
    String title,
    String key,
    int min,
    int max,
    String description,
  ) {
    final value = _settings[key] as int? ?? min;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: max - min,
                label: value.toString(),
                onChanged: (newValue) {
                  _updateSetting(key, newValue.round());
                },
              ),
            ),
            SizedBox(width: 12),
            Container(
              width: 60,
              child: TextFormField(
                initialValue: value.toString(),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onChanged: (text) {
                  final newValue = int.tryParse(text);
                  if (newValue != null && newValue >= min && newValue <= max) {
                    _updateSetting(key, newValue);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(String title, String key, String description) {
    final value = _settings[key] as bool? ?? false;
    
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: (newValue) => _updateSetting(key, newValue),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          SizedBox(width: 12),
          ElevatedButton(
            onPressed: _saveAndClose,
            child: Text('Start Game'),
          ),
        ],
      ),
    );
  }
}