# Vapi Flutter SDK

## Minimum requirements

### Mobile

This package relies heavily on the [`daily_flutter`](https://pub.dev/packages/daily_flutter) package. Please refer to the [daily_flutter pub.dev page](https://pub.dev/packages/daily_flutter) for the most up-to-date version constraints and platform requirements.

### Web

- No special requirements. The Vapi Web SDK is loaded under the hood via [jsdelivr](https://www.jsdelivr.com/), and a specific version is hardcoded to ensure compatibility with this Flutter package. For more details, see `lib/src/platform/web/vapi_web_client.dart`.

## Setup

Add `vapi` as a dependency:

```
flutter pub add vapi
```

Then, before creating a VapiClient or calling runApp in your main function, ensure the platform is initialized:

```dart
void main() async {
  // Wait for the Vapi SDK to be ready (required for web, instant on mobile)
  await VapiClient.platformInitialized.future;
  runApp(const MyApp());
}
```

> **Note:** This is required on web to ensure the Vapi Web SDK is loaded before you create a client or start a call. On mobile, this will complete instantly.

Then, follow the platform-specific setup instructions for `permission_handler`:

### iOS

According to the permission_handler instructions above, add the permission flags for microphone.

Also add this to your Info.plist:

```
<key>NSMicrophoneUsageDescription</key>
<string>This app requires access to the microphone for live audio calls.</string>
```

You'll also need to ensure this is set in your Podfile:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',

        'PERMISSION_MICROPHONE=1',
      ]
    end
  end
end
```

We also recommend adding the audio background mode to your app's capabilities.

### Android

Add the necessary permissions to your AndroidManifest.xml:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

Add the permission flags for microphone according to the permission_handler instructions above.

---

### Web

> No setup is required for web! However, please note:
>
> **Hot restart/hot reload caveat:**
> Web does not fully support hot restart or hot reload if a call is still active and wasn't properly finished. If you attempt to start a new call after a hot restart/hot reload while a previous call is still active, the underlying web SDK will not be refreshed and will throw an error about a call still being active. **Solution:** After a hot restart/hot reload, reload the browser window as well. If the call was finished/ended normally, everything will work as expected.

## Usage

First, import the Vapi class from the package:

```dart
import 'package:vapi/vapi.dart';
```

Then, create a new instance of the Vapi class, passing your Public Key as a parameter to the constructor:

```dart
var vapi = Vapi('your-public-key');
```

You can start a new call by calling the `start` method and passing an `assistant` object or `assistantId`:

```dart
await vapi.start(assistant: {
  "model": {
    "provider": "openai",
    "model": "gpt-3.5-turbo",
    "systemPrompt": "You're an assistant..."
  },
   "voice": {
    "provider": "11labs",
    "voiceId": "burt",
  },
  ...
});
```

```dart
await vapi.start(assistantId: "your-assistant-id");
```

The `start` method will initiate a new call.

You can override existing assistant parameters or set variables with the `assistant_overrides` parameter.
Assume the first message is `Hey, {{name}} how are you?` and you want to set the value of `name` to `John`:

```dart
final assistantOverrides = {
  'recordingEnabled': false,
  'variableValues': {
    'name': 'John',
  },
};

await vapi.start(
  assistantId: 'your-assistant-id',
  assistantOverrides: assistantOverrides,
);
```

You can send text messages to the assistant aside from the audio input using the `send` method and passing appropriate `role` and `content`.

```dart
vapi.send({
  "type": "add-message",
  "message": {
    "role": "system",
    "content": "The user has pressed the button, say peanuts",
  },
});

```

Possible values for the role are `system`, `user`, `assistant`, `tool` or `function`.

You can stop the session by calling the `stop` method:

```dart
await vapi.stop();
```

This will stop the recording and close the connection.

The `setMuted(muted: boolean)` can be used to mute and un-mute the user's microphone.

```dart
vapi.isMuted(); // false
vapi.setMuted(true);
vapi.isMuted(); // true
```

### Events

You can listen to the following events:

```dart
vapi.onEvent.listen((event) {
    if (event.label == "call-start") {
        print('call started');
    }
    if (event.label == "call-end") {
        print('call ended');
    }

    // Speech statuses, function calls and transcripts will be sent via messages
    if (event.label == "message") {
        print(event.value);
    }
});
```

These events allow you to react to changes in the state of the call or speech.

## Troubleshooting

### Choppy or Interrupted Calls

If calls feel choppy or abrupt (abgehackt), this is often caused by the agent hearing itself and being interrupted. This typically happens when the agent's voice output is picked up by the microphone, creating a feedback loop where the agent stops speaking because it thinks the user is interrupting.

This issue is more common in development environments or when using simulators/emulators with intermediate audio layers. On real devices, the operating system automatically filters out audio that is being played through the speakers from the microphone input stream (echo cancellation), preventing this self-interruption problem.

## Example

An example can be found in the repo [here](example/lib/main.dart)

## License

```
MIT License

Copyright (c) 2023 Vapi Labs Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Contributing

### Development Setup

For detailed instructions on setting up your development environment, please see [SETUP.md](SETUP.md).

### Releasing

For information on how to release new versions to pub.dev, please see [RELEASE.md](RELEASE.md).
