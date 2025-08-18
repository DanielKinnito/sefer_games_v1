# Design Document

## Overview

The LAN Party Game System design builds upon the existing Flutter application architecture, completing the networking layer and integrating the lobby system with the game framework. The system uses a host-client architecture where one device acts as the game server while others connect as clients. The design leverages the existing Clean Architecture pattern with domain entities, use cases, and BLoC state management, while adding robust networking capabilities for real-time multiplayer gameplay.

## Architecture

### High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client App    │    │   Host App      │    │   Client App    │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ Lobby BLoC  │ │    │ │ Lobby BLoC  │ │    │ │ Lobby BLoC  │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ Game BLoC   │ │◄───┤ │ Game BLoC   │ ├───►│ │ Game BLoC   │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │ LAN Service │ │    │ │ LAN Service │ │    │ │ LAN Service │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Local Network  │
                    │  (UDP + HTTP)   │
                    └─────────────────┘
```

### Network Communication Flow

1. **Discovery Phase**: Host broadcasts lobby info via UDP, clients listen for broadcasts
2. **Connection Phase**: Clients connect to host via HTTP/WebSocket
3. **Lobby Phase**: Real-time communication via WebSocket for player management
4. **Game Phase**: Game actions routed through host, state synchronized to all clients

## Components and Interfaces

### Enhanced LAN Service

The existing `LanService` will be completed with full networking implementation:

```dart
class LanService {
  // Discovery
  Future<String> startHosting({int port = 8080});
  Future<void> startBroadcasting(LobbyInfo lobbyInfo);
  Future<List<DiscoveredLobby>> discoverLobbies();
  
  // Connection Management  
  Future<WebSocketConnection> connectToHost(String hostAddress, int port);
  Future<void> acceptClientConnection(WebSocket clientSocket);
  
  // Real-time Communication
  Stream<NetworkMessage> get messageStream;
  Future<void> sendToHost(NetworkMessage message);
  Future<void> broadcastToClients(NetworkMessage message);
  Future<void> sendToClient(String clientId, NetworkMessage message);
  
  // Connection Monitoring
  Stream<ConnectionStatus> get connectionStatusStream;
  Future<void> handleReconnection();
}
```

### Network Message Protocol

Standardized message format for all network communication:

```dart
class NetworkMessage {
  final String type;           // 'lobby_update', 'game_action', 'player_joined', etc.
  final String senderId;       // Player/client ID
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? targetId;      // null for broadcast, specific ID for direct messages
}
```

### Game Integration Layer

New component to bridge lobby system and game instances:

```dart
class GameSessionManager {
  Future<void> startGameSession(Lobby lobby);
  Future<void> processGameAction(String playerId, GameAction action);
  Future<void> endGameSession();
  Stream<GameEvent> get gameEventStream;
  
  // State synchronization
  Future<void> syncGameState();
  Future<void> handlePlayerReconnection(String playerId);
}
```

### Enhanced Lobby Repository

Extended to handle network operations:

```dart
abstract class LobbyRepository {
  // Existing methods...
  
  // Network-specific methods
  Future<String> startHosting(String lobbyId, {int port = 8080});
  Future<List<Lobby>> discoverLocalLobbies();
  Future<bool> connectToLobbyHost(String hostAddress, int port);
  
  // Real-time updates
  Stream<LobbyUpdate> watchLobbyUpdates(String lobbyId);
  Future<void> broadcastLobbyUpdate(String lobbyId, LobbyUpdate update);
}
```

## Data Models

### Network-Specific Models

```dart
class DiscoveredLobby {
  final String id;
  final String name;
  final String hostAddress;
  final int hostPort;
  final String gameType;
  final int currentPlayers;
  final int maxPlayers;
  final DateTime discoveredAt;
}

class ConnectionStatus {
  final bool isConnected;
  final String? hostAddress;
  final DateTime lastPing;
  final int reconnectAttempts;
}

class LobbyUpdate {
  final String type;  // 'player_joined', 'player_left', 'game_starting', etc.
  final Map<String, dynamic> data;
  final DateTime timestamp;
}
```

### Enhanced Game Models

```dart
class GameSession {
  final String sessionId;
  final String lobbyId;
  final String gameType;
  final List<String> playerIds;
  final GameBase gameInstance;
  final DateTime startedAt;
  final GameSessionStatus status;
}

enum GameSessionStatus { initializing, active, paused, finished }
```

## Error Handling

### Network Error Categories

1. **Discovery Errors**: No lobbies found, network unavailable
2. **Connection Errors**: Host unreachable, connection timeout, authentication failed
3. **Communication Errors**: Message delivery failed, protocol mismatch
4. **Synchronization Errors**: State mismatch, player desync, host migration needed

### Error Recovery Strategies

```dart
class NetworkErrorHandler {
  Future<void> handleDiscoveryError(DiscoveryError error);
  Future<void> handleConnectionError(ConnectionError error);
  Future<void> handleSyncError(SyncError error);
  
  // Automatic recovery
  Future<void> attemptReconnection(int maxAttempts = 3);
  Future<void> resyncGameState();
  Future<void> migrateHost(); // For future host migration feature
}
```

## Testing Strategy

### Unit Testing

1. **Network Protocol Testing**: Message serialization/deserialization, protocol validation
2. **Game Integration Testing**: Game state synchronization, action processing
3. **Error Handling Testing**: Network failure scenarios, recovery mechanisms
4. **BLoC Testing**: State transitions for network events, error states

### Integration Testing

1. **Multi-Device Simulation**: Mock multiple devices connecting to same lobby
2. **Network Condition Testing**: Simulate poor network conditions, disconnections
3. **Game Flow Testing**: Complete lobby-to-game-to-lobby flow
4. **Concurrent Access Testing**: Multiple players joining/leaving simultaneously

### Manual Testing Requirements

1. **Real Device Testing**: Test on actual devices connected to same WiFi network
2. **Network Stress Testing**: Test with multiple lobbies, high player counts
3. **Edge Case Testing**: Host leaving during game, network switching, app backgrounding

## Implementation Phases

### Phase 1: Core Networking (Requirements 1, 2, 7)
- Complete LAN Service implementation with UDP discovery and HTTP server
- Implement network message protocol and error handling
- Add connection status monitoring and automatic reconnection

### Phase 2: Real-time Communication (Requirement 3)
- Implement WebSocket connections for real-time updates
- Add lobby update broadcasting and synchronization
- Implement player connection/disconnection handling

### Phase 3: Game Integration (Requirements 4, 5, 6)
- Create GameSessionManager for lobby-to-game transitions
- Implement game action routing and state synchronization
- Add game event broadcasting and result handling

### Phase 4: Polish and Testing (Requirement 7)
- Comprehensive error handling and user feedback
- Performance optimization for network operations
- Extensive testing on multiple devices

## Security Considerations

### Network Security
- Local network only (no internet communication)
- Basic message validation to prevent malformed data
- Player ID verification to prevent impersonation
- Rate limiting for game actions to prevent spam

### Data Privacy
- No persistent storage of player data
- All communication stays within local network
- Automatic cleanup of lobby data when sessions end

## Performance Considerations

### Network Optimization
- Message batching for frequent updates
- Compression for large game state synchronization
- Efficient UDP broadcasting with minimal network overhead
- WebSocket connection pooling and reuse

### Memory Management
- Proper disposal of network connections and streams
- Game instance cleanup after sessions end
- Efficient message queuing and processing

### Battery Optimization
- Minimize background network activity
- Efficient polling intervals for discovery
- Proper connection lifecycle management