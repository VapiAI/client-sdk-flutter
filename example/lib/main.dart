import 'package:flutter/material.dart';
import 'package:vapi/vapi.dart';

const vapiPublicKey = 'VAPI_PUBLIC_KEY';
const vapiAssistantId = 'VAPI_ASSISTANT_ID';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String buttonText = 'Start Call';
  bool isLoading = false;
  bool isCallStarted = false;
  
  late final VapiClient vapiClient;
  VapiCall? currentCall;

  @override
  void initState() {
    super.initState();
    vapiClient = VapiClient(vapiPublicKey);
  }

  void _handleCallEvents(VapiEvent event) {
    if (event.label == "call-start") {
      setState(() {
        buttonText = 'End Call';
        isLoading = false;
        isCallStarted = true;
      });
      debugPrint('call started');
    }
    if (event.label == "call-end") {
      setState(() {
        buttonText = 'Start Call';
        isLoading = false;
        isCallStarted = false;
        currentCall = null;
      });
      debugPrint('call ended');
    }
    if (event.label == "message") {
      debugPrint('Message: ${event.value}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Vapi Test App'),
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

                    try {
                      if (!isCallStarted) {
                        // Start a new call
                        final call = await vapiClient.start(assistant: {
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
                        
                        currentCall = call;
                        call.onEvent.listen(_handleCallEvents);
                      } else {
                        // End the current call
                        await currentCall?.stop();
                      }
                    } catch (e) {
                      debugPrint('Error: $e');
                      setState(() {
                        buttonText = 'Start Call';
                        isLoading = false;
                      });
                    }
                  },
            child: Text(buttonText),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    currentCall?.dispose();
    super.dispose();
  }
}
