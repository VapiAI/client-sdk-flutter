# Vapi Flutter SDK

## Overview

The Vapi Flutter SDK provides seamless integration with the Vapi voice AI platform across multiple platforms. This SDK uses a modern factory pattern architecture that automatically selects the appropriate implementation based on your target platform.

### Supported Platforms

- ✅ **Mobile** (iOS/Android) - Using Daily.co WebRTC
- ✅ **Web** - Using Vapi Web SDK with JavaScript interop
  - Modern `dart:js_interop` implementation (future-proof & Wasm compatible)
  - Extension types with full compile-time checking
  - No deprecated APIs - ready for long-term use
- 🔮 **Desktop** - Planned for future releases

## Architecture

The SDK uses a clean factory pattern with platform-specific implementations:

```
VapiClient (Factory)
├── VapiMobileClient (iOS/Android)
│   └── VapiMobileCall
└── VapiWebClient (Web)
    └── VapiWebCall
```

### Key Benefits

- **Automatic Platform Detection**: No need to worry about platform-specific code
- **Unified API**: Same code works across all platforms
- **Platform Optimizations**: Each platform uses the most efficient implementation
- **Type Safety**: Full compile-time checking with platform-specific features
- **Easy Extension**: Simple to add new platforms in the future

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  vapi: ^0.1.0
```

## Quick Start

```dart
import 'package:vapi/vapi.dart';

// Create a client - automatically selects platform implementation
final client = VapiClient('your-public-key');

// Start a call
final call = await client.start(assistantId: 'your-assistant-id');

// Listen to events
call.onEvent.listen((event) {
  switch (event.label) {
    case 'call-start':
      print('Assistant is ready and listening');
    case 'call-end':
      print('Call has ended');
    case 'message':
      print('Message: ${event.value}');
  }
});

// Send a message
await call.send({
  'type': 'add-message',
  'message': {
    'role': 'system',
    'content': 'Hello from Flutter!'
  }
});

// Clean up
await call.stop();
call.dispose();
client.dispose();
```

## Platform-Specific Features

### Mobile-Only Features

```dart
// Access mobile-specific features through type checking
if (call is VapiMobileCall) {
  // Audio device management
  call.setAudioDevice(device: VapiAudioDevice.speakerphone);
  
  // Access transport information
  print('Transport: ${call.transport.provider}');
  print('Monitor URL: ${call.monitor.listenUrl}');
}
```

### Web Features

```dart
// Access web-specific features through type checking
if (call is VapiWebCall) {
  // Make the assistant say something (web-specific feature)
  call.say('Hello! I have something to tell you.');
  
  // End call after speaking
  call.say('Goodbye!', endCallAfterSpoken: true);
  
  // Note: Audio device management is handled by browser
  // setAudioDevice() is a no-op on web platforms
}
```

## Migration from v0.0.x

The new factory pattern maintains API compatibility while providing better architecture:

### Before (v0.0.x)
```dart
final vapi = VapiClient('key');
final call = await vapi.start(assistantId: 'id');
```

### After (v0.1.x)
```dart
final client = VapiClient('key');  // Same constructor
final call = await client.start(assistantId: 'id');  // Same method
// But now with automatic platform selection!
```

### Breaking Changes

- Return type changed from `VapiCall` to `VapiCallInterface` 
- Platform-specific features now accessed through type checking
- Added `client.dispose()` for proper resource cleanup

## API Reference

### VapiClient

The main factory class that creates platform-appropriate implementations.

```dart
// Create a client
final client = VapiClient(
  'your-public-key',
  apiBaseUrl: 'https://api.vapi.ai', // Optional
);

// Start a call
final call = await client.start(
  assistantId: 'assistant-id',              // Option 1: Use existing assistant
  assistant: {...},                         // Option 2: Inline configuration
  assistantOverrides: {...},                // Optional: Override settings
  waitUntilActive: false,                   // Optional: Wait for assistant
);

// Clean up
client.dispose();
```

### VapiCallInterface

The unified interface for managing calls across platforms.

```dart
// Call information
print(call.id);
print(call.assistantId);
print(call.status);
print(call.createdAt);

// Event listening
call.onEvent.listen((event) {
  // Handle events
});

// Audio controls
call.setMuted(true);
final isMuted = call.isMuted;

// Send messages
await call.send({'type': 'add-message', ...});

// End call
await call.stop();
call.dispose();
```

## Error Handling

```dart
try {
  final client = VapiClient('your-key');
  final call = await client.start(assistantId: 'assistant-id');
} on VapiConfigurationException catch (e) {
  print('Configuration error: $e');
} on VapiMissingAssistantException catch (e) {
  print('Assistant error: $e');
} on VapiJoinFailedException catch (e) {
  print('Connection error: $e');
} catch (e) {
  print('Unexpected error: $e');
}
```

## Examples

Check out the `/example` folder for complete implementations:

- **Basic Usage**: Simple call start/stop functionality
- **Event Handling**: Comprehensive event listening examples
- **Platform Features**: Demonstrating platform-specific capabilities

## Contributing

We welcome contributions! The factory pattern architecture makes it easy to:

1. **Add New Platforms**: Implement the interfaces for new platforms
2. **Improve Existing Platforms**: Enhance mobile or web implementations
3. **Add Features**: Extend the interface with new capabilities

## Roadmap

- [x] Mobile support (iOS/Android) with Daily.co WebRTC
- [x] Factory pattern architecture
- [x] Unified API across platforms
- [x] Web support with Vapi Web SDK
- [ ] Desktop support (Windows/macOS/Linux)
- [ ] Advanced audio features
- [ ] Multiple simultaneous calls

## License

MIT License - see the [LICENSE](LICENSE) file for details.
