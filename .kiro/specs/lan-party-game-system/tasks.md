# Implementation Plan

- [ ] 1. Complete core networking infrastructure
  - Implement UDP discovery broadcasting and listening functionality
  - Complete HTTP server setup with proper request routing
  - Create network message protocol classes and serialization
  - _Requirements: 1.3, 1.4, 2.1, 7.2_

- [x] 1.1 Implement UDP discovery broadcasting system


  - Write UDP broadcast sender for lobby advertisement
  - Implement UDP listener for lobby discovery
  - Create DiscoveredLobby model and parsing logic
  - Add network interface detection for proper IP resolution
  - _Requirements: 1.3, 2.1_

- [x] 1.2 Complete HTTP server implementation in LanService


  - Implement proper HTTP request routing for lobby endpoints
  - Add CORS headers for cross-origin requests
  - Create lobby info endpoint that returns current lobby state
  - Implement player join/leave endpoints with validation
  - _Requirements: 1.2, 2.3, 7.2_

- [x] 1.3 Create network message protocol classes



  - Implement NetworkMessage class with JSON serialization
  - Create message type constants and validation
  - Add message timestamp and sender ID handling
  - Write unit tests for message serialization/deserialization
  - _Requirements: 3.1, 3.2, 5.1, 5.2_

- [ ] 2. Implement WebSocket real-time communication
  - Add WebSocket server capability to LanService
  - Implement WebSocket client connection management
  - Create message broadcasting and targeted messaging
  - Add connection status monitoring and heartbeat system
  - _Requirements: 3.1, 3.2, 3.4, 5.2, 5.3_

- [x] 2.1 Add WebSocket server to LanService


  - Upgrade HTTP server to support WebSocket connections
  - Implement WebSocket connection acceptance and management
  - Create client connection registry with unique IDs
  - Add WebSocket message routing and broadcasting capabilities
  - _Requirements: 3.1, 3.2, 5.2_

- [x] 2.2 Implement WebSocket client connection in LanService



  - Create WebSocket client connection method
  - Add automatic reconnection logic with exponential backoff
  - Implement connection status stream for UI updates
  - Create message sending queue for offline message handling
  - _Requirements: 2.3, 3.4, 7.1_

- [x] 2.3 Create connection monitoring and heartbeat system


  - Implement periodic ping/pong messages between host and clients
  - Add connection timeout detection and automatic cleanup
  - Create connection status events for BLoC state updates
  - Write reconnection handling with user feedback
  - _Requirements: 3.4, 7.1_

- [ ] 3. Enhance lobby data layer for network operations
  - Update LobbyDataSourceImpl to use LanService for network operations
  - Implement real-time lobby update streaming
  - Add network-specific error handling and retry logic
  - Create lobby synchronization mechanisms
  - _Requirements: 1.1, 2.4, 3.1, 3.2, 7.3_

- [x] 3.1 Update LobbyDataSourceImpl with network integration


  - Modify createLobby to integrate with LanService hosting
  - Update joinLobby to use WebSocket connection establishment
  - Implement getAvailableLobbies using UDP discovery
  - Add proper error handling for network operations
  - _Requirements: 1.1, 1.2, 2.1, 2.3_

- [x] 3.2 Implement real-time lobby update streaming


  - Create watchLobby method that returns lobby update stream
  - Implement lobby update broadcasting when players join/leave
  - Add lobby state synchronization across all connected clients
  - Create LobbyUpdate model for different update types
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 3.3 Add network error handling to data layer


  - Implement retry logic for failed network operations
  - Create specific error types for different network failures
  - Add timeout handling for lobby operations
  - Implement graceful degradation when network is unavailable
  - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [ ] 4. Create game session management system
  - Implement GameSessionManager class for lobby-to-game transitions
  - Create game action routing and state synchronization
  - Add game event broadcasting to all players
  - Implement game session lifecycle management
  - _Requirements: 4.1, 4.2, 4.3, 5.1, 5.2, 5.3_

- [x] 4.1 Implement GameSessionManager class



  - Create GameSessionManager with game instance management
  - Implement startGameSession method that initializes selected game
  - Add game action processing with host-client routing
  - Create game event stream for real-time game updates
  - _Requirements: 4.2, 4.3, 5.1, 6.4_

- [x] 4.2 Implement game action routing system


  - Create game action message types and validation
  - Implement client-to-host game action forwarding
  - Add host game action processing and result broadcasting
  - Create game state synchronization for all players
  - _Requirements: 5.1, 5.2, 5.3_

- [x] 4.3 Add game session lifecycle management


  - Implement game start validation (minimum players, game type)
  - Create game end handling with results broadcasting
  - Add return-to-lobby functionality after game completion
  - Implement game session cleanup and resource disposal
  - _Requirements: 4.1, 4.4, 4.5, 5.5, 6.5_

- [ ] 5. Update BLoC layer for network events
  - Enhance LobbyBloc with real-time update handling
  - Create GameBloc for game session state management
  - Add network status events and error state handling
  - Implement automatic state synchronization
  - _Requirements: 3.1, 3.2, 4.2, 5.2, 7.1_

- [x] 5.1 Enhance LobbyBloc with real-time updates



  - Add lobby update stream subscription to LobbyBloc
  - Implement real-time player join/leave event handling
  - Create network status events (connected, disconnected, reconnecting)
  - Add automatic lobby state synchronization from network updates
  - _Requirements: 3.1, 3.2, 3.4_

- [x] 5.2 Create GameBloc for game session management


  - Implement GameBloc with game session state management
  - Add game action events and state transitions
  - Create game event stream subscription for real-time updates
  - Implement game result handling and lobby return logic
  - _Requirements: 4.2, 5.1, 5.2, 5.5_

- [x] 5.3 Add comprehensive error handling to BLoCs


  - Implement network error state handling in LobbyBloc
  - Add retry mechanisms for failed operations
  - Create user-friendly error messages for different failure types
  - Implement automatic recovery for temporary network issues
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 6. Update UI layer for real-time features
  - Modify lobby pages to handle real-time player updates
  - Add connection status indicators and error displays
  - Create game session UI integration
  - Implement loading states and user feedback
  - _Requirements: 3.1, 3.2, 7.1, 7.5_

- [x] 6.1 Update lobby pages for real-time functionality


  - Modify HostLobbyPage to show real-time player joins
  - Update JoinLobbyPage to display live lobby discovery
  - Add connection status indicators to both pages
  - Implement automatic UI updates from BLoC state changes
  - _Requirements: 3.1, 3.2, 7.1_

- [x] 6.2 Add comprehensive error handling to UI


  - Create error dialog components for network failures
  - Add retry buttons and manual refresh options
  - Implement loading indicators for network operations
  - Create connection status widgets with reconnection feedback
  - _Requirements: 7.1, 7.2, 7.3, 7.5_

- [x] 6.3 Create game session UI integration


  - Implement navigation from lobby to game sessions
  - Create game UI container that loads appropriate game widgets
  - Add game action input handling and result display
  - Implement return-to-lobby navigation after game completion
  - _Requirements: 4.2, 4.3, 5.5_

- [ ] 7. Implement comprehensive testing
  - Create unit tests for network protocol and message handling
  - Add integration tests for lobby and game session flows
  - Implement BLoC tests for all network-related state transitions
  - Create mock network services for testing
  - _Requirements: All requirements - testing coverage_

- [ ] 7.1 Create network protocol unit tests
  - Write tests for NetworkMessage serialization/deserialization
  - Test UDP discovery broadcasting and listening
  - Create tests for WebSocket connection management
  - Add tests for error handling and retry mechanisms
  - _Requirements: 1.3, 1.4, 2.1, 3.4_

- [ ] 7.2 Implement lobby and game integration tests
  - Create tests for complete lobby creation and joining flow
  - Test real-time player updates and synchronization
  - Add tests for game session start and action processing
  - Implement tests for error scenarios and recovery
  - _Requirements: 1.1, 2.3, 4.2, 5.1_

- [ ] 7.3 Add comprehensive BLoC testing
  - Test LobbyBloc with network events and error states
  - Create GameBloc tests for game session management
  - Add tests for automatic reconnection and state recovery
  - Implement tests for UI state synchronization
  - _Requirements: 3.1, 3.2, 5.2, 7.1_

- [ ] 8. Add final polish and optimization
  - Optimize network message frequency and batching
  - Add performance monitoring for network operations
  - Implement final error handling improvements
  - Create user documentation and help screens
  - _Requirements: 7.5, Performance considerations_

- [ ] 8.1 Optimize network performance
  - Implement message batching for frequent updates
  - Add network message compression for large payloads
  - Optimize UDP broadcasting frequency and timing
  - Create efficient connection pooling and reuse
  - _Requirements: Performance optimization_

- [ ] 8.2 Add final error handling and user experience improvements
  - Implement comprehensive error logging and reporting
  - Add user-friendly error messages with suggested actions
  - Create help screens explaining network setup and troubleshooting
  - Add final UI polish for loading states and transitions
  - _Requirements: 7.5_