import 'package:flutter/material.dart';
import 'call_screen.dart';
import 'yui_service.dart'; // new file for yui to clean it up

//post pone yui for now:
//note to self: find free api-key, (lets see if this llama works)
//then microphone to talk to her
//then connect to my actual phone
//find her ACTUAL voice instead of her robotic pone
//then find a database to store info as in her memory
//maybe use unlimited database WITHIN flutter
//if not maybe firebase or mongoDB
//then make a history for her to remember
//make her have a daily status report at the end of the day
//to auto delete anything unimportant from my command
//havea 3d model of her to move around (unity maybe?)

void main() => runApp(const YuiApp());

class YuiApp extends StatelessWidget {
  const YuiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        useMaterial3: true,
      ),
      home: const YuiInterface(),
    );
  }
}

class YuiInterface extends StatefulWidget {
  const YuiInterface({super.key});
  @override
  State<YuiInterface> createState() => _YuiInterfaceState();
}

class _YuiInterfaceState extends State<YuiInterface> {
  final YuiService _yui = YuiService();
  final TextEditingController _controller = TextEditingController();
  
  List<Map<String, String>> messages = [];
  bool _isListening = false;
  bool _isThinking = false;
  bool _isInitialized = false;
  bool _isCallMode = false; // New toggle

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() async {
    await _yui.init();
    
    // Set up the listener for Call Mode: 
    // When Yui finishes talking, she starts listening again automatically.
    _yui.flutterTts.setCompletionHandler(() {
      if (_isCallMode) {
        _handleVoice();
      }
    });

    setState(() => _isInitialized = true);
  }

  void _toggleCallMode() {
    // We stop any current voice/listening before jumping screens
    _yui.speechToText.stop();
    _yui.flutterTts.stop();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(yui: _yui),
      ),
    ).then((_) {
      // This runs when you "Hang Up" and come back to the chat
      setState(() {
        _isCallMode = false; 
        messages.add({"role": "yui", "text": "[Call Ended]"});
      });
    });
  }

  void _handleVoice() async {
    bool available = await _yui.speechToText.initialize();
    if (available) {
      setState(() => _isListening = true);
      _yui.speechToText.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
          
          // CRITICAL: Automatically sends when you stop talking
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            setState(() => _isListening = false);
            _send(); 
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 2), // Sends after 2 seconds of silence
      );
    }
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.isEmpty) return;
    setState(() {
      messages.add({"role": "user", "text": text});
      _isThinking = true;
    });
    _controller.clear();

    String response = await _yui.getGroqResponse(messages);
    setState(() {
      messages.add({"role": "yui", "text": response});
      _isThinking = false;
    });

    await _yui.speak(response);
    // Note: The CompletionHandler you set in _setup() handles 
    // restarting the mic once she finishes speaking!
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Yui MHCP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          // THE CALL BUTTON
          IconButton(
            icon: Icon(_isCallMode ? Icons.call_end : Icons.call),
            color: _isCallMode ? Colors.redAccent : Colors.greenAccent,
            onPressed: _toggleCallMode,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. BACKGROUND GRADIENT
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
            ),
          ),
          
          // 2. YUI IMAGE
          Positioned(
            bottom: 100,
            right: -20,
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/yui.png', 
                height: 350, 
                errorBuilder: (c, e, s) => const Icon(Icons.person, size: 100, color: Colors.white24),
              ),
            ),
          ),

          // 3. CHAT CONTENT
          Column(
            children: [
              const SizedBox(height: 100),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    bool isYui = messages[i]['role'] == 'yui';
                    return Align(
                      alignment: isYui ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isYui 
                            ? Colors.white.withValues(alpha: 0.1) 
                            : Colors.pinkAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          messages[i]['text']!,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_isThinking) 
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: LinearProgressIndicator(color: Colors.pinkAccent),
                ),
              
              // INPUT AREA
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.pinkAccent),
                      onPressed: _handleVoice,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Message Yui...",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.pinkAccent),
                      onPressed: _send,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}