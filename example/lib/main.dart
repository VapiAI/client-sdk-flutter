import 'package:flutter/material.dart';
import 'package:vapi/vapi.dart';

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
  
  VapiClient? vapiClient;
  VapiCall? currentCall;
  
  // Controllers for text fields
  final TextEditingController _publicKeyController = TextEditingController();
  final TextEditingController _assistantIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
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

  Future<void> _onButtonPressed() async {
    setState(() {
      buttonText = 'Loading...';
      isLoading = true;
    });

    try {
      // Initialize client if not already done
      if (vapiClient == null) {
        vapiClient = VapiClient(_publicKeyController.text.trim());
      }

      if (!isCallStarted) {
        // Start a new call using assistant ID
        final call = await vapiClient!.start(assistantId: _assistantIdController.text.trim());
        
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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Vapi Test App'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _publicKeyController,
                decoration: const InputDecoration(
                  labelText: 'VAPI Public Key',
                  border: OutlineInputBorder(),
                  hintText: 'Enter your VAPI public key',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _assistantIdController,
                decoration: const InputDecoration(
                  labelText: 'VAPI Assistant ID',
                  border: OutlineInputBorder(),
                  hintText: 'Enter your VAPI assistant ID',
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _onButtonPressed,
                child: Text(buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _publicKeyController.dispose();
    _assistantIdController.dispose();
    currentCall?.dispose();
    super.dispose();
  }
}
