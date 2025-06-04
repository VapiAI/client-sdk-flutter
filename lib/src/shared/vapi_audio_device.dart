/// Available audio output devices for Vapi calls.
/// 
/// This enum provides a platform-agnostic way to specify which audio
/// output device should be used during a call, without requiring
/// direct dependency on the daily_flutter package.
/// 
/// Example usage:
/// ```dart
/// // Switch to speakerphone during a call
/// vapi.setVapiAudioDevice(device: VapiAudioDevice.speakerphone);
/// 
/// // Switch to Bluetooth headset
/// vapi.setVapiAudioDevice(device: VapiAudioDevice.bluetooth);
/// ```
enum VapiAudioDevice {
  /// Use the device's built-in speakerphone.
  /// 
  /// This routes audio through the device's main speaker,
  /// allowing hands-free operation.
  speakerphone,
  
  /// Use wired headphones or earphones.
  /// 
  /// This routes audio through connected wired audio devices
  /// like headphones, earphones, or aux cables.
  wired,
  
  /// Use the device's earpiece speaker.
  /// 
  /// This routes audio through the small speaker typically
  /// used for phone calls, providing private audio output.
  earpiece,
  
  /// Use connected Bluetooth audio devices.
  /// 
  /// This routes audio through paired Bluetooth headphones,
  /// earbuds, or other Bluetooth audio devices.
  bluetooth,
} 
