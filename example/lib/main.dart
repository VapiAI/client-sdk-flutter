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
  Vapi? vapi;

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

                    var vapi = Vapi(VAPI_PUBLIC_KEY);

                    vapi.onEvent.listen((event) {
                      if (event.label == "call-start") {
                        setState(() {
                          buttonText = 'End Call';
                          isLoading = false;
                        });
                        print('call started');
                      }
                      if (event.label == "call-end") {
                        setState(() {
                          buttonText = 'Start Call';
                          isLoading = false;
                        });
                        print('call ended');
                      }
                      if (event.label == "message") {
                        print(event.value);
                      }
                    });

                    if (buttonText == 'Start Call') {
                      await vapi.start(assistant: {"voice": "jennifer-playht"});
                    } else if (buttonText == 'End Call') {
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
