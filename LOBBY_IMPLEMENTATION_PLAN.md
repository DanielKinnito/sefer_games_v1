# LAN Party Game Lobby - Implementation Plan

## Current Status ✅

### Completed:
- ✅ Fixed domain/repository interface mismatches
- ✅ Updated data layer to handle proper Player objects instead of just IDs
- ✅ Created LAN-specific use cases (StartHosting, DiscoverLocalLobbies, ConnectToLobbyHost)
- ✅ Enhanced lobby bloc with proper state management
- ✅ Added LAN service placeholder/gateway for future networking
- ✅ Implemented stream-based lobby watching for real-time updates

### Current Architecture:
```
lib/features/lobby/
├── domain/
│   ├── entities/ (Lobby, Player)
│   ├── repositories/ (LobbyRepository - with LAN methods)
│   └── usecases/ (CreateLobby, JoinLobby, StartHosting, etc.)
├── data/
│   ├── datasources/ (LobbyDataSource - with proper Player handling)
│   ├── models/ (LobbyModel, PlayerModel)
│   ├── repositories/ (LobbyRepositoryImpl)
│   └── services/ (LanService - networking gateway)
└── presentation/
    ├── bloc/ (LobbyBloc - enhanced with LAN events)
    ├── pages/ (Existing UI pages)
    └── widgets/ (Existing UI components)
```

## Next Immediate Steps 🎯

### Phase 1: Basic Integration (Next 1-2 sessions)
1. **Update UI Pages to use new BLoC structure**
   - Fix HostLobbyPage to use proper CreateLobbyEvent
   - Fix JoinLobbyPage to use proper JoinLobbyEvent
   - Add proper form validation and player details collection

2. **Wire up the BLoC in UI**
   - Add BlocProvider in main.dart or lobby pages
   - Connect UI actions to BLoC events
   - Handle BLoC states in UI (loading, success, error)

3. **Test Basic Functionality**
   - Create lobby with proper player details
   - Join lobby with player name/avatar
   - Leave lobby functionality
   - Real-time lobby updates

### Phase 2: LAN Foundation (Next 2-3 sessions)
1. **Enhance LAN Service**
   - Implement basic HTTP server for lobby hosting
   - Add network discovery using UDP broadcast
   - Create message protocol for lobby communication

2. **Add Game State Management**
   - Lobby waiting state → in-game state transitions
   - Player ready/not ready status
   - Game start coordination

3. **Real-time Communication**
   - WebSocket/TCP connections for real-time updates
   - Player connection status monitoring
   - Automatic reconnection handling

### Phase 3: Game Integration Framework (Future sessions)
1. **Abstract Game Interface**
   - Create base game interface for future games
   - Define common game states and transitions
   - Implement game-agnostic lobby → game flow

2. **Game Session Management**
   - Start/stop game sessions
   - Handle game results and scoring
   - Return to lobby functionality

## LAN Architecture Design 🏗️

### Network Communication Strategy:
```
Host Device (Creates Lobby):
1. Starts HTTP server on local network
2. Broadcasts lobby availability via UDP
3. Manages player connections and game state
4. Coordinates game sessions

Client Devices (Join Lobby):
1. Discover lobbies via UDP listening
2. Connect to host via HTTP/WebSocket
3. Send/receive game data through host
4. Handle connection drops gracefully
```

### Future Game Integration:
```
Lobby System → Game Interface → Specific Games
                    ↓
            [Word Games, Trivia, etc.]
```

## Technology Considerations 📋

### Current Dependencies Needed:
- `http` package for server functionality
- `web_socket_channel` for real-time communication (future)
- Possibly `network_info_plus` for network discovery

### Game Design Patterns:
- **Command Pattern**: For game actions
- **Observer Pattern**: For real-time updates
- **Strategy Pattern**: For different game types
- **State Pattern**: For game state management

## Placeholder Components 🔧

Currently implemented as placeholders/gateways:
- **LanService**: Ready for full networking implementation
- **Data Source**: Supports both local and networked data
- **Repository**: Abstracted to handle any backend
- **Use Cases**: Ready for both local and LAN operations

## Success Metrics 🎯

### Short-term (Next session):
- [ ] Can create a lobby with player details
- [ ] Can join an existing lobby
- [ ] UI properly reflects lobby state changes
- [ ] Basic error handling works

### Medium-term (Next few sessions):
- [ ] Multiple devices can discover each other on LAN
- [ ] Players can join/leave in real-time
- [ ] Lobby host can start a game session
- [ ] Basic game state synchronization

### Long-term (Future):
- [ ] Stable multi-device party game sessions
- [ ] Multiple game types supported
- [ ] Robust error handling and reconnection
- [ ] Smooth lobby ↔ game transitions

## Notes for Development 📝

1. **Keep modularity**: Each game should be a separate feature
2. **Abstract early**: LAN logic should be reusable for any party game
3. **Handle edge cases**: Network drops, host leaving, etc.
4. **Test thoroughly**: Multi-device testing is crucial
5. **Performance**: Consider message frequency and data size
