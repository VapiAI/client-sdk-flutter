import 'package:flutter/material.dart';
import 'package:vapi/Vapi.dart';

const VAPI_PUBLIC_KEY = 'VAPI_PUBLIC_KEY';
const VAPI_ASSISTANT_ID = 'VAPI_ASSISTANT_ID';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String buttonText = 'Start Call';
  bool isLoading = false;
  bool isCallStarted = false;
  Vapi vapi = Vapi(VAPI_PUBLIC_KEY);

  _MyAppState() {
    vapi.onEvent.listen((event) {
      if (event.label == "call-start") {
        setState(() {
          buttonText = 'End Call';
          isLoading = false;
          isCallStarted = true;
        });
        print('call started');
      }
      if (event.label == "call-end") {
        setState(() {
          buttonText = 'Start Call';
          isLoading = false;
          isCallStarted = false;
        });
        print('call ended');
      }
      if (event.label == "message") {
        print(event.value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Test App'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () async {
                    setState(() {
                      buttonText = 'Loading...';
                      isLoading = true;
                    });

                    if (!isCallStarted) {
                      await vapi.start(assistant: {
                        "firstMessage": "Hello, I am an assistant.",
                        "model": {
                          "provider": "openai",
                          "model": "gpt-3.5-turbo",
                          "messages": [
                            {
                              "role": "system",
                              "content": "You are an assistant."
                            }
                          ]
                        },
                        "voice": "jennifer-playht"
                      });
                    } else {
                      await vapi.stop();
                    }
                  },
            child: Text(buttonText),
          ),
        ),
      ),
    );
  }
}
