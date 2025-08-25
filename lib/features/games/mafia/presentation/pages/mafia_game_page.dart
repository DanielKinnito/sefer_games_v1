import 'package:flutter/material.dart';
import '../../../../../core/game/game_base.dart';
import '../../mafia_game.dart';
import '../../models/mafia_models.dart';

class MafiaGamePage extends StatefulWidget {
  final MafiaGame game;
  final String currentPlayerId;

  const MafiaGamePage({
    Key? key,
    required this.game,
    required this.currentPlayerId,
  }) : super(key: key);

  @override
  State<MafiaGamePage> createState() => _MafiaGamePageState();
}

class _MafiaGamePageState extends State<MafiaGamePage> {
  late Stream<GameEvent> _gameEvents;
  String? _selectedTarget;
  bool _hasActed = false;

  @override
  void initState() {
    super.initState();
    _gameEvents = widget.game.gameEvents;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mafia Game'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<GameEvent>(
        stream: _gameEvents,
        builder: (context, snapshot) {
          return Column(
            children: [
              _buildGameHeader(),
              _buildPhaseIndicator(),
              Expanded(
                child: _buildGameContent(),
              ),
              _buildActionPanel(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGameHeader() {
    final playerRole = widget.game.getPlayerRole(widget.currentPlayerId);
    final isAlive = widget.game.alivePlayers.contains(widget.currentPlayerId);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAlive ? Colors.green[100] : Colors.red[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Text(
            'Your Role: ${_getRoleDisplayName(playerRole)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _getRoleColor(playerRole),
            ),
          ),
          SizedBox(height: 8),
          Text(
            isAlive ? 'Status: Alive' : 'Status: Dead',
            style: TextStyle(
              fontSize: 16,
              color: isAlive ? Colors.green[700] : Colors.red[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (playerRole != null) ...[
            SizedBox(height: 8),
            Text(
              _getRoleDescription(playerRole),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhaseIndicator() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: _getPhaseColor(widget.game.currentPhase),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Day ${widget.game.currentDay} - ${_getPhaseDisplayName(widget.game.currentPhase)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Alive: ${widget.game.alivePlayers.length}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPlayersList(),
          SizedBox(height: 16),
          if (widget.game.currentPhase == GamePhase.voting)
            _buildVotingResults(),
        ],
      ),
    );
  }

  Widget _buildPlayersList() {
    final alivePlayers = widget.game.alivePlayers;
    final deadPlayers = widget.game.deadPlayers;
    
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Players',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                if (alivePlayers.isNotEmpty) ...[
                  Text(
                    'Alive (${alivePlayers.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  SizedBox(height: 4),
                  ...alivePlayers.map((playerId) => _buildPlayerTile(playerId, true)),
                ],
                if (deadPlayers.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    'Dead (${deadPlayers.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                  SizedBox(height: 4),
                  ...deadPlayers.map((playerId) => _buildPlayerTile(playerId, false)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(String playerId, bool isAlive) {
    final isSelected = _selectedTarget == playerId;
    final canSelect = _canSelectPlayer(playerId);
    final votes = widget.game.voteCounts[playerId] ?? 0;
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 2),
      color: isSelected ? Colors.blue[100] : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAlive ? Colors.green : Colors.red,
          child: Text(
            playerId.substring(0, 1).toUpperCase(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          'Player $playerId',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isAlive ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: widget.game.currentPhase == GamePhase.voting && votes > 0
            ? Text('Votes: $votes')
            : null,
        trailing: canSelect
            ? Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? Colors.blue : Colors.grey,
              )
            : null,
        onTap: canSelect
            ? () {
                setState(() {
                  _selectedTarget = isSelected ? null : playerId;
                });
              }
            : null,
      ),
    );
  }

  Widget _buildVotingResults() {
    final voteCounts = widget.game.voteCounts;
    if (voteCounts.isEmpty) {
      return Text('No votes cast yet');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Votes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        ...voteCounts.entries.map((entry) => Padding(
          padding: EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Player ${entry.key}'),
              Text('${entry.value} votes'),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildActionPanel() {
    if (!widget.game.alivePlayers.contains(widget.currentPlayerId)) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Text(
          'You are dead and cannot perform actions',
          style: TextStyle(
            fontSize: 16,
            color: Colors.red[700],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedTarget != null)
            Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Selected: Player $_selectedTarget',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final playerRole = widget.game.getPlayerRole(widget.currentPlayerId);
    final phase = widget.game.currentPhase;
    
    String buttonText;
    VoidCallback? onPressed;
    Color? buttonColor;

    if (phase == GamePhase.voting) {
      buttonText = 'Vote';
      buttonColor = Colors.red;
      onPressed = _selectedTarget != null && !_hasActed ? _performVote : null;
    } else if (phase == GamePhase.night) {
      switch (playerRole) {
        case PlayerRole.police:
          buttonText = 'Investigate';
          buttonColor = Colors.blue;
          onPressed = _selectedTarget != null && !_hasActed ? _performInvestigation : null;
          break;
        case PlayerRole.doctor:
          buttonText = 'Heal';
          buttonColor = Colors.green;
          onPressed = _selectedTarget != null && !_hasActed ? _performHeal : null;
          break;
        case PlayerRole.mafia:
          buttonText = 'Kill';
          buttonColor = Colors.red[900];
          onPressed = _selectedTarget != null && !_hasActed ? _performKill : null;
          break;
        default:
          buttonText = 'Wait for morning';
          onPressed = null;
      }
    } else {
      buttonText = 'Wait for next phase';
      onPressed = null;
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(
        buttonText,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  bool _canSelectPlayer(String playerId) {
    if (playerId == widget.currentPlayerId) return false;
    if (!widget.game.alivePlayers.contains(playerId)) return false;
    if (_hasActed) return false;

    final phase = widget.game.currentPhase;
    final playerRole = widget.game.getPlayerRole(widget.currentPlayerId);

    if (phase == GamePhase.voting) return true;
    if (phase == GamePhase.night) {
      return playerRole == PlayerRole.police ||
             playerRole == PlayerRole.doctor ||
             playerRole == PlayerRole.mafia;
    }

    return false;
  }

  void _performVote() async {
    if (_selectedTarget == null) return;

    final action = BasicGameAction(
      type: 'vote',
      playerId: widget.currentPlayerId,
      data: {'targetId': _selectedTarget!},
    );

    try {
      final result = await widget.game.processAction(widget.currentPlayerId, action);
      if (result.success) {
        setState(() {
          _hasActed = true;
          _selectedTarget = null;
        });
        _showSnackBar('Vote cast successfully');
      } else {
        _showSnackBar('Failed to vote: ${result.error}');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _performInvestigation() async {
    if (_selectedTarget == null) return;

    final action = BasicGameAction(
      type: 'police_investigate',
      playerId: widget.currentPlayerId,
      data: {'targetId': _selectedTarget!},
    );

    try {
      final result = await widget.game.processAction(widget.currentPlayerId, action);
      if (result.success) {
        setState(() {
          _hasActed = true;
          _selectedTarget = null;
        });
        final isMafia = result.data?['isMafia'] as bool? ?? false;
        _showSnackBar(
          'Investigation result: Player $_selectedTarget is ${isMafia ? 'MAFIA' : 'INNOCENT'}',
        );
      } else {
        _showSnackBar('Failed to investigate: ${result.error}');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _performHeal() async {
    if (_selectedTarget == null) return;

    final action = BasicGameAction(
      type: 'doctor_heal',
      playerId: widget.currentPlayerId,
      data: {'targetId': _selectedTarget!},
    );

    try {
      final result = await widget.game.processAction(widget.currentPlayerId, action);
      if (result.success) {
        setState(() {
          _hasActed = true;
          _selectedTarget = null;
        });
        _showSnackBar('Heal performed successfully');
      } else {
        _showSnackBar('Failed to heal: ${result.error}');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _performKill() async {
    if (_selectedTarget == null) return;

    final action = BasicGameAction(
      type: 'mafia_kill',
      playerId: widget.currentPlayerId,
      data: {'targetId': _selectedTarget!},
    );

    try {
      final result = await widget.game.processAction(widget.currentPlayerId, action);
      if (result.success) {
        setState(() {
          _hasActed = true;
          _selectedTarget = null;
        });
        _showSnackBar('Kill order sent');
      } else {
        _showSnackBar('Failed to kill: ${result.error}');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _getRoleDisplayName(PlayerRole? role) {
    switch (role) {
      case PlayerRole.mafia:
        return 'Mafia';
      case PlayerRole.police:
        return 'Police';
      case PlayerRole.doctor:
        return 'Doctor';
      case PlayerRole.joker:
        return 'Joker';
      case PlayerRole.civilian:
        return 'Civilian';
      default:
        return 'Unknown';
    }
  }

  String _getRoleDescription(PlayerRole role) {
    switch (role) {
      case PlayerRole.mafia:
        return 'Eliminate other players during the night. Win when you outnumber the town.';
      case PlayerRole.police:
        return 'Investigate players during the night to find the mafia.';
      case PlayerRole.doctor:
        return 'Heal players during the night to protect them from mafia attacks.';
      case PlayerRole.joker:
        return 'Try to get voted out during the day to win the game.';
      case PlayerRole.civilian:
        return 'Help identify and vote out the mafia during the day.';
    }
  }

  Color _getRoleColor(PlayerRole? role) {
    switch (role) {
      case PlayerRole.mafia:
        return Colors.red[900]!;
      case PlayerRole.police:
        return Colors.blue[700]!;
      case PlayerRole.doctor:
        return Colors.green[700]!;
      case PlayerRole.joker:
        return Colors.purple[700]!;
      case PlayerRole.civilian:
        return Colors.grey[700]!;
      default:
        return Colors.black;
    }
  }

  String _getPhaseDisplayName(GamePhase phase) {
    switch (phase) {
      case GamePhase.setup:
        return 'Setup';
      case GamePhase.day:
        return 'Day Discussion';
      case GamePhase.night:
        return 'Night Actions';
      case GamePhase.voting:
        return 'Voting';
    }
  }

  Color _getPhaseColor(GamePhase phase) {
    switch (phase) {
      case GamePhase.setup:
        return Colors.grey[600]!;
      case GamePhase.day:
        return Colors.orange[600]!;
      case GamePhase.night:
        return Colors.indigo[900]!;
      case GamePhase.voting:
        return Colors.red[700]!;
    }
  }
}