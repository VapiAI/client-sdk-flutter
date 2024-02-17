import 'package:flutter/material.dart';
import 'package:vapi/Vapi.dart';

const VAPI_PUBLIC_KEY = 'VAPI_PUBLIC_KEY';
const VAPI_ASSISTANT_ID = 'VAPI_ASSISTANT_ID';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Test App'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              var vapi = Vapi(VAPI_PUBLIC_KEY, null);
              print('starting call...');
              await vapi.startCall(assistantId: VAPI_ASSISTANT_ID);
            },
            child: Text('Start Call'),
          ),
        ),
      ),
    );
  }
}
